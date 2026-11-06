/**
 * SeaBound Phase 3 Firestore Data Migration Script
 *
 * Backfills legacy documents in the `spots` and `trips` collections that do not
 * yet have a `moderationStatus` field by populating them with `moderationStatus: 'active'`.
 *
 * Requirements & Safeguards:
 * 1. Supports dry-run mode (`--dry-run` or `-d`) to audit changes without writing to Firestore.
 * 2. Uses atomic batched writes in chunks of 400 (well within the 500 Firestore limit).
 * 3. Never overwrites documents that already have a moderationStatus (e.g. 'active', 'hidden', 'removed').
 * 4. Can run against local Firestore Emulator (FIRESTORE_EMULATOR_HOST) or configured Firebase project.
 * 5. Provides comprehensive progress logging with affected counts.
 *
 * Usage:
 *   # Dry Run (Audit only, no writes):
 *   node scripts/admin/migrate_moderation_status.js --dry-run
 *
 *   # Live Migration:
 *   node scripts/admin/migrate_moderation_status.js
 */

let admin;
try {
  admin = require('firebase-admin');
} catch (e) {
  // Fallback to test/firestore_rules/node_modules if running from repo root
  try {
    admin = require('../../test/firestore_rules/node_modules/firebase-admin');
  } catch (err) {
    throw e;
  }
}

const BATCH_SIZE = 400;
const DEFAULT_PROJECT_ID = 'fishy-37486';

const args = process.argv.slice(2);
const isDryRun = args.includes('--dry-run') || args.includes('-d');

/**
 * Initializes the Firebase Admin app if not already initialized.
 * Reads FIRESTORE_EMULATOR_HOST or GCLOUD_PROJECT from the environment if present.
 */
function initAdminApp() {
  if (!admin.apps.length) {
    const projectId = process.env.GCLOUD_PROJECT || process.env.FIREBASE_PROJECT_ID || DEFAULT_PROJECT_ID;
    admin.initializeApp({
      projectId: projectId,
    });
  }
  return admin.firestore();
}

/**
 * Migrates a target collection by backfilling documents missing `moderationStatus` to 'active'.
 *
 * @param {admin.firestore.Firestore} db
 * @param {string} collectionName
 * @param {boolean} dryRun
 * @returns {Promise<{scanned: number, migrated: number, skipped: number}>}
 */
async function migrateCollection(db, collectionName, dryRun) {
  console.log(`\n======================================================`);
  console.log(`Starting scan for collection: [${collectionName}] (dry-run: ${dryRun})`);
  console.log(`======================================================`);

  const snapshot = await db.collection(collectionName).get();
  const totalDocs = snapshot.docs.length;
  console.log(`[${collectionName}] Fetched ${totalDocs} total documents.`);

  let migratedCount = 0;
  let skippedCount = 0;
  const toUpdate = [];

  for (const doc of snapshot.docs) {
    const data = doc.data();
    if (data.moderationStatus === undefined || data.moderationStatus === null) {
      toUpdate.push(doc.ref);
    } else {
      skippedCount++;
    }
  }

  console.log(`[${collectionName}] Found ${toUpdate.length} legacy document(s) missing 'moderationStatus'.`);
  console.log(`[${collectionName}] Found ${skippedCount} document(s) already carrying 'moderationStatus' (skipped).`);

  if (toUpdate.length === 0) {
    console.log(`[${collectionName}] No migration needed.`);
    return { scanned: totalDocs, migrated: 0, skipped: skippedCount };
  }

  if (dryRun) {
    console.log(`[${collectionName}] DRY-RUN ENABLED: Skipping write operations for ${toUpdate.length} document(s).`);
    return { scanned: totalDocs, migrated: toUpdate.length, skipped: skippedCount };
  }

  // Execute in batches
  for (let i = 0; i < toUpdate.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const chunk = toUpdate.slice(i, i + BATCH_SIZE);

    for (const ref of chunk) {
      batch.update(ref, {
        moderationStatus: 'active',
      });
    }

    await batch.commit();
    migratedCount += chunk.length;
    console.log(`[${collectionName}] Committed batch: ${migratedCount}/${toUpdate.length} migrated.`);
  }

  console.log(`[${collectionName}] Completed migration: ${migratedCount} document(s) updated.`);
  return { scanned: totalDocs, migrated: migratedCount, skipped: skippedCount };
}

/**
 * Main migration entrypoint.
 */
async function runMigration() {
  const isEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
  console.log(`[SeaBound Phase 3 Migration] Initializing...`);
  console.log(`[SeaBound Phase 3 Migration] Mode: ${isDryRun ? 'DRY RUN (No changes will be applied)' : 'LIVE EXECUTION'}`);
  console.log(`[SeaBound Phase 3 Migration] Emulator target: ${isEmulator ? process.env.FIRESTORE_EMULATOR_HOST : 'Cloud Firestore (Production/Staging)'}`);

  const db = initAdminApp();

  const collections = ['spots', 'trips'];
  const summary = {};

  for (const col of collections) {
    summary[col] = await migrateCollection(db, col, isDryRun);
  }

  console.log(`\n======================================================`);
  console.log(`MIGRATION SUMMARY (${isDryRun ? 'DRY-RUN' : 'LIVE'}):`);
  console.log(`======================================================`);
  for (const [col, stats] of Object.entries(summary)) {
    console.log(`Collection '${col}': Total Scanned: ${stats.scanned}, Migrated: ${stats.migrated}, Skipped: ${stats.skipped}`);
  }
  console.log(`Migration completed successfully.\n`);
}

// Allow importing runMigration and migrateCollection for automated testing
if (require.main === module) {
  runMigration().catch((error) => {
    console.error('Migration failed with error:', error);
    process.exit(1);
  });
}

module.exports = {
  migrateCollection,
  runMigration,
  initAdminApp,
};
