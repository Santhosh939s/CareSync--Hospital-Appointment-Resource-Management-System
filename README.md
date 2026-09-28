# CareSync — Hospital Appointment & Resource Management System

CareSync is a full-stack, enterprise-grade healthcare management ecosystem providing synchronized patient appointment scheduling, doctor clinical consultations, hospital bed allocations, blood bank stock tracking, and diagnostic equipment reservations.

---

## 🏛️ Ecosystem Structure

The repository contains two dedicated client applications backed by a single unified REST API and MongoDB Atlas cloud database:

```
CareSync/
├── server.js               # Node.js + Express REST API Backend
├── models.js               # Mongoose MongoDB schemas
├── index.html              # Web Client (SPA HTML5 / Tailwind CSS / Vanilla JS)
├── app.js                  # Web Client business logic & UI router
├── style.css               # Web Client styling & themes
└── caresync_mobile/        # Native Flutter Mobile Application
    ├── lib/                # Production Dart source code (Clean Architecture)
    ├── test/               # Unit & Widget test suites
    └── README.md           # Mobile app documentation and architecture
```

---

## 🚀 Running the Applications

### 1. Backend Server
```bash
# Install dependencies
npm install

# Start the Express server (Runs on port 3000 by default)
node server.js
```
The server connects to MongoDB Atlas and provides all REST API endpoints under `/api/*`.

### 2. Web Client
Once the backend is running, open `http://localhost:3000` in any web browser.

### 3. Flutter Mobile Client
```bash
cd caresync_mobile

# Fetch packages
flutter pub get

# Run unit & widget tests
flutter test

# Launch mobile application on an emulator or connected device
flutter run
```

---

## 📚 Technical Documentation & Architecture Reference

For in-depth architecture breakdowns and mobile client specifications:
- [Flutter Mobile Documentation](caresync_mobile/README.md)
- [System Architecture & Engineering Specification](ARCHITECTURE_AND_ENGINEERING_GUIDE.md)

---

## 💎 Engineering Standards & Architectural Principles

This application has been engineered to production-grade benchmarks with a focus on:
- **Trust-Centric Reliability**: Real-time capacity transparency with pre-flight availability checks and transparent billing ledgers with zero hidden fees.
- **Pixel-Perfect Craft**: Bespoke Material 3 design system, sleek dark mode (`#0D1117`), fluid 60 FPS transitions, and micro-interactions.
- **Deep Flutter Mastery**: Clean Architecture, Provider state management (`InheritedWidget` wrapper), sound null safety, and scoped element rebuilds.
- **Storage, Threading & Performance**: Non-blocking asynchronous event loop, `SharedPreferences` session recovery, zero-jank `ListView.builder` viewport virtualization, and eliminated battery-draining polling.
- **Production-Ready Engineering**: Production Android bundle configuration, automated CI/CD pipeline, and complete unit/widget test suites.
