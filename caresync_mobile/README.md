# CareSync — Flutter Hospital Appointment & Resource Management App

> **Production-ready, cross-platform mobile client for hospital appointment scheduling, clinical consultations, diagnostic equipment reservations, and real-time hospital resource management.**

---

## 🏥 Project Overview & Problem Statement

Modern hospitals face severe bottlenecks in coordinating outpatient appointments, operating room resources, diagnostic machinery, and inpatient bed occupancy. Traditional web portals often struggle on mobile devices, rely on aggressive constant polling, and lack native offline resilience or intuitive mobile-first workflows.

**CareSync Mobile** transforms the existing Node.js / Express / MongoDB hospital backend into a native Flutter application built with **Dart**, **Material 3**, and the **Provider** state management pattern. It delivers dedicated, role-tailored experiences for **Patients**, **Doctors**, and **Hospital Administrators** with clinical-grade reliability.

---

## 📐 System Architecture

CareSync follows a clean layered architecture with strict separation of presentation, state management, domain business logic, and network transport:

```
┌────────────────────────────────────────────────────────┐
│                   Flutter UI Layer                     │
│   (Screens, Reusable Widgets, Forms, Material 3 Theme)  │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│             Provider State Management Layer            │
│   (AuthProvider, AppointmentProvider, ResourceProvider)│
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│                  Service / Logic Layer                 │
│  (AuthService, AppointmentService, ConsultationService)│
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               Centralized ApiClient Layer              │
│       (HTTP Transport, JSON Parsing, Error Mapping)     │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼ (REST API Calls)
┌────────────────────────────────────────────────────────┐
│            Express.js / Node.js Backend API            │
│      (Authentication, Resource Logic, FI/CO Ledgers)   │
└───────────────────────────┬────────────────────────────┘
                            │
                            ▼
┌────────────────────────────────────────────────────────┐
│               MongoDB Atlas Cloud Database             │
│   (Users, Appointments, Resources, Allocations, POs)   │
└────────────────────────────────────────────────────────┘
```

---

## ✨ Key Features & User Experiences

### 1. 🧑‍⚕️ Patient Experience
- **Personalized Home Dashboard**: Displays the next upcoming appointment, patient greetings, and instant action shortcuts.
- **5-Step Appointment Booking Flow**:
  1. Department / Specialty selection (Cardiology, Neurology, Orthopedics, General Medicine, Pediatrics).
  2. Doctor profile selection with maximum patient limits.
  3. Date picker with past date prevention.
  4. Live time-slot selection (`10:00 AM`, `11:00 AM`, `02:00 PM`, `03:00 PM`, `04:00 PM` — lunch break strictly excluded).
  5. Capacity badges (`Available`, `1/3 booked`, `2/3 booked`, `3/3 FULL`) with pre-flight availability check before final booking to prevent race conditions.
- **Appointments Management**: Status filter chips (`All`, `Scheduled`, `Completed`, `Cancelled`), appointment cancellation, and pull-to-refresh.
- **Digital Electronic Prescriptions**: Official clinical slip layout detailing diagnosis, medicines, dosage instructions, and allocated hospital resources.
- **Prescription Update Notification Badges**: Unread indicator dot automatically shown when a doctor revises a prescription.
- **Diagnostic Machine Booking**: Direct booking of **MRI**, **CT-Scan**, **X-Ray**, and **Ventilator** time slots.

### 2. 👨‍⚕️ Doctor Clinical Portal
- **Clinical Dashboard**: Real-time KPI counters for today's visits, pending queue, and completed consultations.
- **Doctor Schedule Screen**: Date picker filter, status filtering, and chronological appointment cards.
- **Comprehensive Consultation Screen**:
  - Clinical diagnosis and observation recording.
  - Medication prescription and dosage directions.
  - **Inpatient Bed Allocation**: Deducts 1 hospital bed and logs a \$500 admission ledger.
  - **Blood Bank Transfusion**: Deducts required blood units across 8 blood types (`A+`, `A-`, `B+`, `B-`, `O+`, `O-`, `AB+`, `AB-`), logs billing ledger, and triggers purchase order if stock drops below 10 units.
  - **Diagnostic Scan Prescription**: Prescribes MRI, CT-Scan, X-Ray, or Ventilator.
- **Prescription Revision**: Doctor can edit previous prescriptions without double-deducting physical resources, automatically notifying the patient.

### 3. 🛡️ Hospital Admin Dashboard
- **Hospital Bed Capacity**: Live tracking of available vs. total beds with health thresholds (`Critical <20%`, `Limited 20-50%`, `Healthy >50%`) and adjustment sheet.
- **Blood Bank Grid**: Real-time inventory across all 8 blood types with safety threshold indicators.
- **Equipment Inventory**: Diagnostic machinery status and active maintenance counts.
- **Appointments Audit & Force-Cancel**: Admin visibility across all hospital visits with emergency cancellation controls.
- **Doctor Roster**: Specialist directory categorized by medical departments.
- **Financial Ledger & Billing**: Tracking of consultation fees, bed admission charges, transfusion bills, and scan receipts.

---

## 🛠️ Technology Stack

| Technology | Purpose |
| :--- | :--- |
| **Flutter SDK (3.x)** | Native cross-platform mobile application framework |
| **Dart** | Modern, sound null-safe object-oriented language |
| **Provider (6.x)** | Reactive, explainable state management |
| **http** | High-performance asynchronous REST API communication |
| **shared_preferences** | Persistent key-value storage for local session & theme preference |
| **intl** | Standard date/time formatting and localization |
| **Node.js + Express.js** | Existing hospital backend REST API |
| **Mongoose & MongoDB Atlas** | Cloud database with ACID transactions and schema modeling |

---

## 🔐 REST API Architecture & Endpoints

The Flutter app communicates through a centralized `ApiClient` mapping to the backend endpoints:

| Method | Endpoint | Description |
| :--- | :--- | :--- |
| `POST` | `/api/login` | Secure email & password authentication returning user metadata |
| `POST` | `/api/guest-login` | Recruiter demo login for Patient, Doctor, or Admin roles |
| `POST` | `/api/users` | Registers a new patient account |
| `GET` | `/api/data` | OData-style aggregate data feed (users, appointments, resources, ledgers) |
| `POST` | `/api/appointments` | Records a new appointment after capacity validation |
| `PUT` | `/api/appointments/:id` | Updates appointment status, consultation findings, and resource deductions |
| `POST` | `/api/scans` | Schedules diagnostic machinery scan and creates financial ledger |
| `PUT` | `/api/resources` | Admin endpoint to calibrate total beds, blood, and equipment |

---

## ⚡ Mobile Performance & Engineering Decisions

1. **Pull-to-Refresh vs Web Polling**:
   - The original web project relied on a 10-second timer polling `/api/data`. On mobile, continuous background polling drains battery and wastes cellular data.
   - CareSync Mobile replaces periodic polling with on-demand **Pull-to-Refresh**, screen-focus revalidation, and post-mutation state updates.
2. **ListView.builder Virtualization**:
   - Used across appointment lists and rosters to instantiate widgets only when visible on screen, ensuring smooth 60/120 FPS scrolling even with hundreds of records.
3. **const Widget Constructors**:
   - Applied aggressively to immutable subtrees to eliminate redundant build phase reconciliations.
4. **Zero Raw Password Storage**:
   - Sensitive credentials and raw passwords are never saved in local storage. Local session caches only public user metadata.
5. **Centralized Error Hierarchy**:
   - `AppException`, `ApiException`, `NetworkException`, `AuthenticationException`, and `ValidationException` ensure raw server tracebacks are never exposed to the user.

---

## 🚀 Setup & Execution Instructions

### Prerequisites
- Flutter SDK installed and added to PATH (`flutter --version`)
- Android Studio / VS Code with Flutter extension
- Android Emulator or physical device

### 1. Clone & Navigate
```bash
cd "s:/se & pm/project/caresync_mobile"
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. API Configuration
By default, the app targets the production Render backend:
```dart
// lib/core/constants/api_constants.dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://hospital-appointment-and-resource.onrender.com/api',
);
```
To run against a local backend on an Android emulator:
```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

### 4. Run Tests
```bash
flutter test
```

### 5. Launch the Application
```bash
flutter run
```

---

## 🧪 Testing Suite

- **Unit Tests**:
  - `test/unit/appointment_model_test.dart`: Validates JSON serialization, null safety, and Prescription derivation.
  - `test/unit/resource_availability_test.dart`: Validates bed occupancy percentages, blood threshold alerts (<10 units), and time-slot rules (excluding lunch break).
- **Widget Tests**:
  - `test/widget/login_screen_test.dart`: Tests form layout, email/password validation, and demo chip buttons.
  - `test/widget/appointment_card_test.dart`: Validates doctor metadata, status badge coloring, and diagnosis snippets.
