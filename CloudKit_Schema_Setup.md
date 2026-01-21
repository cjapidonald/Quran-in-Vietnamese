# CloudKit Schema for Quran in Vietnamese App

## Container Information
- **Container Identifier**: `iCloud.donald.kvietnamisht`
- **Database**: Private Database (user-specific data)
- **Default Zone**: Use the default zone for all records

---

## Record Types

### 1. UserProfile
**Description**: Stores user account information from Sign in with Apple

**Fields**:
| Field Name | Type | Required | Indexed | Queryable | Sortable | Description |
|------------|------|----------|---------|-----------|----------|-------------|
| appleUserID | String | Yes | Yes | Yes | No | Apple User ID from Sign in with Apple |
| email | String | No | Yes | Yes | No | User's email address |
| givenName | String | No | No | No | No | User's first name |
| familyName | String | No | No | No | No | User's last name |
| lastSignIn | Date/Time | Yes | Yes | Yes | Yes | Last sign-in timestamp |
| userRecord | Reference | No | No | No | No | Reference to CKUserIdentity (legacy) |
| createdAt | Date/Time | Yes | Yes | Yes | Yes | Account creation date |

**Indexes**:
- `appleUserID` (QUERYABLE, SORTABLE)
- `lastSignIn` (QUERYABLE, SORTABLE)

**Security**:
- Users can only read/write their own records
- Record Name should match the user's CloudKit recordID

---

### 2. FavoriteAyah
**Description**: Stores individual favorited verses (ayahs)

**Fields**:
| Field Name | Type | Required | Indexed | Queryable | Sortable | Description |
|------------|------|----------|---------|-----------|----------|-------------|
| ayahID | String | Yes | Yes | Yes | Yes | Format: "surahNumber:ayahNumber" (e.g., "1:1", "2:255") |
| surahNumber | Int(64) | Yes | Yes | Yes | Yes | Surah number (1-114) |
| ayahNumber | Int(64) | Yes | Yes | Yes | Yes | Ayah number within the surah |
| favoritedAt | Date/Time | Yes | Yes | Yes | Yes | When the ayah was favorited |
| ownerRecordName | String | Yes | Yes | Yes | No | User's CloudKit record name for ownership |

**Indexes**:
- `ayahID` (QUERYABLE, SORTABLE)
- `surahNumber` (QUERYABLE, SORTABLE)
- `ayahNumber` (QUERYABLE, SORTABLE)
- `favoritedAt` (QUERYABLE, SORTABLE)
- `ownerRecordName` (QUERYABLE)

**Security**:
- Users can only access records where `ownerRecordName` matches their CloudKit recordID
- Each ayahID should be unique per user (create composite index if needed)

---

### 3. AyahNote
**Description**: Stores user notes for specific verses

**Fields**:
| Field Name | Type | Required | Indexed | Queryable | Sortable | Description |
|------------|------|----------|---------|-----------|----------|-------------|
| ayahID | String | Yes | Yes | Yes | Yes | Format: "surahNumber:ayahNumber" (e.g., "1:1") |
| surahNumber | Int(64) | Yes | Yes | Yes | Yes | Surah number (1-114) |
| ayahNumber | Int(64) | Yes | Yes | Yes | Yes | Ayah number within the surah |
| noteText | String | Yes | No | No | No | The actual note content (can be long) |
| createdAt | Date/Time | Yes | Yes | Yes | Yes | When the note was created |
| modifiedAt | Date/Time | Yes | Yes | Yes | Yes | When the note was last modified |
| ownerRecordName | String | Yes | Yes | Yes | No | User's CloudKit record name for ownership |

**Indexes**:
- `ayahID` (QUERYABLE, SORTABLE)
- `surahNumber` (QUERYABLE, SORTABLE)
- `ayahNumber` (QUERYABLE, SORTABLE)
- `createdAt` (QUERYABLE, SORTABLE)
- `modifiedAt` (QUERYABLE, SORTABLE)
- `ownerRecordName` (QUERYABLE)

**Security**:
- Users can only access records where `ownerRecordName` matches their CloudKit recordID
- Multiple notes allowed per ayahID

---

### 4. ReadingProgress
**Description**: Stores reading progress for each surah

**Fields**:
| Field Name | Type | Required | Indexed | Queryable | Sortable | Description |
|------------|------|----------|---------|-----------|----------|-------------|
| surahNumber | Int(64) | Yes | Yes | Yes | Yes | Surah number (1-114) |
| lastReadAyah | Int(64) | Yes | Yes | Yes | Yes | Last ayah number read in this surah |
| totalAyahs | Int(64) | Yes | No | No | No | Total number of ayahs in the surah |
| progressPercentage | Double | Yes | Yes | Yes | Yes | Calculated: (lastReadAyah / totalAyahs) * 100 |
| lastUpdatedAt | Date/Time | Yes | Yes | Yes | Yes | Last time progress was updated |
| ownerRecordName | String | Yes | Yes | Yes | No | User's CloudKit record name for ownership |

**Indexes**:
- `surahNumber` (QUERYABLE, SORTABLE) - PRIMARY
- `lastReadAyah` (QUERYABLE, SORTABLE)
- `progressPercentage` (QUERYABLE, SORTABLE)
- `lastUpdatedAt` (QUERYABLE, SORTABLE)
- `ownerRecordName` (QUERYABLE)

**Security**:
- Users can only access records where `ownerRecordName` matches their CloudKit recordID
- Each surahNumber should be unique per user (one progress record per surah per user)

---

### 5. AppSettings (Optional - for future use)
**Description**: Stores user preferences and settings

**Fields**:
| Field Name | Type | Required | Indexed | Queryable | Sortable | Description |
|------------|------|----------|---------|-----------|----------|-------------|
| settingKey | String | Yes | Yes | Yes | No | Setting identifier (e.g., "theme", "fontSize") |
| settingValue | String | Yes | No | No | No | Serialized setting value (JSON) |
| lastModifiedAt | Date/Time | Yes | Yes | Yes | Yes | Last modification timestamp |
| ownerRecordName | String | Yes | Yes | Yes | No | User's CloudKit record name for ownership |

**Indexes**:
- `settingKey` (QUERYABLE)
- `ownerRecordName` (QUERYABLE)

**Security**:
- Users can only access records where `ownerRecordName` matches their CloudKit recordID

---

## Security & Permissions

### Private Database Permissions
All record types should be set to:
- **Read**: Creator Only
- **Write**: Creator Only
- **Delete**: Creator Only

This ensures users can only access their own data.

### Public Database Permissions
Do NOT use public database for this app - all data is user-private.

---

## Subscription Setup (for Real-time Sync)

### 1. FavoriteAyah Subscription
- **Type**: Database Subscription
- **Database**: Private
- **Fires on**: Create, Update, Delete
- **Name**: `favorite-ayah-changes`

### 2. AyahNote Subscription
- **Type**: Database Subscription
- **Database**: Private
- **Fires on**: Create, Update, Delete
- **Name**: `ayah-note-changes`

### 3. ReadingProgress Subscription
- **Type**: Database Subscription
- **Database**: Private
- **Fires on**: Create, Update, Delete
- **Name**: `reading-progress-changes`

---

## Record Naming Convention

### Record IDs should follow this pattern:

1. **UserProfile**: Use CloudKit's automatically assigned user record ID
   - Format: `_defaultOwner` or user's UUID

2. **FavoriteAyah**:
   - Format: `favorite-{userRecordName}-{ayahID}`
   - Example: `favorite-_abc123-1:1`

3. **AyahNote**:
   - Format: `note-{userRecordName}-{ayahID}-{UUID}`
   - Example: `note-_abc123-1:1-550e8400-e29b-41d4-a716-446655440000`

4. **ReadingProgress**:
   - Format: `progress-{userRecordName}-{surahNumber}`
   - Example: `progress-_abc123-1`

5. **AppSettings**:
   - Format: `setting-{userRecordName}-{settingKey}`
   - Example: `setting-_abc123-theme`

---

## Setup Instructions

### Step 1: Create New CloudKit Container
1. Go to https://icloud.developer.apple.com/
2. Click "CloudKit Database"
3. Select your existing container or create a new one: `iCloud.donald.kvietnamisht`
4. Select "Production" environment (you can test in Development first)

### Step 2: Create Record Types
For each record type above:
1. Click "Schema" → "Record Types" → "Add Record Type"
2. Enter the record type name (exactly as shown above)
3. Click "Add Field" for each field in the table
4. Set the field type, and check "Required" if needed
5. Save the record type

### Step 3: Configure Indexes
For each record type:
1. Click on the record type name
2. Go to "Indexes" tab
3. Click "Add Index"
4. Select the field name
5. Check "Queryable" and "Sortable" as specified in the tables above
6. Save the index

### Step 4: Deploy to Production
1. After creating all record types in Development, test thoroughly
2. Click "Deploy Schema Changes"
3. Select "Production" environment
4. Confirm deployment

### Step 5: Update App Entitlements
Ensure your Xcode project has:
1. CloudKit capability enabled
2. Container `iCloud.donald.kvietnamisht` selected
3. Sign in with Apple capability enabled
4. Background Modes → Remote notifications enabled (for subscriptions)

---

## Migration Notes

### From UserDefaults to CloudKit

Your current data is stored in UserDefaults:
- `favoriteAyahs` (Set<String>)
- `ayahNotes` ([String: [String]])
- `ReadingProgressStore.progress` ([Int: SurahProgress])

You'll need to implement a migration function that:
1. Reads existing UserDefaults data
2. Creates CloudKit records for each item
3. Uploads to CloudKit on first sign-in
4. Clears UserDefaults after successful upload (optional)

---

## Sample Queries

### Fetch all favorites for a user:
```swift
let predicate = NSPredicate(format: "ownerRecordName == %@", userRecordName)
let query = CKQuery(recordType: "FavoriteAyah", predicate: predicate)
let results = try await database.records(matching: query)
```

### Fetch all notes for a specific ayah:
```swift
let predicate = NSPredicate(format: "ayahID == %@ AND ownerRecordName == %@", ayahID, userRecordName)
let query = CKQuery(recordType: "AyahNote", predicate: predicate)
let results = try await database.records(matching: query)
```

### Fetch reading progress for all surahs:
```swift
let predicate = NSPredicate(format: "ownerRecordName == %@", userRecordName)
let query = CKQuery(recordType: "ReadingProgress", predicate: predicate)
query.sortDescriptors = [NSSortDescriptor(key: "surahNumber", ascending: true)]
let results = try await database.records(matching: query)
```

---

## Testing Checklist

After setting up the schema, test these scenarios:

- [ ] User can sign in with Apple
- [ ] User profile is created/updated in CloudKit
- [ ] Favorite an ayah → Record appears in CloudKit dashboard
- [ ] Unfavorite an ayah → Record is deleted from CloudKit
- [ ] Add a note → Record appears in CloudKit
- [ ] Delete a note → Record is deleted from CloudKit
- [ ] Read verses → Progress records are created/updated
- [ ] Sign out and sign back in → Data persists
- [ ] Install app on second device → Data syncs automatically
- [ ] Delete account → All user records are removed

---

## Troubleshooting

### Common Issues:

1. **"Server Rejected Request"**
   - Make sure schema is deployed to Production
   - Check that all required fields are set
   - Verify container identifier matches exactly

2. **"Permission Failure"**
   - Check CloudKit capability is enabled in Xcode
   - Verify user is signed into iCloud on device
   - Ensure app is signed with correct team/profile

3. **"Unknown Item"**
   - Record doesn't exist yet (normal for first fetch)
   - Handle gracefully by creating new record

4. **"Network Unavailable"**
   - Check internet connection
   - Retry with exponential backoff
   - Queue operations for later

---

## Important Notes

1. **Schema is IMMUTABLE in Production**: Once deployed, you cannot:
   - Delete fields
   - Change field types
   - Rename fields

   You CAN:
   - Add new fields
   - Add new record types
   - Modify indexes

2. **Test in Development First**: Always test schema changes in Development environment before deploying to Production

3. **Backup Strategy**: CloudKit is not a backup solution. Consider exporting user data periodically or on-demand

4. **Rate Limits**: CloudKit has rate limits. Implement batching for large operations:
   - Max 400 records per operation
   - Max 200 operations per second

---

## Next Steps for Implementation

After setting up the schema, you'll need to:

1. Create CloudKit sync service classes:
   - `CloudKitFavoritesSync.swift`
   - `CloudKitNotesSync.swift`
   - `CloudKitProgressSync.swift`

2. Implement sync logic:
   - Upload local changes to CloudKit
   - Download CloudKit changes to local
   - Handle conflicts (last-write-wins or custom logic)

3. Add sync triggers:
   - On app launch (after sign-in)
   - On data changes (debounced)
   - On background fetch
   - On push notification (from subscriptions)

4. Add migration from UserDefaults:
   - One-time migration on first sign-in
   - Export UserDefaults → CloudKit
   - Optional: Clear local data after successful sync

Would you like me to implement these sync service classes as well?
