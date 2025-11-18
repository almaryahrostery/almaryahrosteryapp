# Real Device Testing Guide

## 🎯 Purpose

Verify that the Al Marya Rostery app works correctly on real devices with the production backend after removing all localhost references.

**Critical Fix Applied:** ✅ All 3 localhost references removed (Commit: 9cb4555)

---

## 📋 Pre-Testing Checklist

### 1. Verify Configuration

**Backend URL:**
```dart
// lib/core/constants/app_constants.dart
static const bool _useProduction = true; // ✅ Must be true
static String get baseUrl => 'https://almaryahrostery.onrender.com'
```

**Files Fixed:**
- ✅ `lib/services/fcm_service.dart` - Now uses `AppConstants.baseUrl`
- ✅ `lib/core/services/websocket_service.dart` - Now uses `AppConstants.baseUrl`
- ✅ `lib/core/constants/app_constants.dart` - Production enabled

### 2. Build Release APK

```bash
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery"

# Clean previous builds
flutter clean
flutter pub get

# Build release APK
flutter build apk --release

# APK location:
# build/app/outputs/flutter-apk/app-release.apk
```

### 3. Install on Device

**Option A: Via USB (Android)**
```bash
# Install on connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# Or use Flutter
flutter install --release
```

**Option B: Via File Transfer**
1. Copy `app-release.apk` to device
2. Enable "Install from Unknown Sources"
3. Tap APK file to install

**Option C: iOS (if applicable)**
```bash
flutter build ios --release
# Then use Xcode to install on device
```

---

## 🧪 Testing Protocol

### Phase 1: Critical Backend Connectivity (30 min)

#### Test 1: Authentication Flow ✅
**Expected:** All auth operations connect to production backend

1. **Register New Account**
   - [ ] Open app on real device
   - [ ] Tap "Register"
   - [ ] Fill form with test data:
     ```
     Name: Test User
     Email: test@example.com
     Phone: +971501234567 (UAE format)
     Password: Test123!
     ```
   - [ ] Submit registration
   - [ ] ✅ **Verify:** Network request goes to `https://almaryahrostery.onrender.com/api/auth/register`
   - [ ] ✅ **Verify:** Success message or account created
   - [ ] ❌ **Fail if:** Connection refused, localhost error, timeout

2. **Login**
   - [ ] Use credentials from registration
   - [ ] Tap "Login"
   - [ ] ✅ **Verify:** Redirected to home page
   - [ ] ✅ **Verify:** Token saved locally
   - [ ] ✅ **Verify:** User profile loaded

3. **Token Refresh (Background Test)**
   - [ ] Leave app idle for 5-10 minutes
   - [ ] Perform any authenticated action
   - [ ] ✅ **Verify:** Token auto-refreshes
   - [ ] ✅ **Verify:** No logout occurs

4. **Logout**
   - [ ] Go to Profile → Settings → Logout
   - [ ] ✅ **Verify:** Redirected to login
   - [ ] ✅ **Verify:** Token cleared

#### Test 2: Product Catalog ✅
**Expected:** Products load from production API

1. **Browse Products**
   - [ ] Open home page
   - [ ] ✅ **Verify:** Products load (not empty)
   - [ ] ✅ **Verify:** Images display correctly
   - [ ] ✅ **Verify:** Prices show in AED
   - [ ] ❌ **Fail if:** "Connection refused", empty list with no error

2. **Product Details**
   - [ ] Tap any product
   - [ ] ✅ **Verify:** Full details load
   - [ ] ✅ **Verify:** Images load
   - [ ] ✅ **Verify:** Add to cart works

3. **Categories**
   - [ ] Browse by category
   - [ ] ✅ **Verify:** Category filtering works
   - [ ] ✅ **Verify:** Products match category

#### Test 3: Shopping Cart & Checkout ✅
**Expected:** Cart operations persist and checkout works

1. **Cart Management**
   - [ ] Add 2-3 products to cart
   - [ ] ✅ **Verify:** Cart count updates
   - [ ] ✅ **Verify:** Total calculates correctly
   - [ ] Update quantities
   - [ ] ✅ **Verify:** Total recalculates

2. **Checkout Process**
   - [ ] Proceed to checkout
   - [ ] Select delivery address (or add new)
   - [ ] ✅ **Verify:** Address API works (`/api/addresses`)
   - [ ] Select payment method
   - [ ] Place order
   - [ ] ✅ **Verify:** Order created successfully
   - [ ] ✅ **Verify:** Order ID received
   - [ ] ❌ **Fail if:** localhost error, payment gateway error

#### Test 4: Order Tracking ✅
**Expected:** Real-time tracking works via WebSocket

1. **View Orders**
   - [ ] Go to Orders page
   - [ ] ✅ **Verify:** Past orders load
   - [ ] ✅ **Verify:** Order statuses correct

2. **Track Active Order**
   - [ ] Tap on recent order
   - [ ] ✅ **Verify:** Tracking page opens
   - [ ] ✅ **Verify:** WebSocket connects to `https://almaryahrostery.onrender.com`
   - [ ] ✅ **Verify:** Order status shows
   - [ ] Wait 30 seconds
   - [ ] ✅ **Verify:** Real-time updates work (if driver active)
   - [ ] ❌ **Fail if:** WebSocket connection error, localhost error

---

### Phase 2: Feature Verification (45 min)

#### Test 5: Loyalty System ✅
**API:** `/api/loyalty/*`

- [ ] Go to Profile → Loyalty
- [ ] ✅ **Verify:** Points balance loads
- [ ] ✅ **Verify:** Rewards list loads
- [ ] ✅ **Verify:** Tier info displays
- [ ] Try redeeming a reward (if available)
- [ ] ✅ **Verify:** Redemption API works

#### Test 6: Referrals ✅
**API:** `/api/referrals/*`

- [ ] Go to Profile → Referrals
- [ ] ✅ **Verify:** Referral code generates
- [ ] ✅ **Verify:** Earnings display
- [ ] ✅ **Verify:** Statistics load
- [ ] Share referral code
- [ ] ✅ **Verify:** Share functionality works

#### Test 7: Subscriptions ✅
**API:** `/api/subscriptions/*`

- [ ] Go to Profile → Subscriptions
- [ ] ✅ **Verify:** Subscription plans load
- [ ] View plan details
- [ ] ✅ **Verify:** Plan info displays correctly
- [ ] (Optional) Subscribe to plan
- [ ] ✅ **Verify:** Subscription API works

#### Test 8: Reviews ✅
**API:** `/api/reviews/*`

- [ ] Go to any product
- [ ] Write a review
- [ ] ✅ **Verify:** Review submission works
- [ ] View product reviews
- [ ] ✅ **Verify:** Reviews load from API

#### Test 9: Brewing Methods ✅
**API:** `/api/brewing-methods/*`

- [ ] Go to Brewing Methods
- [ ] ✅ **Verify:** Methods list loads
- [ ] View method details
- [ ] ✅ **Verify:** Content displays
- [ ] Rate a method
- [ ] ✅ **Verify:** Rating API works

#### Test 10: Gift Sets ✅
**API:** `/api/gift-sets/*`

- [ ] Go to Gift Sets
- [ ] ✅ **Verify:** Gift sets load
- [ ] Filter by occasion
- [ ] ✅ **Verify:** Filtering works
- [ ] View gift details
- [ ] ✅ **Verify:** Can add to cart

---

### Phase 3: Push Notifications & FCM (15 min)

#### Test 11: FCM Token Registration ✅
**Fixed:** `lib/services/fcm_service.dart` now uses `AppConstants.baseUrl`

1. **Token Save to Backend**
   - [ ] Open app (or reinstall)
   - [ ] Login
   - [ ] **Behind the scenes:** FCM token sent to `/api/users/me/fcm-token`
   - [ ] ✅ **Verify in logs:** "✅ FCM token saved to backend"
   - [ ] ❌ **Fail if:** "localhost", "connection refused"

2. **Receive Notifications**
   - [ ] Trigger a test notification (admin panel or backend)
   - [ ] ✅ **Verify:** Notification received on device
   - [ ] Tap notification
   - [ ] ✅ **Verify:** App opens to correct screen

---

### Phase 4: Edge Cases & Error Handling (20 min)

#### Test 12: Network Conditions

1. **Slow Connection**
   - [ ] Enable device "slow 3G" mode
   - [ ] Browse products
   - [ ] ✅ **Verify:** Skeleton loaders display
   - [ ] ✅ **Verify:** Content eventually loads
   - [ ] ✅ **Verify:** No crashes

2. **Offline Mode**
   - [ ] Enable airplane mode
   - [ ] Try browsing products
   - [ ] ✅ **Verify:** Offline message shows
   - [ ] ✅ **Verify:** No crash
   - [ ] Disable airplane mode
   - [ ] ✅ **Verify:** App recovers

3. **API Timeout**
   - [ ] Perform action (e.g., load orders)
   - [ ] If backend is slow (cold start)
   - [ ] ✅ **Verify:** Loading indicator shows
   - [ ] ✅ **Verify:** Timeout handled gracefully (60s timeout)
   - [ ] ✅ **Verify:** Error message if timeout

#### Test 13: Data Validation

1. **Invalid Inputs**
   - [ ] Try registering with invalid email
   - [ ] ✅ **Verify:** Validation error shows
   - [ ] Try invalid UAE phone (e.g., "123")
   - [ ] ✅ **Verify:** Validation error shows

2. **Empty States**
   - [ ] New user with no orders
   - [ ] ✅ **Verify:** Empty state message
   - [ ] Empty wishlist
   - [ ] ✅ **Verify:** Empty state UI

---

## 📊 Test Results Template

```markdown
# Real Device Test Results - [DATE]

## Device Info
- Device: [e.g., Samsung Galaxy S21]
- OS: [e.g., Android 13]
- App Version: 1.0.5+5005
- Backend: https://almaryahrostery.onrender.com

## Phase 1: Critical Backend Connectivity ✅/❌
- [ ] Authentication (Register/Login/Logout)
- [ ] Product Catalog Loading
- [ ] Shopping Cart & Checkout
- [ ] Order Tracking & WebSocket

**Issues Found:**
- [List any issues]

## Phase 2: Feature Verification ✅/❌
- [ ] Loyalty System
- [ ] Referrals
- [ ] Subscriptions
- [ ] Reviews
- [ ] Brewing Methods
- [ ] Gift Sets

**Issues Found:**
- [List any issues]

## Phase 3: Push Notifications ✅/❌
- [ ] FCM Token Registration
- [ ] Notification Delivery

**Issues Found:**
- [List any issues]

## Phase 4: Edge Cases ✅/❌
- [ ] Slow Connection
- [ ] Offline Mode
- [ ] API Timeout
- [ ] Data Validation
- [ ] Empty States

**Issues Found:**
- [List any issues]

## Overall Assessment
- Backend Connectivity: ✅/❌
- All Features Working: ✅/❌
- Ready for Production: ✅/❌

## Next Steps
- [List any fixes needed]
```

---

## 🔍 Debugging Tips

### Check Logs During Testing

**Android (via USB):**
```bash
# Watch all app logs
adb logcat | grep "flutter"

# Watch for errors
adb logcat | grep -E "ERROR|EXCEPTION"

# Watch API calls
adb logcat | grep "http"
```

**iOS:**
```bash
# Use Xcode Console
# Or Flutter DevTools
flutter logs
```

### Common Issues & Solutions

| Issue | Likely Cause | Solution |
|-------|-------------|----------|
| "Connection refused" | Localhost still referenced | Check all files, rebuild |
| FCM token error | Token not sent to backend | Check `fcm_service.dart` logs |
| WebSocket not connecting | Wrong socket URL | Verify `websocket_service.dart` |
| Images not loading | CORS or wrong URL | Check image URL construction |
| Blank screens | API error | Check error handling in pages |

### Network Monitoring

**Use Charles Proxy or similar:**
1. Configure device to use proxy
2. Monitor all HTTP requests
3. ✅ **Verify:** All go to `almaryahrostery.onrender.com`
4. ❌ **Flag:** Any localhost or 192.168.* requests

---

## ✅ Success Criteria

**All tests must pass:**
- ✅ No localhost connection attempts
- ✅ All API calls go to production backend
- ✅ Authentication flow works end-to-end
- ✅ Products load and display
- ✅ Orders can be placed
- ✅ Real-time tracking connects
- ✅ All major features accessible
- ✅ FCM token saves to backend
- ✅ App handles offline mode gracefully
- ✅ No crashes during normal use

**If any test fails:**
1. Document the failure
2. Check logs for root cause
3. Fix the issue
4. Rebuild and retest
5. Update test results

---

## 📞 Post-Testing Actions

### If All Tests Pass ✅

1. **Document Results**
   - Fill out test results template
   - Take screenshots of key features
   - Note any performance observations

2. **Update Status**
   ```bash
   # Update ACTION_PLAN.md
   # Mark "Test on production backend" as complete
   ```

3. **Proceed to Next Phase**
   - Begin hardcoded color migration
   - Add skeleton loaders
   - Plan production deployment

### If Tests Fail ❌

1. **Document Failures**
   - Exact error messages
   - Steps to reproduce
   - Device info
   - Logs/screenshots

2. **Prioritize Fixes**
   - Critical: Auth, checkout, payment
   - High: Major features not working
   - Medium: UI issues, minor bugs

3. **Fix & Retest**
   - Fix issues one by one
   - Rebuild APK
   - Retest failed scenarios
   - Verify fix doesn't break other features

---

## 🎯 Quick Start Command

**Run this to build and deploy for testing:**

```bash
# Full rebuild and install
cd "/Volumes/PERSONAL/Al Marya Rostery APP/al_marya_rostery" && \
flutter clean && \
flutter pub get && \
flutter build apk --release && \
adb install -r build/app/outputs/flutter-apk/app-release.apk && \
echo "✅ App installed! Start testing..."
```

---

**Testing Prepared By:** GitHub Copilot  
**Date:** November 18, 2025  
**App Version:** 1.0.5+5005  
**Backend:** Production (https://almaryahrostery.onrender.com)  
**Critical Fixes Applied:** ✅ All localhost references removed (Commit: 9cb4555)
