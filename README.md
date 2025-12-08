BrightActs Front-End (Dart/Flutter)

Version: 1.0.0 | Language: Dart / Flutter | License: MIT

Overview

BrightActs is a bio-inspired, blockchain-backed digital ecosystem designed to securely capture, process, and display Goodwill Actions across a global network. The Flutter/Dart front-end provides a modern, cross-platform interface for users to interact with the BrightActs system, view their impact, and participate in governance.

Featuring a dynamic nebula background with persistent, clear transparent windows, the interface offers an immersive, visually engaging experience while keeping all user data and dashboards clear and readable.

Key Features

Real-Time Dashboards – Track Goodwill Actions, tokenized balances, and impact scores with instantaneous updates.

User Interaction & Rewards – Submit, track, and visualize Goodwill Actions via secure, auditable transaction pipelines.

Governance & Voting – Seamlessly view proposals, cast votes, and monitor council decisions directly from the front-end.

Portfolio & Analytics – Historical performance, scoring analytics, and interactive charts powered by back-end cognitive modules.

Secure Authentication – Firebase-backed login ensures secure, auditable access for all users.

Cross-Platform – Fully compatible with Android, iOS, and web builds via Flutter.

Architecture Highlights

Modular Flutter Components – Each view (Portfolio, Ledger, Governance) is encapsulated for easy extension and maintainability.

Real-Time Back-End Sync – Connects to Python back-end APIs via REST or WebSockets to ensure live data and audit logging.

Data Validation & Integrity – All user interactions are rigorously validated before submission to guarantee accuracy and auditability.

Dynamic Nebula Background – Persistent visual effect enhances UI immersion without interfering with clarity of data windows.

Getting Started

Prerequisites:

Flutter SDK >= 3.10.0

Dart SDK >= 3.2.0

Node/npm (optional for build tooling)

Firebase project configuration (optional for auth + analytics)

Installation & Run:

git clone https://github.com/dfeen87/front-end-peoples-coin.git
cd BrightActs-Frontend
flutter pub get
flutter run

Folder Structure
lib/
├─ main.dart           # Entry point
├─ screens/            # UI screens: Portfolio, Governance, Ledger
├─ widgets/            # Reusable UI components
├─ models/             # Dart classes mirroring back-end schemas
├─ services/           # API & Firebase integration
├─ utils/              # Helpers, constants, formatting
└─ state/              # State management (Provider/Bloc)

Contributing

We welcome developers, designers, and blockchain enthusiasts to contribute, extend, and help scale BrightActs globally.

Workflow:

Fork the repo

Create a feature branch: git checkout -b feature/your-feature

Commit your changes: git commit -am 'Add feature'

Push to the branch: git push origin feature/your-feature

Open a Pull Request

License

MIT License – See LICENSE for details.
