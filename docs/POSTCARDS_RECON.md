
---

## G. Implementation Notes (Step 7)

### What Shipped
1. **Domain Models & Flags (`lib/features/postcards/`):**
   - `kPostcardsEnabled`: Single compile-time feature flag in `postcards_flags.dart` (enabled as `true` in Step 7).
   - `Postcard`, `CircleZone`, `EarnedPostcard` models in `postcard_model.dart` with manual Firestore serialization.
   - `PostcardsRepository` in `postcards_repository.dart` for streaming active postcards, user earned postcards, and atomic idempotent `claimPostcard` transactions.
2. **Zone Matching & Detection Service:**
   - `ZoneMatcher` in `zone_matcher.dart`: Pure Dart Haversine distance calculations, circle containment checks, and 6-character Base32 geohash encoding.
   - `PostcardDetectionService` in `postcard_detection_service.dart`: Listens to user GPS location from existing `userPositionStreamProvider`, enforces horizontal accuracy thresholds (<65m), ignores mock fixes, throttles evaluations (>3s or >15m displacement), and triggers idempotent offline-safe claims.
3. **UI Integration:**
   - `PostcardsSection` in `postcards_section.dart`: Rendered at the very bottom of the Profile screen (`lib/features/profile/profile_screen.dart`), displaying earned cards and empty state.
   - `PostcardUnlockedDialog` in `postcard_unlocked_dialog.dart`: Lightweight in-app celebration modal when crossing into an unearned zone on the map (`SpotsScreen`).
4. **Admin Postcards Management:**
   - Route `/admin/postcards` registered in `app_router.dart` and linked from `AdminDashboardScreen`.
   - `AdminPostcardsScreen` and `AdminPostcardFormScreen` for creating, editing, radius previewing via `flutter_map`, and deleting postcards.
5. **Security Rules Documentation:**
   - `docs/postcards_firestore_rules.md` providing exact, non-breaking match blocks for `/postcards` and `/users/{uid}/postcards` for manual administrator deployment.

### Files Touched (Minimal Edits to Existing Files)
- `lib/core/app_router.dart`: Added `/admin/postcards` route under `/admin` (flag-gated).
- `lib/features/moderation/admin_dashboard_screen.dart`: Added postcard management button in top bar (flag-gated).
- `lib/features/profile/profile_screen.dart`: Added `PostcardsSection()` below Friends list at bottom (flag-gated).
- `lib/features/spots/spots_screen.dart`: Connected location listener to evaluate candidate zones and emit celebration dialog (flag-gated).

### Manual QA Checklist
1. **Admin Postcard Creation:**
   - Sign in as an administrator.
   - Navigate to `/admin/postcards` via the moderation hub.
   - Tap "+" to open the creation form.
   - Enter title, location name, tap map to set center coordinate, adjust radius slider to 300m, and tap "Create Postcard".
   - Confirm card appears in active postcards list.
2. **Zone Ingress Simulation:**
   - Open map screen (`/spots`).
   - Simulate GPS position outside radius: verify no dialog triggers.
   - Move GPS position inside the 300m circle: verify `PostcardUnlockedDialog` celebration appears with title, location, and "Add to Collection" button.
3. **Profile Verification:**
   - Navigate to `/profile`.
   - Scroll to the very bottom below Friends list: verify "Postcards (1 Collected)" appears with the unlocked postcard card.
4. **Offline Resilience:**
   - Toggle device to Airplane mode.
   - Move into an unearned postcard zone: verify claim queues in Firestore offline queue and unlocks locally without crashing.
5. **Non-Admin Security:**
   - Sign in as a regular non-admin user.
   - Attempt to navigate to `/#/admin/postcards`: verify router/guard blocks access with "Access Denied".
