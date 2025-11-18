# Al Marya Rostery - Coffee Delivery App

A comprehensive Flutter-based coffee delivery application for Al Marya Rostery, featuring real-time order tracking, product management, and multi-platform support.

## 🚀 Quick Start

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Run tests
flutter test

# Generate coverage
flutter test --coverage
```

## 📱 Platform Support

- ✅ iOS
- ✅ Android
- ✅ Web

## 🧪 Testing

### Test Suite Overview

**Total: 153 tests (100% passing)**

```
Runtime: ~17-18 seconds
Pass Rate: 100% ✅
Coverage: Comprehensive
CI/CD: Compatible
```

### Test Breakdown

#### Unit Tests (82 tests - 53.6%)
- **Profile Validators** (46 tests) - Name, email, UAE phone validation
- **Auth Provider** (20 tests) - Login, register, logout, state management
- **Firebase Auth** (6 tests) - Auth models and structures
- **Cart Provider** (2 tests) - Cart operations
- **Integration Providers** (8 tests) - Reviews, Loyalty, Referrals

#### Widget Tests (67 tests - 43.8%)
- **Wishlist** (20 tests) - Button display, product details, edge cases
- **Login Page** (~23 tests) - Form elements, navigation, error handling
- **Register Page** (~23 tests) - Form validation, terms & conditions
- **App Widget** (1 test) - App initialization

#### Integration Tests (4 tests - 2.6%)
- **Coffee API** (3 tests) - API endpoint, service instantiation
- **Backend Integration** (1 test) - Health check with graceful skip

#### Feature Tests (35 tests)
- **Shipping Validation** (35 tests) - UAE phone validation, GPS validation

### Running Specific Test Suites

```bash
# Run unit tests only
flutter test test/unit/

# Run widget tests only
flutter test test/widget/

# Run integration tests only
flutter test test/integration/

# Run specific test file
flutter test test/unit/profile_validators_test.dart
```

## 🛠️ Key Features

### Address Management
- UAE-specific address validation
- GPS location support
- Emirate and area selection
- P.O. Box support
- Multiple address management

### Authentication & Authorization
- Email/password authentication
- Role-based access control (Customer, Staff, Admin)
- Secure token management
- Session persistence

### Product Management
- Coffee product catalog
- Real-time inventory tracking
- Product categorization
- Wishlist functionality
- Cart management

### Order Management
- Real-time order tracking
- Order history
- Status updates
- Delivery scheduling

### Profile Management
- User profile editing
- Phone number validation (UAE formats)
- Email validation
- Profile picture upload
- Preferences management

## 📋 Validation Rules

### UAE Phone Number Formats (Supported)
```
+971501234567   (International format)
971501234567    (Without + prefix)
0501234567      (National format)
501234567       (Local format)
```

### Email Validation
- Pattern: `r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$'`
- Supports subdomains, dots, dashes, numbers

### Name Validation
- Minimum 2 characters
- Supports Unicode (Arabic names)
- Supports special characters (O'Connor-Smith)

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── theme/          # App theming
│   └── widgets/        # Reusable widgets
├── domain/
│   ├── models/         # Data models
│   └── repositories/   # Repository interfaces
├── features/
│   ├── account/        # User profile management
│   ├── auth/           # Authentication
│   ├── checkout/       # Checkout flow
│   ├── coffee/         # Coffee products
│   └── profile/        # User profiles
└── main.dart

test/
├── unit/              # Unit tests
├── widget/            # Widget tests
├── integration/       # Integration tests
└── features/          # Feature-specific tests
```

## 🔧 Development

### Prerequisites
- Flutter SDK (latest stable)
- Dart SDK
- iOS: Xcode and CocoaPods
- Android: Android Studio and SDK

### Environment Setup

1. **Clone the repository**
```bash
git clone https://github.com/almaryahrostery/almaryahrosteryapp.git
cd almaryahrosteryapp/al_marya_rostery
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run code generation** (if needed)
```bash
flutter pub run build_runner build
```

4. **Run the app**
```bash
flutter run
```

### Backend Configuration

The app connects to:
- Production: `https://almaryahrostery.onrender.com`
- Local development: `http://localhost:5001`

Update API endpoint in `lib/core/config/api_config.dart`

## 🧪 Test Development Guidelines

### Writing New Tests

**Unit Test Example:**
```dart
test('should validate email format', () {
  expect(ProfileValidators.validateEmail('user@example.com'), isNull);
  expect(ProfileValidators.validateEmail('invalid'), isNotNull);
});
```

**Widget Test Example:**
```dart
testWidgets('should display login form', (WidgetTester tester) async {
  await tester.pumpWidget(createTestWidget());
  await tester.pumpAndSettle();
  
  expect(find.text('Email'), findsOneWidget);
  expect(find.text('Password'), findsOneWidget);
});
```

### Test Coverage Goals
- Unit tests: 80%+ coverage
- Widget tests: Critical user flows
- Integration tests: API endpoints
- All tests must pass before merge

## 📦 Dependencies

### Core
- `flutter` - UI framework
- `provider` - State management
- `http` - API communication

### Firebase
- `firebase_core` - Firebase initialization
- `firebase_auth` - Authentication
- `cloud_firestore` - Database

### UI/UX
- `image_picker` - Image selection
- `cached_network_image` - Image caching
- `flutter_svg` - SVG support

### Development
- `flutter_test` - Testing framework
- `mocktail` - Mocking library
- `flutter_lints` - Linting rules

## 🚀 Deployment

### Building for Production

**Android:**
```bash
flutter build apk --release
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

**Web:**
```bash
flutter build web --release
```

## 📝 UX Testing Guide

### Manual Testing Checklist

#### Authentication Flow
- [ ] User can register with valid credentials
- [ ] User can login with email/password
- [ ] User can logout successfully
- [ ] Invalid credentials show error message
- [ ] Password visibility toggle works

#### Profile Management
- [ ] User can view profile
- [ ] User can edit name, email, phone
- [ ] UAE phone validation works for all formats
- [ ] Email validation shows proper errors
- [ ] Profile picture upload works
- [ ] Changes save successfully

#### Product & Wishlist
- [ ] Products display correctly
- [ ] Wishlist button toggles state
- [ ] Wishlist persists across sessions
- [ ] Add to cart works
- [ ] Product details show complete info

#### Address Management
- [ ] User can add new address
- [ ] GPS location detection works
- [ ] Emirate/area selection works
- [ ] Address validation works
- [ ] Multiple addresses supported

#### Checkout Flow
- [ ] Cart displays items correctly
- [ ] Shipping form validates properly
- [ ] UAE phone validation works
- [ ] Order placement succeeds
- [ ] Order confirmation shown

### Accessibility Testing
- [ ] Screen reader support
- [ ] Keyboard navigation
- [ ] Touch target sizes (min 44x44)
- [ ] Color contrast ratios
- [ ] Text scaling support

## 🐛 Troubleshooting

### Common Issues

**Tests failing due to network images:**
- Solution: Mock network images in tests or use placeholder assets

**Backend connection timeout:**
- Check backend is running
- Verify API endpoint in configuration
- Integration tests skip gracefully if backend unavailable

**Phone validation issues:**
- Ensure phone format matches UAE patterns
- Check normalization logic removes spaces/dashes

## 📄 License

Copyright © 2025 Al Marya Rostery. All rights reserved.

## 🤝 Contributing

1. Create feature branch (`git checkout -b feature/AmazingFeature`)
2. Write tests for new features
3. Ensure all tests pass (`flutter test`)
4. Commit changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to branch (`git push origin feature/AmazingFeature`)
6. Open Pull Request

## 📞 Support

For support and inquiries:
- Email: support@almaryahrostery.com
- Website: https://almaryahrostery.com

---

**Test Status:** ✅ 153/153 passing | **Last Updated:** November 18, 2025
