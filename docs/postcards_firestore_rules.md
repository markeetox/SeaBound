# SeaBound Postcards: Firestore Security Rules (Step 6)

The following rules blocks must be added to `firestore.rules` under `match /databases/{database}/documents`.

**DO NOT DEPLOY WITHOUT MANUAL REVIEW.**

```javascript
    // ---------------------------------------------------------
    // Postcards Collection (Step 6: Admin-authored collectibles)
    // ---------------------------------------------------------
    match /postcards/{postcardId} {
      // Any authenticated user can read active and catalog postcards
      allow read: if isAuthenticated();

      // Only administrators or users with explicit manage_postcards claim can write
      allow create, update: if isAuthenticated()
        && (request.auth.token.admin == true || request.auth.token.manage_postcards == true)
        && request.resource.data.title is string
        && request.resource.data.title.size() > 0
        && request.resource.data.title.size() <= 100
        && request.resource.data.description is string
        && request.resource.data.description.size() <= 500
        && request.resource.data.locationName is string
        && request.resource.data.locationName.size() <= 100
        && request.resource.data.imageUrl is string
        && request.resource.data.active is bool
        && request.resource.data.zone is map
        && request.resource.data.zone.lat is number
        && request.resource.data.zone.lat >= -90.0 && request.resource.data.zone.lat <= 90.0
        && request.resource.data.zone.lng is number
        && request.resource.data.zone.lng >= -180.0 && request.resource.data.zone.lng <= 180.0
        && request.resource.data.zone.radiusMeters is number
        && request.resource.data.zone.radiusMeters >= 25.0 && request.resource.data.zone.radiusMeters <= 50000.0;

      allow delete: if isAuthenticated()
        && (request.auth.token.admin == true || request.auth.token.manage_postcards == true);
    }

    // Inside match /users/{userId}
    match /users/{userId} {
      // ... existing rules ...

      // ---------------------------------------------------------
      // User Earned Postcards Subcollection (Step 6: Idempotent unlocks)
      // ---------------------------------------------------------
      match /postcards/{postcardId} {
        // Any authenticated user can view earned postcards on user profiles
        allow read: if isAuthenticated();

        // Create-only: User can only create their own earned record with doc ID == postcardId
        allow create: if isOwner(userId)
          && request.resource.data.postcardId == postcardId
          && request.resource.data.title is string
          && request.resource.data.earnedAt == request.time
          && exists(/databases/$(database)/documents/postcards/$(postcardId))
          && get(/databases/$(database)/documents/postcards/$(postcardId)).data.active == true;

        // Earned postcards are permanent records (no tampering by user, admins can moderate)
        allow update: if false;
        allow delete: if isAdmin();
      }
    }
```

---

## Known Security Limitations & Tradeoffs

1. **Client-Side GPS Verification:**
   - Because SeaBound is an offshore maritime navigation application where boaters frequently lose cellular service, zone ingress is evaluated locally on the client and queued offline via Firestore's offline persistence.
   - **Tradeoff:** A user with a modified client binary or mock location tool could trigger `claimPostcard()` for any active postcard.
   - **Recommendation from Reconnaissance:** This tradeoff is accepted for v1 gamification/collectibles because offshore reliability is paramount. If competitive leaderboards or real-world prizes are introduced later, a Cloud Function with trajectory verification or geofence attestation can be layered on.
