const { serverTimestamp } = require('firebase/firestore');
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

describe('Seabound Phase 1 Firestore Security Rules', () => {
  let testEnv;

  before(async () => {
    const rules = fs.readFileSync(path.resolve(__dirname, '../../firestore.rules'), 'utf8');
    testEnv = await initializeTestEnvironment({
      projectId: 'seabound-test-project',
      firestore: {
        rules: rules,
        host: '127.0.0.1',
        port: 8080,
      },
    });
  });

  after(async () => {
    if (testEnv) {
      await testEnv.cleanup();
    }
  });

  beforeEach(async () => {
    await testEnv.clearFirestore();

    // Seed test database using admin context
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();

      // Seed spot 1: Active spot owned by author1
      await db.collection('spots').doc('spot_active_1').set({
        userId: 'author1',
        name: 'Biscayne Reef',
        moderationStatus: 'active',
      });

      // Seed spot 2: Legacy spot without moderationStatus (must evaluate to active)
      await db.collection('spots').doc('spot_legacy_2').set({
        userId: 'author1',
        name: 'Legacy Spot',
      });

      // Seed spot 3: Hidden spot
      await db.collection('spots').doc('spot_hidden_3').set({
        userId: 'author1',
        name: 'Hidden Spot',
        moderationStatus: 'hidden',
      });

      // Seed spot 4: Removed spot
      await db.collection('spots').doc('spot_removed_4').set({
        userId: 'author1',
        name: 'Removed Spot',
        moderationStatus: 'removed',
      });

      // Seed user profile: captain_target
      await db.collection('users').doc('captain_target').set({
        username: 'CaptainTarget',
      });

      // Seed trip 1: Private trip shared with friend_reporter
      await db.collection('trips').doc('trip_shared_1').set({
        userId: 'author1',
        title: 'Offshore Trip',
        sharedWith: ['friend_reporter', 'other_user'],
        moderationStatus: 'active',
      });

      // Seed trip 2: Legacy trip without moderationStatus
      await db.collection('trips').doc('trip_legacy_2').set({
        userId: 'author1',
        title: 'Legacy Trip',
        sharedWith: ['friend_reporter'],
      });

      // Seed trip 3: Private trip with malformed or missing sharedWith
      await db.collection('trips').doc('trip_malformed_3').set({
        userId: 'author1',
        title: 'No Shares',
      });

      // Seed trip 4: Hidden trip
      await db.collection('trips').doc('trip_hidden_4').set({
        userId: 'author1',
        title: 'Hidden Trip',
        sharedWith: ['friend_reporter'],
        moderationStatus: 'hidden',
      });
    });
  });

  describe('Report Creation Rules', () => {
    it('allows authenticated user to report an active spot with valid length-prefixed ID', async () => {
      const reporter = testEnv.authenticatedContext('reporter1');
      const db = reporter.firestore();
      const contentId = 'spot_active_1';
      const reportId = `spot_${contentId.length}_${contentId}_reporter1`;

      await assertSucceeds(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'spot',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'reporter1',
          category: 'illegal_activity',
          explanation: 'Fishing in a prohibited zone',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('allows reporting legacy spot without moderationStatus', async () => {
      const reporter = testEnv.authenticatedContext('reporter1');
      const db = reporter.firestore();
      const contentId = 'spot_legacy_2';
      const reportId = `spot_${contentId.length}_${contentId}_reporter1`;

      await assertSucceeds(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'spot',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'reporter1',
          category: 'offensive_content',
          explanation: 'Bad spot description',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects report on hidden or removed spots', async () => {
      const reporter = testEnv.authenticatedContext('reporter1');
      const db = reporter.firestore();

      // Hidden
      const contentId = 'spot_hidden_3';
      const reportId = `spot_${contentId.length}_${contentId}_reporter1`;
      await assertFails(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'spot',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'reporter1',
          category: 'offensive_content',
          explanation: 'Test',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );

      // Removed
      const reportId2 = `spot_14_spot_removed_4_reporter1`;
      await assertFails(
        db.collection('reports').doc(reportId2).set({
          id: reportId2,
          contentType: 'spot',
          contentId: 'spot_removed_4',
          authorId: 'author1',
          reporterId: 'reporter1',
          category: 'offensive_content',
          explanation: 'Test',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects report with mismatched authorId', async () => {
      const reporter = testEnv.authenticatedContext('reporter1');
      const db = reporter.firestore();
      const contentId = 'spot_active_1';
      const reportId = `spot_${contentId.length}_${contentId}_reporter1`;

      await assertFails(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'spot',
          contentId: contentId,
          authorId: 'wrong_author',
          reporterId: 'reporter1',
          category: 'other',
          explanation: 'Test',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects self-reporting', async () => {
      const author = testEnv.authenticatedContext('author1');
      const db = author.firestore();
      const contentId = 'spot_active_1';
      const reportId = `spot_${contentId.length}_${contentId}_author1`;

      await assertFails(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'spot',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'author1',
          category: 'other',
          explanation: 'Reporting myself',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('allows valid shared trip report from user in sharedWith', async () => {
      const reporter = testEnv.authenticatedContext('friend_reporter');
      const db = reporter.firestore();
      const contentId = 'trip_shared_1';
      const reportId = `trip_${contentId.length}_${contentId}_friend_reporter`;

      await assertSucceeds(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'trip',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'friend_reporter',
          category: 'harassment',
          explanation: 'Abusive trip notes',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects private trip report if reporter is not in sharedWith', async () => {
      const stranger = testEnv.authenticatedContext('stranger_uid');
      const db = stranger.firestore();
      const contentId = 'trip_shared_1';
      const reportId = `trip_${contentId.length}_${contentId}_stranger_uid`;

      await assertFails(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'trip',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'stranger_uid',
          category: 'harassment',
          explanation: 'Not in sharedWith',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects trip report if sharedWith is missing or not a list', async () => {
      const reporter = testEnv.authenticatedContext('friend_reporter');
      const db = reporter.firestore();
      const contentId = 'trip_malformed_3';
      const reportId = `trip_${contentId.length}_${contentId}_friend_reporter`;

      await assertFails(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'trip',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'friend_reporter',
          category: 'harassment',
          explanation: 'Malformed sharedWith',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('allows valid public profile report and rejects profile ID mismatch', async () => {
      const reporter = testEnv.authenticatedContext('reporter1');
      const db = reporter.firestore();
      const targetUser = 'captain_target';
      const reportId = `user_${targetUser.length}_${targetUser}_reporter1`;

      // Valid profile report
      await assertSucceeds(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'user',
          contentId: targetUser,
          authorId: targetUser,
          reporterId: 'reporter1',
          category: 'hate_speech',
          explanation: 'Abusive profile name',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );

      // Mismatch authorId != contentId
      const reportId2 = `user_${targetUser.length}_${targetUser}_reporter2`;
      const reporter2 = testEnv.authenticatedContext('reporter2');
      await assertFails(
        reporter2.firestore().collection('reports').doc(reportId2).set({
          id: reportId2,
          contentType: 'user',
          contentId: targetUser,
          authorId: 'different_user',
          reporterId: 'reporter2',
          category: 'hate_speech',
          explanation: 'Mismatch',
          status: 'pending',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects unexpected payload fields (e.g. priority injection)', async () => {
      const reporter = testEnv.authenticatedContext('reporter1');
      const db = reporter.firestore();
      const contentId = 'spot_active_1';
      const reportId = `spot_${contentId.length}_${contentId}_reporter1`;

      await assertFails(
        db.collection('reports').doc(reportId).set({
          id: reportId,
          contentType: 'spot',
          contentId: contentId,
          authorId: 'author1',
          reporterId: 'reporter1',
          category: 'other',
          explanation: 'Injected priority',
          status: 'pending',
          priority: 'high', // Forged field
          createdAt: serverTimestamp(),
        })
      );
    });
  });

  describe('Access Control Rules', () => {
    it('ordinary users cannot read, list, update, or delete reports', async () => {
      const reporter = testEnv.authenticatedContext('reporter1');
      const db = reporter.firestore();

      // Read single
      await assertFails(db.collection('reports').doc('any_report_id').get());
      // List
      await assertFails(db.collection('reports').get());
      // Delete
      await assertFails(db.collection('reports').doc('any_report_id').delete());
    });

    it('admin user with { admin: true } claim can read reports', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertSucceeds(db.collection('reports').get());
    });

    it('authenticated user without exact admin: true claim cannot read reports', async () => {
      const fakeAdmin = testEnv.authenticatedContext('user2', { admin: false, role: 'admin' });
      const db = fakeAdmin.firestore();

      await assertFails(db.collection('reports').get());
    });
  });

  describe('Admin Resolution Transitions', () => {
    const seedReportId = 'spot_13_spot_active_1_rep_test';

    beforeEach(async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        const db = context.firestore();
        await db.collection('reports').doc(seedReportId).set({
          id: seedReportId,
          contentType: 'spot',
          contentId: 'spot_active_1',
          authorId: 'author1',
          reporterId: 'rep_test',
          category: 'harassment',
          explanation: 'Bad content',
          status: 'pending',
          createdAt: serverTimestamp(),
        });
      });
    });

    it('admin can transition pending to under_review modifying only status', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertSucceeds(
        db.collection('reports').doc(seedReportId).update({
          status: 'under_review',
        })
      );
    });

    it('rejects under_review transition if resolution fields are injected during triage', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertFails(
        db.collection('reports').doc(seedReportId).update({
          status: 'under_review',
          resolvedBy: 'admin_user', // Invalid during triage
        })
      );
    });

    it('admin can transition to resolved or dismissed with complete resolution metadata', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertSucceeds(
        db.collection('reports').doc(seedReportId).update({
          status: 'resolved',
          resolvedBy: 'admin_user',
          resolvedAt: serverTimestamp(),
          resolutionNotes: 'Verified violation and hidden content.',
        })
      );
    });

    it('rejects admin resolution if resolvedBy does not match admin auth UID', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertFails(
        db.collection('reports').doc(seedReportId).update({
          status: 'resolved',
          resolvedBy: 'impersonated_admin_uid',
          resolvedAt: serverTimestamp(),
          resolutionNotes: 'Fake admin ID',
        })
      );
    });

    it('rejects admin attempts to modify original evidence fields', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertFails(
        db.collection('reports').doc(seedReportId).update({
          status: 'resolved',
          explanation: 'Altered explanation text',
          resolvedBy: 'admin_user',
          resolvedAt: serverTimestamp(),
          resolutionNotes: 'Tampering evidence',
        })
      );
    });

    it('rejects reopening or modifying resolved reports', async () => {
      // First resolve the report
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('reports').doc(seedReportId).update({
          status: 'resolved',
          resolvedBy: 'admin_user',
          resolvedAt: serverTimestamp(),
          resolutionNotes: 'Done',
        });
      });

      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      // Attempt to reopen to pending
      await assertFails(
        db.collection('reports').doc(seedReportId).update({
          status: 'pending',
        })
      );

      // Attempt to delete
      await assertFails(
        db.collection('reports').doc(seedReportId).delete()
      );
    });
  });

  // =========================================================================
  // Phase 3: Moderation Audit Logs Collection (/moderation_logs) Tests
  // =========================================================================
  describe('Phase 3 Moderation Audit Logs Rules', () => {
    it('allows admin to create a valid moderation audit log document', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_valid_1';

      await assertSucceeds(
        db.collection('moderation_logs').doc(logId).set({
          id: logId,
          adminId: 'admin_user',
          contentType: 'spot',
          contentId: 'spot_active_1',
          previousStatus: 'active',
          newStatus: 'hidden',
          reason: 'Policy violation',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects log creation by non-admin authenticated users', async () => {
      const user = testEnv.authenticatedContext('regular_user');
      const db = user.firestore();
      const logId = 'log_unauth_1';

      await assertFails(
        db.collection('moderation_logs').doc(logId).set({
          id: logId,
          adminId: 'regular_user',
          contentType: 'spot',
          contentId: 'spot_active_1',
          previousStatus: 'active',
          newStatus: 'hidden',
          reason: 'I am not an admin',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects log creation if adminId does not match authenticated admin UID', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_spoof_admin';

      await assertFails(
        db.collection('moderation_logs').doc(logId).set({
          id: logId,
          adminId: 'other_admin',
          contentType: 'spot',
          contentId: 'spot_active_1',
          previousStatus: 'active',
          newStatus: 'hidden',
          reason: 'Spoofed admin',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects log creation if previousStatus and newStatus are identical', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_same_status';

      await assertFails(
        db.collection('moderation_logs').doc(logId).set({
          id: logId,
          adminId: 'admin_user',
          contentType: 'spot',
          contentId: 'spot_active_1',
          previousStatus: 'active',
          newStatus: 'active',
          reason: 'No-op transition',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects log creation if reason exceeds 500 characters', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_long_reason';

      await assertFails(
        db.collection('moderation_logs').doc(logId).set({
          id: logId,
          adminId: 'admin_user',
          contentType: 'spot',
          contentId: 'spot_active_1',
          previousStatus: 'active',
          newStatus: 'hidden',
          reason: 'a'.repeat(501),
          createdAt: serverTimestamp(),
        })
      );
    });

    it('rejects log creation if unauthorized fields are included', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_extra_fields';

      await assertFails(
        db.collection('moderation_logs').doc(logId).set({
          id: logId,
          adminId: 'admin_user',
          contentType: 'spot',
          contentId: 'spot_active_1',
          previousStatus: 'active',
          newStatus: 'hidden',
          reason: 'Extra field injection',
          extraField: 'not_allowed',
          createdAt: serverTimestamp(),
        })
      );
    });

    it('admin can read /moderation_logs documents and collections', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      await assertSucceeds(admin.firestore().collection('moderation_logs').get());
    });

    it('ordinary users cannot read /moderation_logs', async () => {
      const user = testEnv.authenticatedContext('regular_user');
      const db = user.firestore();
      await assertFails(db.collection('moderation_logs').doc('any_log').get());
      await assertFails(db.collection('moderation_logs').get());
    });

    it('moderation logs are immutable: update and delete are rejected for admins', async () => {
      await testEnv.withSecurityRulesDisabled(async (context) => {
        await context.firestore().collection('moderation_logs').doc('immutable_log').set({
          id: 'immutable_log',
          adminId: 'admin_user',
          contentType: 'spot',
          contentId: 'spot_active_1',
          previousStatus: 'active',
          newStatus: 'hidden',
          reason: 'Immutable test',
          createdAt: new Date(),
        });
      });

      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertFails(
        db.collection('moderation_logs').doc('immutable_log').update({
          reason: 'Modified reason',
        })
      );

      await assertFails(
        db.collection('moderation_logs').doc('immutable_log').delete()
      );
    });
  });

  // =========================================================================
  // Phase 3: Content Moderation Lifecycle & Atomic Mutations (Spots & Trips)
  // =========================================================================
  describe('Phase 3 Content Moderation Lifecycle (Spots)', () => {
    it('allows admin to atomically transition active spot to hidden with coupled audit log', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_spot_hide_1';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'spot',
        contentId: 'spot_active_1',
        previousStatus: 'active',
        newStatus: 'hidden',
        reason: 'Hide offensive spot',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('spots').doc('spot_active_1'), {
        moderationStatus: 'hidden',
        moderationLogId: logId,
      });

      await assertSucceeds(batch.commit());
    });

    it('allows admin to atomically transition hidden spot to removed with coupled audit log', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_spot_remove_1';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'spot',
        contentId: 'spot_hidden_3',
        previousStatus: 'hidden',
        newStatus: 'removed',
        reason: 'Permanent removal after review',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('spots').doc('spot_hidden_3'), {
        moderationStatus: 'removed',
        moderationLogId: logId,
      });

      await assertSucceeds(batch.commit());
    });

    it('allows admin to restore removed spot back to active with coupled audit log', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_spot_restore_1';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'spot',
        contentId: 'spot_removed_4',
        previousStatus: 'removed',
        newStatus: 'active',
        reason: 'Content exonerated upon appeal',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('spots').doc('spot_removed_4'), {
        moderationStatus: 'active',
        moderationLogId: logId,
      });

      await assertSucceeds(batch.commit());
    });

    it('rejects spot moderation transition if audit log is missing (not atomic)', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertFails(
        db.collection('spots').doc('spot_active_1').update({
          moderationStatus: 'hidden',
          moderationLogId: 'non_existent_log_id',
        })
      );
    });

    it('rejects spot moderation transition if audit log previousStatus does not match', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_spot_mismatch_prev';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'spot',
        contentId: 'spot_active_1',
        previousStatus: 'hidden',
        newStatus: 'removed',
        reason: 'Mismatched previous status',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('spots').doc('spot_active_1'), {
        moderationStatus: 'removed',
        moderationLogId: logId,
      });

      await assertFails(batch.commit());
    });

    it('rejects spot moderation transition if audit log contentId does not match spotId', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_spot_mismatch_id';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'spot',
        contentId: 'different_spot_id',
        previousStatus: 'active',
        newStatus: 'hidden',
        reason: 'Mismatched target ID',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('spots').doc('spot_active_1'), {
        moderationStatus: 'hidden',
        moderationLogId: logId,
      });

      await assertFails(batch.commit());
    });

    it('rejects direct spot moderation by regular users', async () => {
      const user = testEnv.authenticatedContext('author1');
      const db = user.firestore();

      await assertFails(
        db.collection('spots').doc('spot_active_1').update({
          moderationStatus: 'hidden',
          moderationLogId: 'some_log_id',
        })
      );
    });

    it('strictly prohibits physical deletion of spots by anyone (owner and admin)', async () => {
      const owner = testEnv.authenticatedContext('author1');
      await assertFails(owner.firestore().collection('spots').doc('spot_active_1').delete());

      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      await assertFails(admin.firestore().collection('spots').doc('spot_active_1').delete());
    });
  });

  describe('Phase 3 Content Moderation Lifecycle (Trips)', () => {
    it('allows admin to atomically transition active trip to hidden with coupled audit log', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_trip_hide_1';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'trip',
        contentId: 'trip_shared_1',
        previousStatus: 'active',
        newStatus: 'hidden',
        reason: 'Offensive trip notes',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('trips').doc('trip_shared_1'), {
        moderationStatus: 'hidden',
        moderationLogId: logId,
      });

      await assertSucceeds(batch.commit());
    });

    it('allows admin to atomically transition hidden trip to active with coupled audit log', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_trip_restore_1';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'trip',
        contentId: 'trip_hidden_4',
        previousStatus: 'hidden',
        newStatus: 'active',
        reason: 'Restoring cleared trip',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('trips').doc('trip_hidden_4'), {
        moderationStatus: 'active',
        moderationLogId: logId,
      });

      await assertSucceeds(batch.commit());
    });

    it('rejects trip moderation transition if audit log contentType is wrong', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();
      const logId = 'log_trip_wrong_type';

      const batch = db.batch();
      batch.set(db.collection('moderation_logs').doc(logId), {
        id: logId,
        adminId: 'admin_user',
        contentType: 'spot',
        contentId: 'trip_shared_1',
        previousStatus: 'active',
        newStatus: 'hidden',
        reason: 'Wrong content type',
        createdAt: serverTimestamp(),
      });
      batch.update(db.collection('trips').doc('trip_shared_1'), {
        moderationStatus: 'hidden',
        moderationLogId: logId,
      });

      await assertFails(batch.commit());
    });

    it('strictly prohibits physical deletion of trips by anyone (owner and admin)', async () => {
      const owner = testEnv.authenticatedContext('author1');
      await assertFails(owner.firestore().collection('trips').doc('trip_shared_1').delete());

      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      await assertFails(admin.firestore().collection('trips').doc('trip_shared_1').delete());
    });
  });

  describe('Phase 3 Content Visibility Rules for Non-Admins', () => {
    it('public spot reads allow active spots for regular users, but reject hidden and removed spots', async () => {
      const regularUser = testEnv.authenticatedContext('viewer_uid');
      const db = regularUser.firestore();

      await assertSucceeds(db.collection('spots').doc('spot_active_1').get());
      await assertSucceeds(db.collection('spots').doc('spot_legacy_2').get());
      await assertFails(db.collection('spots').doc('spot_hidden_3').get());
      await assertFails(db.collection('spots').doc('spot_removed_4').get());
    });

    it('owner can always view their own spots regardless of moderation status', async () => {
      const owner = testEnv.authenticatedContext('author1');
      const db = owner.firestore();

      await assertSucceeds(db.collection('spots').doc('spot_active_1').get());
      await assertSucceeds(db.collection('spots').doc('spot_hidden_3').get());
      await assertSucceeds(db.collection('spots').doc('spot_removed_4').get());
    });

    it('admin can view all spots regardless of moderation status', async () => {
      const admin = testEnv.authenticatedContext('admin_user', { admin: true });
      const db = admin.firestore();

      await assertSucceeds(db.collection('spots').doc('spot_active_1').get());
      await assertSucceeds(db.collection('spots').doc('spot_hidden_3').get());
      await assertSucceeds(db.collection('spots').doc('spot_removed_4').get());
    });

    it('shared trip reads allow shared participants only when trip is active', async () => {
      const friend = testEnv.authenticatedContext('friend_reporter');
      const db = friend.firestore();

      await assertSucceeds(db.collection('trips').doc('trip_shared_1').get());
      await assertSucceeds(db.collection('trips').doc('trip_legacy_2').get());
      await assertFails(db.collection('trips').doc('trip_hidden_4').get());
    });

    it('shared participant cannot toggle reactions on hidden trips', async () => {
      const friend = testEnv.authenticatedContext('friend_reporter');
      const db = friend.firestore();

      await assertSucceeds(
        db.collection('trips').doc('trip_shared_1').update({
          likedBy: ['friend_reporter'],
        })
      );

      await assertFails(
        db.collection('trips').doc('trip_hidden_4').update({
          likedBy: ['friend_reporter'],
        })
      );
    });
  });

});
