# CloudKit Schema Setup Guide
## Container: iCloud.donald.kvietnamisht

---

## IMPORTANT: Schema Setup Method

CloudKit Console does NOT support direct JSON import. You must create the schema manually following the exact specifications below.

---

## Record Type 1: UserProfile

### Fields to Add:
1. Click "Add Field"
   - Field Name: `appleUserID`
   - Type: `String`
   - Check: ✅ Required

2. Click "Add Field"
   - Field Name: `email`
   - Type: `String`
   - Leave unchecked: Required

3. Click "Add Field"
   - Field Name: `givenName`
   - Type: `String`
   - Leave unchecked: Required

4. Click "Add Field"
   - Field Name: `familyName`
   - Type: `String`
   - Leave unchecked: Required

5. Click "Add Field"
   - Field Name: `lastSignIn`
   - Type: `Date/Time`
   - Check: ✅ Required

6. Click "Add Field"
   - Field Name: `createdAt`
   - Type: `Date/Time`
   - Check: ✅ Required

### Indexes to Add:
1. Click "Add Index"
   - Field: `appleUserID`
   - Check: ✅ QUERYABLE
   - Check: ✅ SEARCHABLE

2. Click "Add Index"
   - Field: `lastSignIn`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

3. Click "Add Index"
   - Field: `createdAt`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

### Metadata Indexes (Built-in):
- Check: ✅ Enable recordName for queries
- Check: ✅ Enable createdTimestamp for queries
- Check: ✅ Enable modifiedTimestamp for queries

---

## Record Type 2: FavoriteAyah

### Fields to Add:
1. Click "Add Field"
   - Field Name: `ayahID`
   - Type: `String`
   - Check: ✅ Required

2. Click "Add Field"
   - Field Name: `surahNumber`
   - Type: `Int(64)`
   - Check: ✅ Required

3. Click "Add Field"
   - Field Name: `ayahNumber`
   - Type: `Int(64)`
   - Check: ✅ Required

4. Click "Add Field"
   - Field Name: `favoritedAt`
   - Type: `Date/Time`
   - Check: ✅ Required

5. Click "Add Field"
   - Field Name: `ownerRecordName`
   - Type: `String`
   - Check: ✅ Required

### Indexes to Add:
1. Click "Add Index"
   - Field: `ayahID`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

2. Click "Add Index"
   - Field: `surahNumber`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

3. Click "Add Index"
   - Field: `ayahNumber`
   - Check: ✅ QUERYABLE

4. Click "Add Index"
   - Field: `favoritedAt`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

5. Click "Add Index"
   - Field: `ownerRecordName`
   - Check: ✅ QUERYABLE

### Metadata Indexes:
- Check: ✅ Enable recordName for queries
- Check: ✅ Enable createdBy for queries

---

## Record Type 3: AyahNote

### Fields to Add:
1. Click "Add Field"
   - Field Name: `ayahID`
   - Type: `String`
   - Check: ✅ Required

2. Click "Add Field"
   - Field Name: `surahNumber`
   - Type: `Int(64)`
   - Check: ✅ Required

3. Click "Add Field"
   - Field Name: `ayahNumber`
   - Type: `Int(64)`
   - Check: ✅ Required

4. Click "Add Field"
   - Field Name: `noteText`
   - Type: `String`
   - Check: ✅ Required

5. Click "Add Field"
   - Field Name: `createdAt`
   - Type: `Date/Time`
   - Check: ✅ Required

6. Click "Add Field"
   - Field Name: `modifiedAt`
   - Type: `Date/Time`
   - Check: ✅ Required

7. Click "Add Field"
   - Field Name: `ownerRecordName`
   - Type: `String`
   - Check: ✅ Required

### Indexes to Add:
1. Click "Add Index"
   - Field: `ayahID`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

2. Click "Add Index"
   - Field: `surahNumber`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

3. Click "Add Index"
   - Field: `ayahNumber`
   - Check: ✅ QUERYABLE

4. Click "Add Index"
   - Field: `createdAt`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

5. Click "Add Index"
   - Field: `modifiedAt`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

6. Click "Add Index"
   - Field: `ownerRecordName`
   - Check: ✅ QUERYABLE

### Metadata Indexes:
- Check: ✅ Enable recordName for queries
- Check: ✅ Enable createdBy for queries

---

## Record Type 4: ReadingProgress

### Fields to Add:
1. Click "Add Field"
   - Field Name: `surahNumber`
   - Type: `Int(64)`
   - Check: ✅ Required

2. Click "Add Field"
   - Field Name: `lastReadAyah`
   - Type: `Int(64)`
   - Check: ✅ Required

3. Click "Add Field"
   - Field Name: `totalAyahs`
   - Type: `Int(64)`
   - Check: ✅ Required

4. Click "Add Field"
   - Field Name: `progressPercentage`
   - Type: `Double`
   - Check: ✅ Required

5. Click "Add Field"
   - Field Name: `lastUpdatedAt`
   - Type: `Date/Time`
   - Check: ✅ Required

6. Click "Add Field"
   - Field Name: `ownerRecordName`
   - Type: `String`
   - Check: ✅ Required

### Indexes to Add:
1. Click "Add Index"
   - Field: `surahNumber`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

2. Click "Add Index"
   - Field: `lastReadAyah`
   - Check: ✅ QUERYABLE

3. Click "Add Index"
   - Field: `progressPercentage`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

4. Click "Add Index"
   - Field: `lastUpdatedAt`
   - Check: ✅ QUERYABLE
   - Check: ✅ SORTABLE

5. Click "Add Index"
   - Field: `ownerRecordName`
   - Check: ✅ QUERYABLE

### Metadata Indexes:
- Check: ✅ Enable recordName for queries
- Check: ✅ Enable createdBy for queries

---

## Security Settings (For ALL Record Types)

For each record type created above:

1. Click on the Record Type name
2. Go to "Security Roles" tab
3. Set the following permissions:

### World (Everyone):
- Create: ❌ No
- Read: ❌ No
- Write: ❌ No

### Authenticated (Signed-in users):
- Create: ❌ No
- Read: ❌ No
- Write: ❌ No

### Creator (Record owner only):
- Create: ✅ Yes (Private Database Only)
- Read: ✅ Yes
- Write: ✅ Yes

This ensures each user can ONLY access their own data.

---

## Step-by-Step Setup Process

### Step 1: Access CloudKit Dashboard
1. Go to: https://icloud.developer.apple.com/
2. Sign in with your Apple Developer account
3. Select your app or create new container
4. Container identifier: `iCloud.donald.kvietnamisht`

### Step 2: Select Environment
1. Click on "Development" environment first (for testing)
2. You'll deploy to Production later

### Step 3: Create Record Types
1. Click "Schema" in the left sidebar
2. Click "Record Types"
3. Click "+" button to add new record type

For each record type (UserProfile, FavoriteAyah, AyahNote, ReadingProgress):
1. Enter the Record Type Name exactly as shown above
2. Click "Add Field" and enter each field as specified
3. After adding all fields, go to "Indexes" tab
4. Add each index as specified
5. Save the record type

### Step 4: Test in Development
1. Build and run your app in Xcode
2. Sign in with Apple
3. Add a favorite, note, or read some verses
4. Go to CloudKit Dashboard → Data
5. Verify records appear correctly

### Step 5: Deploy to Production
1. Go to CloudKit Dashboard
2. Click "Schema" → "Deploy Schema Changes"
3. Select all record types
4. Click "Deploy to Production"
5. Confirm deployment

⚠️ **WARNING**: Once deployed to Production, schema changes are PERMANENT and cannot be undone!

---

## Verification Checklist

After creating the schema, verify:

- [ ] All 4 record types created
- [ ] All fields added with correct types
- [ ] All required fields marked as required
- [ ] All indexes added and configured
- [ ] Security roles set to "Creator only"
- [ ] Tested in Development environment
- [ ] Deployed to Production

---

## Quick Reference Table

| Record Type | Primary Index | Owner Field | Purpose |
|-------------|---------------|-------------|---------|
| UserProfile | appleUserID | (self) | User account info |
| FavoriteAyah | ayahID | ownerRecordName | Favorited verses |
| AyahNote | ayahID | ownerRecordName | User notes on verses |
| ReadingProgress | surahNumber | ownerRecordName | Reading progress per surah |

---

## Common Field Types Reference

When adding fields, use these exact types:

- **String**: Text data (IDs, names, notes)
- **Int(64)**: Numbers (surah numbers, ayah numbers)
- **Double**: Decimal numbers (percentages)
- **Date/Time**: Timestamps

---

## Need Help?

If you encounter errors:
1. Double-check field names match exactly (case-sensitive)
2. Ensure container identifier is correct: `iCloud.donald.kvietnamisht`
3. Verify you're signed into iCloud on your test device
4. Check Xcode capabilities are enabled
5. Review CloudKit logs in Xcode console

---

**Next**: After completing this setup, I'll update your app code to use the new container!
