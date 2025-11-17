# Al Marya Rostery - Coffee Delivery System

A complete coffee delivery ecosystem built with Flutter and Node.js.

## 📱 Project Structure

This repository contains the **customer mobile app** with integrated backend and cloud functions:

```
al_marya_rostery/ (GitHub repository)
├── lib/                    # Flutter app source code
│   ├── core/              # Core utilities, services, constants
│   ├── data/              # Data layer (repositories, models)
│   ├── features/          # Feature modules (auth, products, cart, orders)
│   └── main.dart          # App entry point
├── android/               # Android native code
├── ios/                   # iOS native code
├── backend/               # Node.js Express API
│   ├── routes/           # API routes
│   ├── models/           # MongoDB models
│   ├── middleware/       # Auth & validation
│   └── server.js         # Server entry point
├── functions/             # Firebase Cloud Functions
├── assets/                # Images, fonts, translations
├── test/                  # Unit and widget tests
└── pubspec.yaml          # Flutter dependencies
```

> **Note:** Staff and Driver apps are maintained as separate repositories/projects.

## 🚀 Quick Start

### Customer App
```bash
cd al_marya_rostery
flutter pub get
flutter run
```

### Backend (Local Development)
```bash
cd al_marya_rostery/backend
npm install
npm start
```

### Firebase Functions (Deploy)
```bash
cd al_marya_rostery/functions
npm install
firebase deploy --only functions
```

## 🛠️ Maintenance Scripts

- `build_all_apks.sh` - Build APKs for all apps
- `cleanup_for_production.sh` - Clean project for production
- `pre-push-security-check.sh` - Security checks before git push

## 📦 Tech Stack

- **Mobile:** Flutter (Dart)
- **Backend:** Node.js, Express, MongoDB
- **Cloud:** Firebase (Auth, Firestore, Functions, FCM)
- **Payment:** Stripe

---
Last cleaned: November 15, 2025
