# CloudKit User and Account Deletion Schema

This document captures the CloudKit configuration required to provision the backend that matches the app bundle identifier `vn.quran.app` and its entitlements.

## CloudKit container

* **Container identifier:** `iCloud.com.donald.quranvn`
* Ensure the container is added to the Apple Developer account that owns the bundle identifier. The container name follows the `iCloud.<bundle identifier>` convention so it matches the Xcode project settings and entitlements.

### Add the container in CloudKit Dashboard

1. Sign in to the [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard/) with an Apple ID that has the **App Manager** or **Admin** role for the team.
2. Create a new container named `iCloud.com.donald.quranvn` (or select it if it already exists).
3. Under **Schema → Record Types**, add the following record types.

### `UserProfile`

| Field name    | Type                    | Attributes          | Notes                                                       |
|---------------|-------------------------|---------------------|-------------------------------------------------------------|
| `appleUserID` | String                  | Queryable           | Required, stores the stable Sign in with Apple identifier   |
| `email`       | String                  | Queryable, optional | Optional email address                                      |
| `givenName`   | String                  | Optional            | Optional user given name                                    |
| `familyName`  | String                  | Optional            | Optional user family name                                   |
| `lastSignIn`  | Date Time (`DATE_TIME`) | Sortable            | Tracks the most recent sign-in date-time value              |
| `userRecord`  | Reference               | —                   | Reference to the owner’s `_defaultOwner` user record        |

```text
INDEXES
QUERY appleUserID
QUERY email
```

### `AccountDeletionRequest`

| Field name    | Type                    | Attributes          | Notes                                                                 |
|---------------|-------------------------|---------------------|-----------------------------------------------------------------------|
| `userRecord`  | Reference               | —                   | Reference to the `_defaultOwner` record for the signed-in user        |
| `appleUserID` | String                  | Queryable           | Mirrors the Sign in with Apple identifier for auditing                |
| `requestedAt` | Date Time (`DATE_TIME`) | Sortable            | Date-time for when the user requested account deletion                |
| `status`      | String                  | Queryable           | Workflow state (e.g. `pending`, `processing`, `completed`, `error`)   |
| `notes`       | String                  | Optional            | Optional field for operational comments                               |

```text
INDEXES
QUERY appleUserID
QUERY status, requestedAt
SORT requestedAt
```

4. In **Schema → Indexes**, confirm the indexes above exist. For query indexes, select the appropriate fields and press **Save**.
5. Use **Deploy → Production** to promote the schema so it is available outside the development environment.

## Xcode project configuration

1. In the project editor, select the **Quranvn** target and open the **Signing & Capabilities** tab.
2. Enable the **iCloud** capability and check the **CloudKit** service.
3. Under **Containers**, add `iCloud.com.donald.quranvn`. This updates `Quranvn.entitlements` with the correct container identifier.
4. Ensure the bundle identifier remains `vn.quran.app` for both Debug and Release configurations so it matches the container naming convention.

## Team roles and environment requirements

* The developer performing these steps must belong to the Apple Developer team with either **Admin** or **App Manager** privileges. Editors can work with records but cannot manage schema promotion.
* Other contributors should:
  1. Pull the latest source code to receive the updated entitlements file.
  2. Sign into Xcode with a team account that has access to `iCloud.com.donald.quranvn`.
  3. Confirm the container appears under **Signing & Capabilities → iCloud** after signing in.
* When running locally, use a device or simulator signed into iCloud with the same Apple ID used for development testing so CloudKit requests succeed.

Following these steps keeps the CloudKit configuration consistent between the dashboard, Xcode project, and runtime environment.
