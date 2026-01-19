# 🧪 QUICK TEST GUIDE - SERMONS FEATURE

## ⚡ Ready to Test!

Your backend is **running and ready**. Follow these steps to verify everything works.

---

## 1️⃣ Login as Editor

```
Username: sayunitanzania7@gmail.com
Password: (your password)
```

**Expected Result:** ✅ Login successful, redirected to home screen

---

## 2️⃣ Open Sermons Tab

- Tap **Sermons** in bottom navigation

**Expected Results:**
- ✅ See sermons list (may be empty if no sermons yet)
- ✅ See **+** button in top-right (editor only)
- ✅ See filter buttons (Category, Pastor, Topics)
- ✅ See search bar

---

## 3️⃣ Upload First Sermon

1. **Tap + button**
   - Opens upload form

2. **Fill the form:**
   - Title: `Faith in Action`
   - Pastor: `Mzaliwa Edward`
   - Category: `Sunday Service`
   - Topics: `Faith, Prayer, Miracles`
   - Duration: `45:30`
   - Description: `A powerful sermon about putting your faith into action`

3. **Upload files:**
   - Tap "Select Thumbnail" → Choose image
   - Tap "Select Audio File" → Choose audio (MP3/M4A)
   - OR tap "Select Video File" → Choose video (MP4/MOV)

4. **Tap UPLOAD SERMON**

**Expected Results:**
- ✅ Loading spinner appears
- ✅ Success message appears
- ✅ Returns to sermons list
- ✅ New sermon appears at top of list
- ✅ Django console shows: `📤 Creating sermon...` then `✅ Sermon created successfully`

**If it fails:**
- Check file size < 100MB
- Check at least audio OR video selected
- Check Django console for errors

---

## 4️⃣ Test Sermon Display

**Check sermon card shows:**
- ✅ Thumbnail image
- ✅ Title: "Faith in Action"
- ✅ Pastor: "Mzaliwa Edward"
- ✅ Category badge: "Sunday Service"
- ✅ Duration: "45:30"
- ✅ View count: "0 views"
- ✅ Edit button (pencil icon) - editor only

---

## 5️⃣ Test Search

1. **Tap search bar**
2. **Type:** `faith`

**Expected Results:**
- ✅ List filters to show only sermons with "faith" in title/description/topics/pastor
- ✅ See "Faith in Action" sermon
- ✅ Search updates after typing stops (500ms debounce)

3. **Clear search**
   - ✅ All sermons appear again

---

## 6️⃣ Test Filters

### Category Filter:
1. **Tap "Category" filter**
2. **Select "Sunday Service"**

**Expected Results:**
- ✅ Only Sunday Service sermons shown
- ✅ Filter button shows "Category: Sunday Service"
- ✅ Tap ✕ to clear → All sermons appear

### Pastor Filter:
1. **Tap "Pastor" filter**
2. **Select "Mzaliwa Edward"**

**Expected Results:**
- ✅ Only that pastor's sermons shown
- ✅ Filter button shows "Pastor: Mzaliwa Edward"

### Topics Filter:
1. **Tap "Topics" filter**
2. **Select "Faith"**

**Expected Results:**
- ✅ Only sermons with "Faith" topic shown
- ✅ Filter button shows "Topics: Faith"

### Clear All Filters:
1. **Tap "Clear" button**

**Expected Results:**
- ✅ All filters removed
- ✅ All sermons appear

---

## 7️⃣ Test Edit

1. **Tap edit button** (pencil icon) on sermon card

**Expected Results:**
- ✅ Upload form opens
- ✅ All fields pre-filled with sermon data
- ✅ Title shows "Edit Sermon"

2. **Change something:**
   - Update description: `An amazing sermon about faith and miracles`

3. **Tap UPDATE SERMON**

**Expected Results:**
- ✅ Loading spinner
- ✅ Success message
- ✅ Returns to list
- ✅ Sermon shows updated description
- ✅ Django console shows: `📝 Updating sermon...` then `✅ Sermon updated successfully`

---

## 8️⃣ Test View Increment

1. **Tap a sermon card** to view details

**Expected Results:**
- ✅ Sermon detail page opens
- ✅ View count increments (0 → 1)
- ✅ Django console shows: `📖 Sermon retrieved: Faith in Action (Views: 1)`

2. **Go back and check list:**
   - ✅ View count shows "1 views"

---

## 9️⃣ Upload Multiple Sermons

Upload 2-3 more sermons with different:
- Categories (Midweek Service, Youth Service, etc.)
- Pastors (try different names)
- Topics

**Expected Results:**
- ✅ All sermons appear in list
- ✅ Sorted by newest first
- ✅ Filters work with multiple sermons
- ✅ Search works across all sermons

---

## 🔟 Test Grid/List View Toggle

1. **Switch between grid and list view**

**Expected Results:**
- ✅ Both views show all sermons
- ✅ No overflow errors
- ✅ All sermon data visible
- ✅ Edit buttons visible in both views

---

## ✅ Success Criteria

If all tests pass:
- ✅ Upload works
- ✅ Edit works
- ✅ Search works
- ✅ Filters work
- ✅ View count works
- ✅ Files are saved
- ✅ Database persistence works

**🎉 SERMONS FEATURE IS COMPLETE!**

---

## 🐛 Common Issues

### Issue: + Button Not Visible
**Cause:** User role is not 'editor'
**Fix:** 
1. Check user role in database
2. Re-login
3. Verify `role='editor'` in user table

### Issue: Upload Fails
**Cause:** File too large or no audio/video
**Fix:**
1. Check file size < 100MB
2. Ensure audio OR video selected
3. Check Django console for error

### Issue: Sermon Doesn't Appear
**Cause:** Not refreshing list
**Fix:**
1. Pull down to refresh
2. Navigate away and back
3. Check `is_active=True` in database

### Issue: Edit Button Missing
**Cause:** Not logged in as editor
**Fix:**
1. Verify login credentials
2. Check user role
3. Re-login

---

## 📊 Check Database

To verify sermons in database:

```python
cd backend
python manage.py shell
```

```python
from church.models import Sermon

# List all sermons
for sermon in Sermon.objects.all():
    print(f"{sermon.id}: {sermon.title} by {sermon.preacher}")
    print(f"   Category: {sermon.category}")
    print(f"   Topics: {sermon.topics}")
    print(f"   Has audio: {sermon.has_audio}")
    print(f"   Has video: {sermon.has_video}")
    print(f"   Views: {sermon.views}")
    print()
```

---

## 🚀 You're All Set!

Start testing and enjoy your fully functional sermons management system! 🎉
