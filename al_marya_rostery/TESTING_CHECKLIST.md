# Real Device Testing Checklist ✅

**Date:** November 19, 2025  
**Tester:** _________________  
**Device:** _________________  
**OS Version:** _________________  
**App Version:** 1.0.5+5005  
**Backend:** https://almaryahrostery.onrender.com

---

## ⚡ Quick Start

```bash
# APK Location (after build completes):
# build/app/outputs/flutter-apk/app-release.apk

# Install on device:
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Monitor logs while testing:
adb logcat | grep -E "flutter|ERROR"
```

---

## 🔴 Phase 1: Critical Backend Connectivity (30 min)

### ✅ Authentication Flow

- [ ] **Register New Account**
  - Email: test_`[timestamp]`@example.com
  - Phone: +971501234567
  - Result: ✅ Success / ❌ Failed
  - Notes: _________________

- [ ] **Login**
  - Result: ✅ Success / ❌ Failed
  - Token saved: ✅ Yes / ❌ No
  - Notes: _________________

- [ ] **Logout**
  - Result: ✅ Success / ❌ Failed
  - Cleared data: ✅ Yes / ❌ No

### ✅ Product Catalog

- [ ] **Home Page Products Load**
  - Products displayed: ✅ Yes / ❌ No
  - Images load: ✅ Yes / ❌ No
  - Count: _____ products
  - Notes: _________________

- [ ] **Product Details**
  - Details load: ✅ Yes / ❌ No
  - Add to cart works: ✅ Yes / ❌ No

### ✅ Shopping Cart & Checkout

- [ ] **Add to Cart**
  - Items added: _____ items
  - Total calculates: ✅ Yes / ❌ No

- [ ] **Checkout**
  - Address selection: ✅ Yes / ❌ No
  - Order placed: ✅ Yes / ❌ No
  - Order ID: _________________

### ✅ Order Tracking

- [ ] **View Orders**
  - Orders list loads: ✅ Yes / ❌ No
  - Count: _____ orders

- [ ] **Real-time Tracking**
  - WebSocket connects: ✅ Yes / ❌ No
  - Status updates: ✅ Yes / ❌ No
  - Notes: _________________

**Phase 1 Result:** ✅ PASS / ❌ FAIL

---

## 🟡 Phase 2: Feature Verification (45 min)

### ✅ Loyalty System

- [ ] **View Points**
  - Points load: ✅ Yes / ❌ No
  - Balance: _____ points

- [ ] **Rewards**
  - Rewards list: ✅ Yes / ❌ No
  - Count: _____ rewards

- [ ] **Tier Info**
  - Tier displayed: ✅ Yes / ❌ No
  - Current tier: _________________

### ✅ Referrals

- [ ] **Referral Code**
  - Code generated: ✅ Yes / ❌ No
  - Code: _________________

- [ ] **Earnings**
  - Earnings displayed: ✅ Yes / ❌ No
  - Amount: _________________

### ✅ Subscriptions

- [ ] **View Plans**
  - Plans load: ✅ Yes / ❌ No
  - Count: _____ plans

- [ ] **Plan Details**
  - Details displayed: ✅ Yes / ❌ No

### ✅ Reviews

- [ ] **Write Review**
  - Submission works: ✅ Yes / ❌ No

- [ ] **View Reviews**
  - Reviews load: ✅ Yes / ❌ No

### ✅ Brewing Methods

- [ ] **Methods List**
  - Methods load: ✅ Yes / ❌ No
  - Count: _____ methods

- [ ] **Rate Method**
  - Rating works: ✅ Yes / ❌ No

### ✅ Gift Sets

- [ ] **Gift Catalog**
  - Sets load: ✅ Yes / ❌ No
  - Count: _____ sets

- [ ] **Occasion Filter**
  - Filtering works: ✅ Yes / ❌ No

**Phase 2 Result:** ✅ PASS / ❌ FAIL

---

## 🔵 Phase 3: Push Notifications (15 min)

### ✅ FCM Token

- [ ] **Token Registration**
  - Check logs for: "✅ FCM token saved to backend"
  - Result: ✅ Found / ❌ Not found
  - Token: _________________

- [ ] **Notification Receipt**
  - Sent test notification: ✅ Yes / ❌ No
  - Received: ✅ Yes / ❌ No
  - Tap opens app: ✅ Yes / ❌ No

**Phase 3 Result:** ✅ PASS / ❌ FAIL

---

## 🟢 Phase 4: Edge Cases (20 min)

### ✅ Network Conditions

- [ ] **Slow Connection**
  - Skeleton loaders show: ✅ Yes / ❌ No
  - Content loads eventually: ✅ Yes / ❌ No

- [ ] **Offline Mode**
  - Error message shown: ✅ Yes / ❌ No
  - No crash: ✅ Yes / ❌ No
  - Recovers when online: ✅ Yes / ❌ No

- [ ] **API Timeout**
  - Timeout handled gracefully: ✅ Yes / ❌ No
  - Error message clear: ✅ Yes / ❌ No

### ✅ Data Validation

- [ ] **Invalid Email**
  - Validation error: ✅ Yes / ❌ No

- [ ] **Invalid Phone**
  - Validation error: ✅ Yes / ❌ No

### ✅ Empty States

- [ ] **No Orders**
  - Empty state message: ✅ Yes / ❌ No

- [ ] **Empty Wishlist**
  - Empty state UI: ✅ Yes / ❌ No

**Phase 4 Result:** ✅ PASS / ❌ FAIL

---

## 🎯 Critical Checks

### ❌ NO Localhost Errors
- [ ] Check logs for "localhost"
- [ ] Check logs for "connection refused"
- [ ] Check logs for "192.168"
- **Result:** ✅ Clean / ❌ Found issues

### ✅ All Production URLs
- [ ] All requests to `almaryahrostery.onrender.com`
- [ ] WebSocket connects to production
- [ ] Images load from production
- **Result:** ✅ All production / ❌ Issues found

### ✅ No Crashes
- [ ] App stable during testing
- [ ] No unexpected crashes
- [ ] Memory usage acceptable
- **Result:** ✅ Stable / ❌ Crashed

---

## 📊 Test Summary

**Total Tests:** _____ / _____  
**Passed:** _____ tests  
**Failed:** _____ tests  
**Skipped:** _____ tests

**Overall Result:** ✅ PASS / ❌ FAIL

---

## 🐛 Issues Found

| # | Issue | Severity | Steps to Reproduce | Notes |
|---|-------|----------|-------------------|-------|
| 1 | | 🔴/🟡/🟢 | | |
| 2 | | 🔴/🟡/🟢 | | |
| 3 | | 🔴/🟡/🟢 | | |

---

## ✅ Final Verdict

**Ready for Production?** ✅ YES / ❌ NO

**Confidence Level:** ⭐⭐⭐⭐⭐ / 5

**Recommended Actions:**
- [ ] _________________
- [ ] _________________
- [ ] _________________

**Notes:**
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

---

## 📸 Screenshots

**Attach screenshots of:**
- [ ] Successful login
- [ ] Product catalog
- [ ] Order tracking
- [ ] Any errors encountered

---

**Testing Completed:** _______________  
**Duration:** _____ minutes  
**Signed:** _______________
