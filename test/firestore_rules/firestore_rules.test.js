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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          createdAt: new Date(),
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
          resolvedAt: new Date(),
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
          resolvedAt: new Date(),
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
          resolvedAt: new Date(),
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
          resolvedAt: new Date(),
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
});
