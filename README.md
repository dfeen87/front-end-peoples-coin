# BrightActs Front-End

**Cross-Platform Flutter Interface for the BrightActs Ecosystem**

> IMPORTANT NOTE: NOT AFFILIATED WITH ANY CRYPTO COINS. This project does not mind coins that are sold.

**Version:** 1.0.1 
**Language:** Dart / Flutter  
**License:** MIT

## Overview

BrightActs is a bio-inspired, blockchain-backed digital ecosystem designed to securely capture, process, and visualize Goodwill Actions across a global network. This repository contains the Flutter/Dart front-end, providing a modern, responsive, cross-platform interface that allows users to:

* Interact with the BrightActs network
* Track personal and global impact
* Participate in governance and decision-making
* Visualize data through real-time dashboards

The UI features a dynamic nebula background with persistent, transparent data windows, delivering an immersive experience while preserving clarity, readability, and data focus.

## Key Features

### 🌐 Real-Time Dashboards
* Live tracking of Goodwill Actions, tokenized balances, and impact scores
* Instant updates via synchronized back-end data streams

### 🤝 User Interaction & Rewards
* Secure submission and tracking of Goodwill Actions
* Auditable transaction pipelines aligned with back-end validation logic

### 🏛 Governance & Voting
* View active proposals and council decisions
* Cast votes and monitor outcomes directly from the front-end

### 📊 Portfolio & Analytics
* Historical performance views and scoring analytics
* Interactive charts powered by cognitive back-end modules

### 🔐 Secure Authentication
* Firebase-backed authentication for secure, auditable access
* Supports scalable identity management

### 📱 Cross-Platform Support
* Single codebase targeting Android, iOS, and Web using Flutter

## Architecture Highlights

* **Modular Flutter Design** - Each major view (Portfolio, Ledger, Governance) is encapsulated into reusable, maintainable components.
* **Real-Time Back-End Synchronization** - Integrates with Python back-end services via REST and/or WebSockets to ensure live updates and audit logging.
* **Data Validation & Integrity** - All user inputs are validated locally and server-side before submission to maintain correctness and trust.
* **Immersive Visual Layer** - A persistent nebula background enhances user experience without interfering with foreground data visibility.

## Getting Started

### Prerequisites

* Flutter SDK ≥ 3.10.0
* Dart SDK ≥ 3.2.0
* Node.js / npm (optional, for build tooling)
* Firebase project configuration (optional, for authentication & analytics)

### Installation & Run

```bash
git clone https://github.com/dfeen87/front-end-peoples-coin.git
cd BrightActs-Frontend
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart        # Application entry point
├── screens/         # UI screens (Portfolio, Governance, Ledger)
├── widgets/         # Reusable UI components
├── models/          # Dart models mirroring back-end schemas
├── services/        # API clients & Firebase integration
├── utils/           # Helpers, constants, formatting utilities
└── state/           # State management (Provider / Bloc)
```

## Contributing

We welcome developers, designers, and blockchain enthusiasts to help evolve and scale BrightActs.

### Workflow

1. Fork the repository
2. Create a feature branch
   ```bash
   git checkout -b feature/your-feature
   ```
3. Commit your changes
   ```bash
   git commit -am "Add your feature"
   ```
4. Push to your branch
   ```bash
   git push origin feature/your-feature
   ```
5. Open a Pull Request

All contributions are reviewed with a focus on clarity, maintainability, and alignment with system architecture.

## License

This project is released under the MIT License. See the `LICENSE` file for full terms.

## About

BrightActs Front-End is a cross-platform Flutter application that enables users to securely submit, track, and visualize Goodwill Actions in real time. It integrates seamlessly with the BrightActs back-end to provide governance participation, analytics, and interactive dashboards while maintaining strong data integrity and secure authentication.
