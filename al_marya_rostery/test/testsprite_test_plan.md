# TestSprite Automated Test Plan
## Al Marya Rostery Coffee Delivery App

### Test Execution Date: November 18, 2025

## 🎯 Testing Objectives
1. Validate recent UI improvements (font sizes, wishlist)
2. Ensure profile page enhancements work correctly
3. Test critical user flows end-to-end
4. Verify API integrations and error handling
5. Performance and responsiveness testing

## 📋 Test Suites

### Suite 1: UI/UX Testing
- [ ] Font sizes are reduced and readable across all screens
- [ ] Theme consistency (light/dark mode)
- [ ] Responsive layout on different screen sizes
- [ ] Button and icon sizes are appropriate
- [ ] Text hierarchy is clear

### Suite 2: Wishlist Functionality
- [ ] Add product to wishlist from product card
- [ ] Add product to wishlist from product detail page
- [ ] Remove product from wishlist
- [ ] Wishlist persistence across sessions
- [ ] Wishlist icon state updates correctly (filled/unfilled)
- [ ] Loading indicators during wishlist operations
- [ ] Error handling for network failures

### Suite 3: Profile Page Features
- [ ] Profile completion indicator displays correctly
- [ ] Address management navigation
- [ ] UAE phone number validation
- [ ] Email and push notification toggles
- [ ] Image upload (camera/gallery selection)
- [ ] 5MB file size validation
- [ ] Profile data persistence
- [ ] Error messages display appropriately

### Suite 4: Authentication
- [ ] Firebase authentication login
- [ ] JWT token authentication
- [ ] Session management
- [ ] Token refresh
- [ ] Logout functionality
- [ ] Protected routes redirect properly

### Suite 5: Shopping Cart
- [ ] Add coffee product with size selection
- [ ] Update quantity
- [ ] Remove items
- [ ] Cart total calculation
- [ ] Cart persistence
- [ ] Size-specific pricing

### Suite 6: Product Browsing
- [ ] Product list loads correctly
- [ ] Product detail page displays all info
- [ ] Product search functionality
- [ ] Category filtering
- [ ] Sort options (name, price, rating)
- [ ] Product images load with placeholders

### Suite 7: Checkout Flow
- [ ] Address selection
- [ ] Payment method selection
- [ ] Order summary accuracy
- [ ] Order placement
- [ ] Order confirmation

### Suite 8: API Integration
- [ ] Coffee products API
- [ ] Wishlist API (add, remove, check, count)
- [ ] User profile API
- [ ] Cart API
- [ ] Order API
- [ ] Address API
- [ ] Error handling for 404, 500, timeout

### Suite 9: Performance
- [ ] App startup time < 3 seconds
- [ ] List scrolling is smooth
- [ ] Image loading performance
- [ ] API response times < 2 seconds
- [ ] Memory usage within limits

### Suite 10: Edge Cases
- [ ] No internet connection handling
- [ ] Empty states (no products, empty cart, no wishlist)
- [ ] Invalid input handling
- [ ] Session expiry
- [ ] Concurrent operations

## 🔑 TestSprite Configuration
- **API Key**: Configured in `.testsprite.config.json`
- **Framework**: Flutter with flutter_test
- **CI/CD**: Ready for integration
- **Coverage Goal**: 80%+ code coverage

## 📊 Success Criteria
- All critical user flows pass
- No blocking bugs
- Performance benchmarks met
- Error handling is graceful
- UI is consistent and polished
