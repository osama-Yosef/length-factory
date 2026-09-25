<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white"/>
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black"/>
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white"/>
<img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white"/>
<img src="https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white"/>

<br/>
<br/>

# 🏭 Length Factory

### نظام إدارة مصنع وطلبات متكامل

**Factory Management & Ordering System**

*A production-ready Flutter application with role-based access control, real-time Firestore sync, and full Arabic RTL support.*

<br/>

[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-blue?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange?logo=firebase)](https://firebase.google.com)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-green)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![License](https://img.shields.io/badge/License-MIT-purple)](LICENSE)

</div>

---

## 📋 Table of Contents

- [About The Project](#-about-the-project)
- [Features](#-features)
- [User Roles](#-user-roles)
- [Screenshots](#-screenshots)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Database Schema](#-database-schema)
- [Security Rules](#-security-rules)
- [Getting Started](#-getting-started)
- [Environment Setup](#-environment-setup)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)

---

## 🌟 About The Project

**Length Factory** is a comprehensive factory management system built with Flutter and Firebase. It provides a complete solution for managing products, orders, customers, and workers in a manufacturing environment.

The application supports **three distinct user roles**, each with a tailored interface and permissions:

- 🔴 **Admin** — Full control over products, orders, customers, and payments
- 🟢 **Customer** — Browse products, place orders, and track payment history
- 🟡 **Worker** — View production queue and mark orders as completed

> Built with **Clean Architecture**, **Cubit (flutter_bloc)**, **GetIt**, **Dio**, **Material 3** (light, high-contrast theme), and full **Arabic RTL** support.

---

## ✨ Features

### 🔐 Authentication & Security
- Firebase Authentication (Email/Password) + password reset
- Role-based routing (automatic redirect based on user role)
- Deactivated accounts are signed out immediately and cannot log in
- Firestore Security Rules enforcing data access at the database level
- Self-service Customer registration / Admin-created Worker & Admin accounts

### 👨‍💼 Admin Panel
- **Dashboard** — Live KPIs, today's / total sales, outstanding balances, 7-day sales bar chart, order-status pie chart, low-stock alerts, latest orders
- **Products** — Add / edit / hide / restore, image upload to Cloudinary (via Dio), stock filters (available · low · out · hidden)
- **Orders** — Search, status filter with counts, details page, status flow, payment status, delete, PDF invoice (print / share)
- **Cancel = full reversal** — Cancelling or deleting an order removes its amount from the customer's balance and restores stock (atomic transaction)
- **Customers** — Balance tracking, record payments, payment history, customer orders, activate / deactivate
- **Team** — Create Worker / Admin accounts without logging the admin out, activate / deactivate staff

### 🛍️ Customer Panel
- **Storefront** — Responsive product grid, live search, low-stock / out-of-stock badges
- **Product Details** — Live stock & price, quantity selector capped by available stock
- **Cart** — Quantity steppers, auto-synced with the live catalog (price / stock / hidden products)
- **Checkout** — Balance before / after, optional order note, atomic order placement
- **My Orders** — Status filter, details page, PDF invoice
- **Account** — Live balance, edit name / phone, payment history

### 👷 Worker Panel
- **Production Queue** — FIFO-sorted active orders (pending + preparing) with counters
- **No financial data** — Prices and balances are never shown to workers
- **Status Updates** — Start / finish with confirmation
- **Private Notes** — Notes visible only to Admin; printable work order (no prices)

---

## 👥 User Roles

| Capability | Admin | Customer | Worker |
|:-----------|:-----:|:--------:|:------:|
| Manage Products | ✅ | ❌ | ❌ |
| View Products | ✅ | ✅ | ✅ (name/qty only) |
| Place Orders | ❌ | ✅ | ❌ |
| View Orders | ✅ (all) | ✅ (own) | ✅ (active only) |
| View Prices / Balances | ✅ | ✅ (own) | ❌ **never** |
| Record Payments | ✅ | ❌ | ❌ |
| Change Order Status | ✅ | ❌ | ✅ (start / finish) |
| Cancel / Delete Orders | ✅ | ❌ | ❌ |
| Worker Notes | 👁 read | ❌ | ✅ write |
| Manage Customers & Staff | ✅ | ❌ | ❌ |

---

## 📱 Screenshots

> *Screenshots will be added after first production deployment.*

| Admin Dashboard | Products Management | Order Management |
|:-:|:-:|:-:|
| ![Dashboard](docs/screenshots/admin_dashboard.png) | ![Products](docs/screenshots/admin_products.png) | ![Orders](docs/screenshots/admin_orders.png) |

| Customer Storefront | Cart & Checkout | Worker Queue |
|:-:|:-:|:-:|
| ![Store](docs/screenshots/customer_store.png) | ![Cart](docs/screenshots/customer_cart.png) | ![Worker](docs/screenshots/worker_queue.png) |

---

## 🛠 Tech Stack

| Category | Technology |
|:---------|:-----------|
| **Framework** | Flutter 3.x (Stable) · Dart 3.x |
| **Architecture** | Clean Architecture (feature-first: data / domain / presentation) |
| **State Management** | Cubit — `flutter_bloc` |
| **Dependency Injection** | `get_it` (service locator) |
| **Error Handling** | `dartz` — `Either<Failure, T>` from every use case |
| **Networking** | `dio` (Cloudinary REST image upload, interceptors, error mapping) |
| **Backend** | Firebase Authentication · Cloud Firestore |
| **Navigation** | `go_router` (role-based redirect, refreshed by `AuthCubit`) |
| **UI** | Material 3 light theme + Google Fonts (Cairo), RTL |
| **Charts** | `fl_chart` |
| **Invoices** | `pdf` + `printing` |
| **Testing** | `flutter_test`, `bloc_test`, `mocktail`, `fake_cloud_firestore` |

---

## 🏗 Architecture

Each feature is split into three layers. Dependencies only point inwards:
**Presentation → Domain ← Data**.

```
┌──────────────────────────── PRESENTATION ────────────────────────────┐
│  Screens / Widgets  ──►  Cubits (state)                              │
│  e.g. OrdersCubit, CheckoutCubit, CartCubit, AuthCubit               │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │ calls
┌──────────────────────────────── DOMAIN ─────────────────────────────┐
│  Use cases  (PlaceOrderUseCase, RecordPaymentUseCase, ...)           │
│  Entities   (UserEntity, ProductEntity, OrderEntity, ...)            │
│  Repository contracts (abstract)        — pure Dart, no Firebase     │
└──────────────────────────────────▲───────────────────────────────────┘
                                   │ implements
┌───────────────────────────────── DATA ──────────────────────────────┐
│  Repository implementations  (exceptions ➜ Either<Failure, T>)       │
│  Remote data sources (Firestore transactions, FirebaseAuth)          │
│  Models (toMap / fromMap) · Services (Dio Cloudinary, PDF invoice)   │
└──────────────────────────────────────────────────────────────────────┘
                 Wiring: GetIt  (lib/core/di/injection.dart)
```

### Key Architecture Decisions

- **Domain layer has no Firebase dependencies** — business rules (status flow, validation, dashboard math) are unit-tested without emulators
- **Atomic transactions** for checkout, payments, cancellation and deletion — balance and stock can never drift
- **Real-time everywhere** — Cubits subscribe to Firestore streams; the customer's balance updates live after checkout / payment
- **Role-based routing** via `go_router` redirect driven by `AuthCubit` — users can never reach another role's screens
- **Soft deletes** for products — historical orders remain accurate
- **Screen-scoped Cubits** are GetIt factories (closed automatically by `BlocProvider`); `AuthCubit` and `CartCubit` are app-wide singletons

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/     # Collections, roles, statuses, Cloudinary config
│   ├── cubit/         # SubmissionState, LoadStatus, SafeEmit mixin
│   ├── di/            # GetIt registrations
│   ├── errors/        # Exceptions, Failures, exception → failure mapper
│   ├── network/       # Dio client + error mapping
│   ├── routing/       # AppRouter (go_router) + role redirects
│   ├── services/      # ImageUploadService (Cloudinary via Dio)
│   ├── theme/         # AppColors, AppTheme (light, high contrast)
│   ├── usecase/       # UseCase / StreamUseCase base classes
│   ├── utils/         # Formatting, validators, stream helpers, UI helpers
│   └── widgets/       # Shared widgets (buttons, badges, empty/error views...)
│
├── features/
│   ├── auth/          # Session (AuthCubit), login / register / splash
│   ├── products/      # Catalog, admin product management, storefront
│   ├── cart/          # CartCubit + cart screen
│   ├── orders/        # Checkout, order lists, details, worker queue, PDF invoice
│   ├── accounts/      # Customers, payments, staff, customer profile
│   ├── dashboard/     # DashboardStats + charts
│   └── shell/         # Admin / Customer / Worker shells (bottom navigation)
│
│   (each feature)
│   ├── data/          # datasources · models · repositories (impl)
│   ├── domain/        # entities · repositories (contracts) · usecases
│   └── presentation/  # cubit · screens · widgets
│
├── app.dart           # MaterialApp.router + global providers
├── firebase_options.dart
└── main.dart          # Firebase init + GetIt init
```

---

## 🗄 Database Schema

### `users/{uid}`
```json
{
  "name": "string",
  "phone": "string",
  "email": "string",
  "role": "admin | customer | worker",
  "balance": 0.0,
  "createdAt": "timestamp",
  "isActive": true
}
```

### `products/{id}`
```json
{
  "name": "string",
  "nameLower": "string",
  "image": "string (Storage URL)",
  "price": 0.0,
  "description": "string",
  "quantity": 0,
  "createdAt": "timestamp",
  "isActive": true
}
```

### `orders/{id}`
```json
{
  "orderNumber": "string",
  "customerId": "string (uid ref)",
  "customerName": "string (snapshot)",
  "phone": "string (snapshot)",
  "items": [
    {
      "productId": "string",
      "productName": "string (snapshot)",
      "productImage": "string (snapshot)",
      "unitPrice": 0.0,
      "quantity": 0
    }
  ],
  "totalPrice": 0.0,
  "status": "pending | preparing | completed | cancelled",
  "paymentStatus": "unpaid | partially_paid | paid",
  "workerNote": "string (Admin-visible only)",
  "createdAt": "timestamp",
  "completedAt": "timestamp | null"
}
```

### `payments/{id}`
```json
{
  "customerId": "string (uid ref)",
  "amount": 0.0,
  "date": "timestamp",
  "adminId": "string",
  "adminName": "string",
  "notes": "string | null"
}
```

> **Note:** Order items store a **snapshot** of product data at order time. This ensures historical accuracy even if the product is later edited or deleted.

---

## 🔒 Security Rules

Security is enforced at **two levels**:

1. **UI level** — Workers never see price/balance widgets
2. **Database level** — Firestore rules enforce access regardless of UI

| Rule | Description |
|:-----|:------------|
| Customer can only `create` orders for themselves | `customerId == request.auth.uid` |
| Customer cannot change their `role` | `request.resource.data.role == resource.data.role` |
| Worker can only update `status`, `completedAt`, `workerNote` | `affectedKeys().hasOnly([...])` |
| Worker cannot read `payments` collection | No rule granted |
| Customer can only decrement product `quantity` | `quantity < resource.data.quantity && quantity >= 0` |

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.24.0`
- Dart SDK `>=3.3.0`
- Android Studio / VS Code
- Firebase project (Blaze plan recommended)
- Node.js + Firebase CLI

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/osama-Yosef/length_factory.git
cd length_factory

# 2. Install dependencies
flutter pub get

# 3. Connect Firebase (generates lib/firebase_options.dart)
dart pub global activate flutterfire_cli
flutterfire configure

# 4. Deploy Firestore rules & indexes
firebase deploy --only firestore:rules,firestore:indexes

# 5. Run the app
flutter run
```

---

## ⚙️ Environment Setup

### Firebase Services Required

Enable the following in your Firebase Console:

| Service | Purpose |
|:--------|:--------|
| **Authentication** | Email/Password sign-in |
| **Cloud Firestore** | Real-time database |

Product images are uploaded to **Cloudinary** (free tier) through its REST API using Dio:
create an **unsigned** upload preset named `length_factory`, then set your cloud name in
`CloudinaryConfig.cloudName` (`lib/core/constants/app_constants.dart`).

Deploy the security rules and indexes after pulling:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### Creating the First Admin Account

Self-registration only creates **Customer** accounts (by design).
To create your first Admin:

1. Register via the app (creates a Customer document)
2. Open Firebase Console → Firestore → `users/{uid}`
3. Change `role` field from `"customer"` to `"admin"`
4. Log out and log back in — you'll be routed to the Admin Panel

### Windows Desktop Build

```powershell
# Required environment variable for Firebase C++ SDK compatibility
$env:CMAKE_POLICY_VERSION_MINIMUM="3.5"
flutter run -d windows
```

---

## 🗺 Roadmap

- [x] **Phase 1** — Foundation (Clean Architecture, Firebase setup, Auth flow, Role routing)
- [x] **Phase 2** — Admin Panel (Dashboard, Products CRUD, Orders, Customers/Payments)
- [x] **Phase 3** — Customer Panel (Storefront, Cart, Checkout, Orders, Profile)
- [x] **Phase 4** — Worker Panel (Production Queue, Status Updates, Notes)
- [x] **Phase 5** — Refactor to Cubit + GetIt + Dio, light high-contrast theme
- [x] **Phase 6** — Staff management, order cancellation with reversal, dashboard charts, PDF invoices
- [ ] **Phase 7** — Push Notifications (FCM for Android)
- [ ] **Phase 8** — Excel customer reports, QR code per order
- [ ] **Phase 9** — Cloud Functions (server-side transaction validation)

---

## 👨‍💻 Author

**Osama Yosef**

[![GitHub](https://img.shields.io/badge/GitHub-osama--Yosef-181717?style=flat&logo=github)](https://github.com/osama-Yosef)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Osama%20Yosef-0A66C2?style=flat&logo=linkedin)](https://linkedin.com/in/osama-yosef-819268319)
[![Upwork](https://img.shields.io/badge/Upwork-Osama%20Yosef-6FDA44?style=flat&logo=upwork)](https://upwork.com/freelancers/~014ebd205ef38ca04c)

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

<div align="center">

**Built with ❤️ using Flutter & Firebase**

*Length Factory — Professional Factory Management System*

</div>
