# AST Smart Asset Management - Flutter Mobile Application

[![Flutter 3.x](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Material 3](https://img.shields.io/badge/UI-Material%203-teal)](https://m3.material.io/)
[![Project 3](https://img.shields.io/badge/BUA-DevHub%20Field%20Phase-navy)](https://github.com/AST-Smart-Asset)

Production-grade cross-platform mobile client for **Project 3: Smart Asset Inventory & Predictive Maintenance (AST)** at Badr University in Assiut (BUA DevHub Field Phase, Squad 3).

---

## 📱 Features & Implemented Requirements

- **AST-FR-01: Secure Authentication & Role-Based Access Control**
  - JWT session management with token persistence.
  - Quick-login presets for all system roles (`facility_manager`, `technician`, `auditor`, `department_head`, `admin`).
  - Dynamic API Base URL configuration dialog (easy switching between localhost, LAN IP, or production cloud).
- **AST-FR-02: Operational Executive Dashboard**
  - Real-time KPI summaries: Total Asset Count, In-Service Assets, Active Work Orders, Open Reconciliation Discrepancies, and Critical AI Risk Alerts.
  - Risk distribution indicators with visual status counters.
- **AST-FR-03: Comprehensive Asset Registry & Search**
  - Instant live search by asset tag, name, serial number, and category.
  - Multi-criteria filtering by asset condition (`good`, `fair`, `critical`), operational status, and AI failure risk band.
  - Detailed asset inspection view with QR tag, technical specs, warranty dates, location, and maintenance history.
- **AST-FR-04: Digital Custody & Location Transfer**
  - Formal multi-step custody transfer workflow.
  - Destination room/facility selection with reason documentation and approval notes.
  - Instant audit trail integration with backend event logging.
- **AST-FR-06: Preventive Maintenance & Work Orders**
  - Active and historical work orders grouped by priority (`critical`, `high`, `medium`, `low`).
  - Maintenance closure modal with outcome recording (`repaired`, `passed`, `replaced_parts`, `unresolvable`), downtime tracking, cost, and notes.
  - Automatic next due date recalculation upon completion.
- **AST-FR-07: QR Code Asset Audits & Physical Stocktake**
  - Camera-enabled and manual tag entry scanner for physical verification.
  - Instant discrepancy detection (location mismatch, unknown tags).
- **AST-FR-09: On-Demand Predictive AI Risk Evaluation**
  - One-tap button on asset detail screen to invoke the Python AI microservice via the backend gateway.
  - Displays failure probability %, predicted failure window (lead time), contributing sensor factors, and recommended preventive actions.

---

## 🏗️ Architecture & Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart        # API URLs, timeout, and environment settings
│   ├── network/
│   │   └── api_client.dart        # Unified HTTP client, JWT injection & error handling
│   └── theme/
│       └── app_theme.dart         # Material 3 Navy & Teal design system
├── data/
│   └── models/
│       ├── asset_model.dart       # Asset entity & risk bands
│       ├── dashboard_kpi_model.dart # Executive metrics model
│       ├── stocktake_model.dart   # Physical audit sessions
│       ├── user_model.dart        # Authentication & RBAC profiles
│       └── work_order_model.dart  # Maintenance work order entities
├── presentation/
│   └── screens/
│       ├── asset_detail_screen.dart # Detailed asset view & AI evaluation trigger
│       ├── asset_list_screen.dart   # Filterable & searchable asset registry
│       ├── custody_transfer_screen.dart # Room/custody handoff form
│       ├── dashboard_screen.dart    # Operational overview with KPI cards
│       ├── login_screen.dart        # Auth screen with server settings
│       ├── qr_scanner_screen.dart   # QR inspection and rapid tag lookup
│       └── work_orders_screen.dart  # Preventive maintenance management
└── main.dart                        # Application entrypoint & declarative routing
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.24+ (Dart 3.5+)
- Android Studio / Xcode or Chrome for web preview
- Running [AST Backend API](https://github.com/AST-Smart-Asset/Backend) (default: `http://localhost:4000/api/v1`)

### Installation & Run

1. Clone repository:
   ```bash
   git clone https://github.com/AST-Smart-Asset/Flutter.git
   cd Flutter
   ```

2. Fetch packages:
   ```bash
   flutter pub get
   ```

3. Run static analyzer and tests:
   ```bash
   flutter analyze
   flutter test
   ```

4. Launch the app:
   ```bash
   # On connected Android device / emulator
   flutter run

   # Or on Windows desktop
   flutter run -d windows

   # Or on Chrome
   flutter run -d chrome
   ```

5. Server Connection:
   - On the login screen, tap **"Server Settings"** in the top right corner to set the API Base URL to your backend instance:
     - For Android Emulator: `http://10.0.2.2:4000/api/v1`
     - For Localhost/Desktop: `http://localhost:4000/api/v1`
     - For LAN Device: `http://<YOUR_LAN_IP>:4000/api/v1`