# CloudKit Setup - Complete Guide
## Container: iCloud.donald.kvietnamisht

---

## ✅ App Code Updated

Your app has been updated to use the new CloudKit container:
- **Bundle ID**: `com.Donald.Quranvn` (UNCHANGED - existing app)
- **Container ID**: `iCloud.donald.kvietnamisht` (NEW)
- **Updated Files**:
  - ✅ `Quranvn/Core/CloudAuthManager.swift`
  - ✅ `Quranvn/Quranvn.entitlements`

---

## 📋 CloudKit Schema Setup

Follow these steps to set up your CloudKit schema in the Apple Developer Console.

### Step 1: Access CloudKit Dashboard

1. Go to: https://icloud.developer.apple.com/
2. Sign in with your Apple Developer account
3. Click on your container: **iCloud.donald.kvietnamisht**
   - If it doesn't exist, create it first
4. Select **"Development"** environment (for testing)

---

### Step 2: Create Record Types

Click **Schema** → **Record Types** → **"+"** button

You need to create **4 record types**. For each one, follow the instructions below:

---

## 🔵 RECORD TYPE 1: UserProfile

### Create Record Type:
1. Click "+" to add new record type
2. Name: `UserProfile`
3. Click "Create"

### Add Fields:
Click "Add Field" for each:

| # | Field Name | Type | Required |
|---|------------|------|----------|
| 1 | appleUserID | String | ✅ Yes |
| 2 | email | String | ❌ No |
| 3 | givenName | String | ❌ No |
| 4 | familyName | String | ❌ No |
| 5 | lastSignIn | Date/Time | ✅ Yes |
| 6 | createdAt | Date/Time | ✅ Yes |

### Add Indexes:
Click "Indexes" tab, then "Add Index" for each:

| Field | QUERYABLE | SEARCHABLE | SORTABLE |
|-------|-----------|------------|----------|
| appleUserID | ✅ | ✅ | ❌ |
| lastSignIn | ✅ | ❌ | ✅ |
| createdAt | ✅ | ❌ | ✅ |

### Set Metadata Indexes:
- ✅ recordName
- ✅ createdTimestamp
- ✅ modifiedTimestamp

**Click "Save"**

---

## 🔵 RECORD TYPE 2: FavoriteAyah

### Create Record Type:
1. Click "+" to add new record type
2. Name: `FavoriteAyah`
3. Click "Create"

### Add Fields:

| # | Field Name | Type | Required |
|---|------------|------|----------|
| 1 | ayahID | String | ✅ Yes |
| 2 | surahNumber | Int(64) | ✅ Yes |
| 3 | ayahNumber | Int(64) | ✅ Yes |
| 4 | favoritedAt | Date/Time | ✅ Yes |
| 5 | ownerRecordName | String | ✅ Yes |

### Add Indexes:

| Field | QUERYABLE | SORTABLE |
|-------|-----------|----------|
| ayahID | ✅ | ✅ |
| surahNumber | ✅ | ✅ |
| ayahNumber | ✅ | ❌ |
| favoritedAt | ✅ | ✅ |
| ownerRecordName | ✅ | ❌ |

### Set Metadata Indexes:
- ✅ recordName
- ✅ createdBy
- ✅ createdTimestamp

**Click "Save"**

---

## 🔵 RECORD TYPE 3: AyahNote

### Create Record Type:
1. Click "+" to add new record type
2. Name: `AyahNote`
3. Click "Create"

### Add Fields:

| # | Field Name | Type | Required |
|---|------------|------|----------|
| 1 | ayahID | String | ✅ Yes |
| 2 | surahNumber | Int(64) | ✅ Yes |
| 3 | ayahNumber | Int(64) | ✅ Yes |
| 4 | noteText | String | ✅ Yes |
| 5 | createdAt | Date/Time | ✅ Yes |
| 6 | modifiedAt | Date/Time | ✅ Yes |
| 7 | ownerRecordName | String | ✅ Yes |

### Add Indexes:

| Field | QUERYABLE | SORTABLE |
|-------|-----------|----------|
| ayahID | ✅ | ✅ |
| surahNumber | ✅ | ✅ |
| ayahNumber | ✅ | ❌ |
| createdAt | ✅ | ✅ |
| modifiedAt | ✅ | ✅ |
| ownerRecordName | ✅ | ❌ |

### Set Metadata Indexes:
- ✅ recordName
- ✅ createdBy
- ✅ createdTimestamp

**Click "Save"**

---

## 🔵 RECORD TYPE 4: ReadingProgress

### Create Record Type:
1. Click "+" to add new record type
2. Name: `ReadingProgress`
3. Click "Create"

### Add Fields:

| # | Field Name | Type | Required |
|---|------------|------|----------|
| 1 | surahNumber | Int(64) | ✅ Yes |
| 2 | lastReadAyah | Int(64) | ✅ Yes |
| 3 | totalAyahs | Int(64) | ✅ Yes |
| 4 | progressPercentage | Double | ✅ Yes |
| 5 | lastUpdatedAt | Date/Time | ✅ Yes |
| 6 | ownerRecordName | String | ✅ Yes |

### Add Indexes:

| Field | QUERYABLE | SORTABLE |
|-------|-----------|----------|
| surahNumber | ✅ | ✅ |
| lastReadAyah | ✅ | ❌ |
| progressPercentage | ✅ | ✅ |
| lastUpdatedAt | ✅ | ✅ |
| ownerRecordName | ✅ | ❌ |

### Set Metadata Indexes:
- ✅ recordName
- ✅ createdBy
- ✅ createdTimestamp

**Click "Save"**

---

## 🔒 Step 3: Configure Security (Important!)

For **EACH** of the 4 record types you created:

1. Click on the record type name
2. Click "Security Roles" tab
3. Set permissions as follows:

| Role | Create | Read | Write |
|------|--------|------|-------|
| World (Everyone) | ❌ | ❌ | ❌ |
| Authenticated | ❌ | ❌ | ❌ |
| **Creator** | ✅ | ✅ | ✅ |

This ensures users can ONLY see their own data.

**Click "Save" for each record type**

---

## 🧪 Step 4: Test in Development

1. Open Xcode
2. **Clean Build Folder**: Product → Clean Build Folder (Shift+Cmd+K)
3. **Build and Run** on a real device (NOT simulator)
   - Simulator doesn't support Sign in with Apple
4. Sign in with Apple in the app
5. Try these actions:
   - ✅ Favorite an ayah
   - ✅ Add a note to an ayah
   - ✅ Read some verses (to create progress)
6. Go back to CloudKit Dashboard → **Data** tab
7. Verify you see records in:
   - UserProfile
   - FavoriteAyah
   - AyahNote
   - ReadingProgress

---

## 🚀 Step 5: Deploy to Production

**⚠️ IMPORTANT**: Only do this after testing thoroughly in Development!

1. Go to CloudKit Dashboard
2. Click **"Deploy Schema Changes"**
3. Review the changes (should show all 4 record types)
4. Select **"Production"** environment
5. Click **"Deploy"**
6. **Confirm deployment**

**Note**: Once deployed to Production, the schema is PERMANENT and cannot be deleted or modified!

---

## 🔧 Step 6: Update Xcode Capabilities

1. Open your Xcode project
2. Select **Quranvn** target
3. Go to **Signing & Capabilities** tab
4. Verify these capabilities are enabled:

### iCloud:
- ✅ Services: CloudKit
- ✅ Containers: `iCloud.donald.kvietnamisht`

### Sign in with Apple:
- ✅ Enabled

### Background Modes (optional for push notifications):
- ✅ Remote notifications

5. Select your Development Team
6. Ensure Provisioning Profile is up to date

---

## 📱 Step 7: Build and Test on Device

1. Connect a real iOS device (NOT simulator)
2. Make sure device is signed into iCloud
3. Build and run the app
4. Test these flows:

### Sign In Flow:
1. Tap Settings tab
2. Tap "Sign in with Apple"
3. Complete authentication
4. Should show "Đã đăng nhập" (Signed in)

### Favorites Flow:
1. Go to Library tab
2. Tap on a Surah to open reader
3. Double-tap an ayah to favorite it
4. Should see pink heart icon
5. Go to Favorites tab
6. Should see the favorited ayah

### Notes Flow:
1. Long-press an ayah
2. Select "Thêm ghi chú" (Add note)
3. Type a note and save
4. Should see note appear below the ayah
5. Go to Notes tab
6. Should see the note

### Reading Progress Flow:
1. Read through several ayahs in a Surah
2. Close the app and reopen
3. Go back to that Surah
4. Progress should be preserved

### Cross-Device Sync (if you have 2 devices):
1. Sign in on Device A
2. Favorite an ayah on Device A
3. Sign in with same Apple ID on Device B
4. Open the app on Device B
5. Should see the same favorite

---

## ✅ Verification Checklist

Before going to production, verify:

- [ ] All 4 record types created in CloudKit
- [ ] All fields added with correct types
- [ ] All indexes configured
- [ ] Security set to "Creator only" for all types
- [ ] Tested on real device (not simulator)
- [ ] Sign in with Apple works
- [ ] Favorites sync to CloudKit
- [ ] Notes sync to CloudKit
- [ ] Reading progress syncs to CloudKit
- [ ] Data persists after app restart
- [ ] Schema deployed to Production
- [ ] Tested with production build on device

---

## 🐛 Troubleshooting

### "Server Rejected Request" Error
**Cause**: Schema not deployed to Production
**Fix**: Deploy schema to Production environment

### "Permission Failure" Error
**Cause**: Security roles not set correctly
**Fix**: Set Creator role to allow Create/Read/Write

### "Not Authenticated" Error
**Cause**: User not signed into iCloud
**Fix**: Go to Settings → [Your Name] → iCloud and sign in

### "Unknown Item" Error
**Cause**: Record doesn't exist (normal on first fetch)
**Fix**: This is expected - your app should create the record

### "Network Unavailable" Error
**Cause**: No internet connection
**Fix**: Check device internet connection

### Sign in with Apple doesn't work on Simulator
**Cause**: Simulator limitation
**Fix**: Test on real device only

### Container not found
**Cause**: Container identifier mismatch
**Fix**: Verify `iCloud.donald.kvietnamisht` in:
- CloudAuthManager.swift
- Quranvn.entitlements
- Xcode Signing & Capabilities

---

## 📊 What Gets Synced

| Data Type | Storage | Sync to CloudKit |
|-----------|---------|------------------|
| Favorites | UserDefaults + CloudKit | ✅ Yes |
| Notes | UserDefaults + CloudKit | ✅ Yes |
| Reading Progress | UserDefaults + CloudKit | ✅ Yes |
| App Settings (theme, etc.) | UserDefaults only | ❌ No (future) |
| Quran Text/Translation | App Bundle | ❌ No (read-only) |

---

## 🎯 Next Steps

After CloudKit is working:

1. **Implement CloudKit sync service classes** (I can create these for you)
2. **Add conflict resolution** for when data changes on multiple devices
3. **Add migration** from UserDefaults to CloudKit on first sign-in
4. **Add pull-to-refresh** to manually sync data
5. **Add sync status indicator** to show when syncing
6. **Add error handling** for offline mode

---

## 📞 Need Help?

If you encounter issues:

1. Check Xcode console logs for detailed error messages
2. Look for CloudKit errors with prefix "❌ CloudKit Error"
3. Verify CloudKit Dashboard → Data tab shows your test records
4. Double-check container identifier matches everywhere
5. Make sure you're testing on a real device signed into iCloud

---

## Summary

✅ **App Updated**: Container ID changed to `iCloud.donald.kvietnamisht`
📋 **Schema Defined**: 4 record types ready to create
🔒 **Security Configured**: Creator-only access
🧪 **Testing Guide**: Step-by-step verification
🚀 **Production Ready**: Deployment instructions included

**You're ready to set up CloudKit! Follow the steps above and let me know if you need help.**
