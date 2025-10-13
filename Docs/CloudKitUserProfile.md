# CloudKit User Profile Setup

This document captures the configuration required to provision the CloudKit backend that matches the app bundle identifier `com.Donald.Quranvn` and its entitlements.

## CloudKit container

* **Container identifier:** `iCloud.com.Donald.Quranvn`
* Ensure the container is added to the Apple Developer account that owns the bundle identifier. The container name follows the `iCloud.<bundle identifier>` convention so it matches the Xcode project settings and entitlements.

### Add the container in CloudKit Dashboard

1. Sign in to the [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/) with an Apple ID that has the **App Manager** or **Admin** role for the team.
2. Create a new container named `iCloud.com.Donald.Quranvn` (or select it if it already exists).
3. Under **Schema → Record Types**, add a new record type named `UserProfile` with the following fields:
   | Field name  | Type    | Attributes                     | Notes                                               |
   |-------------|---------|--------------------------------|-----------------------------------------------------|
   | `appleUserID` | String | Queryable                     | Required, stores the stable CloudKit user identifier |
   | `email`       | String | Queryable, optional           | Optional email address                             |
   | `givenName`   | String | Optional                      |                                                    |
   | `familyName`  | String | Optional                      |                                                    |
   | `lastSignIn`  | Date   | Sortable                      | Tracks the most recent sign-in                     |
   | `userRef`     | Reference | —                          | Reference to the owner’s `_defaultOwner` user record |
4. In **Schema → Indexes**, add query indexes on `appleUserID` and `email`. This enables efficient lookups for sign-in and duplicate detection.
5. Use **Deploy → Production** to promote the schema so it is available outside the development environment.

## Xcode project configuration

1. In the project editor, select the **Quranvn** target and open the **Signing & Capabilities** tab.
2. Enable the **iCloud** capability and check the **CloudKit** service.
3. Under **Containers**, add `iCloud.com.Donald.Quranvn`. This updates `Quranvn.entitlements` with the correct container identifier.
4. Ensure the bundle identifier remains `com.Donald.Quranvn` for both Debug and Release configurations so it matches the container naming convention.

## Team roles and environment requirements

* The developer performing these steps must belong to the Apple Developer team with either **Admin** or **App Manager** privileges. Editors can work with records but cannot manage schema promotion.
* Other contributors should:
  1. Pull the latest source code to receive the updated entitlements file.
  2. Sign into Xcode with a team account that has access to `iCloud.com.Donald.Quranvn`.
  3. Confirm the container appears under **Signing & Capabilities → iCloud** after signing in.
* When running locally, use a device or simulator signed into iCloud with the same Apple ID used for development testing so CloudKit requests succeed.

Following these steps keeps the CloudKit configuration consistent between the dashboard, Xcode project, and runtime environment.
