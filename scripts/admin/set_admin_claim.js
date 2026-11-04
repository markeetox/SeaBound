/**
 * SeaBound Admin Custom Claim Provisioning Script
 *
 * Target Project: fishy-37486
 * Target UID: ojMSrDiSHHZs82kwFGVADnvQGCh1
 *
 * Usage:
 * 1. Ensure you have authorized Google Cloud application default credentials:
 *    gcloud auth application-default login
 *    OR provide GOOGLE_APPLICATION_CREDENTIALS=/path/to/serviceAccountKey.json
 *
 * 2. Run:
 *    node scripts/admin/set_admin_claim.js
 */

const admin = require('firebase-admin');

const TARGET_PROJECT_ID = 'fishy-37486';
const TARGET_UID = 'ojMSrDiSHHZs82kwFGVADnvQGCh1';

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: TARGET_PROJECT_ID,
  });
}

async function setAdminClaim() {
  console.log(`[SeaBound Provisioning] Target Firebase Project: ${TARGET_PROJECT_ID}`);
  console.log(`[SeaBound Provisioning] Assigning custom claim { admin: true } to UID: ${TARGET_UID}...`);

  try {
    // 1. Fetch existing user record to verify target existence
    const user = await admin.auth().getUser(TARGET_UID);
    console.log(`[SeaBound Provisioning] Found user: ${user.email || user.displayName || user.uid}`);

    // 2. Set custom claims preserving existing claims if any
    const currentClaims = user.customClaims || {};
    const updatedClaims = { ...currentClaims, admin: true };

    await admin.auth().setCustomUserClaims(TARGET_UID, updatedClaims);
    console.log(`[SeaBound Provisioning] Successfully assigned claims.`);

    // 3. Re-fetch user record to verify claim persistence
    const verifiedUser = await admin.auth().getUser(TARGET_UID);
    console.log(`[SeaBound Provisioning] Verification confirmed. Active Custom Claims:`, verifiedUser.customClaims);

    if (verifiedUser.customClaims && verifiedUser.customClaims.admin === true) {
      console.log(`[SeaBound Provisioning] SUCCESS: UID ${TARGET_UID} is confirmed as an active Administrator.`);
    } else {
      console.error(`[SeaBound Provisioning] ERROR: Custom claim verification failed.`);
    }
  } catch (error) {
    console.error(`[SeaBound Provisioning] Failed to set admin claim:`, error);
    process.exit(1);
  }
}

setAdminClaim();
