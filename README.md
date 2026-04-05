# BrightActs Front-End

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.10.0+-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.2.0+-0175C2?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-lightgrey)

**Cross-Platform Flutter Interface for the BrightActs Ecosystem**

> IMPORTANT NOTE: NOT AFFILIATED WITH ANY CRYPTO COINS. This project does not mine, mint, or sell coins.

[Features](#key-features) •
[Getting Started](#getting-started) •
[Documentation](#documentation) •
[Contributing](#contributing) •
[License](#license)

</div>

---

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Architecture Highlights](#architecture-highlights)
- [Technology Stack](#technology-stack)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
  - [Environment Configuration](#environment-configuration)
  - [Running the Application](#running-the-application)
- [Project Structure](#project-structure)
- [Development](#development)
  - [Testing](#testing)
  - [Linting](#linting)
  - [Building](#building)
- [Deployment](#deployment)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [Roadmap](#roadmap)
- [License](#license)
- [Contact & Support](#contact--support)

---

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
* Real-time data visualization with interactive charts

### 🤝 User Interaction & Rewards
* Secure submission and tracking of Goodwill Actions
* Auditable transaction pipelines aligned with back-end validation logic
* Token-based reward system for positive actions

### 🏛 Governance & Voting
* View active proposals and council decisions
* Cast votes and monitor outcomes directly from the front-end
* Transparent governance process with full audit trail

### 📊 Portfolio & Analytics
* Historical performance views and scoring analytics
* Interactive charts powered by cognitive back-end modules
* Personal impact tracking and global statistics

### 🔐 Secure Authentication
* Firebase-backed authentication for secure, auditable access
* Supports scalable identity management
* Local biometric authentication support
* Secure storage for sensitive data

### 💼 Wallet Management
* Integrated Web3 wallet functionality
* Secure transaction management
* QR code generation for easy sharing

### 📱 Cross-Platform Support
* Single codebase targeting Android, iOS, and Web using Flutter
* Responsive design adapting to different screen sizes
* Native performance on all platforms

## Architecture Highlights

* **Modular Flutter Design** - Each major view (Portfolio, Ledger, Governance) is encapsulated into reusable, maintainable components.
* **Real-Time Back-End Synchronization** - Integrates with Python back-end services via REST and/or WebSockets to ensure live updates and audit logging.
* **Data Validation & Integrity** - All user inputs are validated locally and server-side before submission to maintain correctness and trust.
* **Immersive Visual Layer** - A persistent nebula background enhances user experience without interfering with foreground data visibility.
* **State Management** - Uses Riverpod and Provider for efficient state management across the application.
* **Secure Data Storage** - Implements Flutter Secure Storage for sensitive information like credentials and keys.
* **Web3 Integration** - Built-in support for blockchain interactions via web3dart library.

---

## Technology Stack

### Core Framework
- **Flutter** (≥3.10.0) - Cross-platform UI framework
- **Dart** (≥3.2.0) - Programming language

### State Management
- **flutter_riverpod** (^2.4.10) - Modern state management
- **provider** (^6.1.1) - Additional state management
- **flutter_bloc** (^8.1.3) - BLoC pattern implementation

### Backend & APIs
- **Firebase Core** (^2.31.1) - Firebase integration
- **Firebase Auth** (^4.19.6) - Authentication services
- **Cloud Firestore** (^4.17.4) - Cloud database
- **http** (^1.1.2) - HTTP client
- **dio** (^5.4.3+1) - Advanced HTTP client

### Blockchain & Web3
- **web3dart** (^2.7.3) - Ethereum blockchain interaction

### Security
- **local_auth** (^2.1.8) - Biometric authentication
- **flutter_secure_storage** (^9.0.0) - Secure data storage
- **cryptography** (^2.5.0) - Cryptographic operations
- **encrypt** (^5.0.3) - Encryption library

### UI Components
- **go_router** (^12.1.3) - Declarative routing
- **flutter_svg** (^2.0.10+1) - SVG rendering
- **cached_network_image** (^3.2.3) - Image caching
- **shimmer** (^3.0.0) - Loading animations
- **lottie** (^3.1.0) - JSON-based animations
- **confetti** (^0.7.0) - Celebration effects

### Utilities
- **uuid** (^4.4.0) - UUID generation
- **intl** (^0.18.1) - Internationalization
- **logger** (^2.3.0) - Logging framework
- **flutter_dotenv** (^5.1.0) - Environment configuration

---

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

* **Flutter SDK** ≥ 3.10.0
  ```bash
  flutter --version
  ```
* **Dart SDK** ≥ 3.2.0 (included with Flutter)
* **Git** - For cloning the repository
* **IDE** - Recommended: VS Code or Android Studio with Flutter plugins
* **Platform-Specific Requirements:**
  - **Android**: Android Studio, Android SDK
  - **iOS**: Xcode (macOS only), CocoaPods
  - **Web**: Chrome browser for debugging
* **Firebase Account** (optional, for authentication & analytics)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/dfeen87/front-end-peoples-coin.git
   cd front-end-peoples-coin
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Verify installation**
   ```bash
   flutter doctor
   ```
   This command checks your environment and displays a report of the status of your Flutter installation.

### Environment Configuration

The application uses environment variables for configuration. Create and configure your `config.env` file:

1. **Copy the template** (if not already present)
   ```bash
   cp config.env.example config.env  # If example exists
   ```

2. **Configure environment variables** in `config.env`:
   ```env
   # API Configuration
   API_BASE_URL=https://your-backend-api.com
   
   # Firebase Configuration
   FIREBASE_API_KEY=your_firebase_api_key
   FIREBASE_APP_ID=your_firebase_app_id
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_PROJECT_ID=your_project_id
   ```

2. **Firebase Setup** (if using Firebase)
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Download configuration files:
     - `google-services.json` for Android → place in `android/app/`
     - `GoogleService-Info.plist` for iOS → place in `ios/Runner/`
   - Run Firebase configuration:
     ```bash
     dart pub global activate flutterfire_cli
     flutterfire configure
     ```

### Running the Application

#### Development Mode

Run on your preferred platform:

```bash
# Run on connected device (auto-detect)
flutter run

# Run on specific platform
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS (macOS only)
flutter run -d macos       # macOS desktop
flutter run -d windows     # Windows desktop
flutter run -d linux       # Linux desktop

# Run with hot reload enabled (default in debug mode)
flutter run --hot
```

#### Production Mode

Build optimized release versions:

```bash
# Android APK
flutter build apk --release

# Android App Bundle (recommended for Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release

# Desktop platforms
flutter build macos --release
flutter build windows --release
flutter build linux --release
```

#### Quick Start Commands

```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Check for issues
flutter doctor -v
```

## Project Structure

```
front-end-peoples-coin/
├── android/              # Android platform-specific code
├── ios/                  # iOS platform-specific code
├── web/                  # Web platform-specific code
├── windows/              # Windows platform-specific code
├── linux/                # Linux platform-specific code
├── macos/                # macOS platform-specific code
├── lib/
│   ├── main.dart                    # Application entry point
│   ├── config/                      # Configuration files
│   │   └── api_config.dart          # API endpoints configuration
│   ├── api/                         # API clients and services
│   ├── models/                      # Data models
│   │   ├── user.dart                # User model
│   │   ├── proposal.dart            # Governance proposal model
│   │   ├── goodwill_action.dart     # Goodwill action model
│   │   ├── wallet_models.dart       # Wallet-related models
│   │   └── tech_system.dart         # System configuration model
│   ├── pages/                       # Main application pages
│   │   ├── my_portfolio_page.dart   # User portfolio view
│   │   ├── my_wallet_page.dart      # Wallet management
│   │   ├── governance_page.dart     # Governance & voting
│   │   ├── public_ledger_page.dart  # Public transaction ledger
│   │   ├── submit_goodwill_page.dart # Submit goodwill actions
│   │   └── create_proposal_page.dart # Create governance proposals
│   ├── screens/                     # Authentication & utility screens
│   │   ├── welcome_screen.dart      # Welcome/landing screen
│   │   ├── sign_in_screen.dart      # User sign-in
│   │   ├── sign_up_screen.dart      # User registration
│   │   └── code_display_page.dart   # Code viewer utility
│   ├── widgets/                     # Reusable UI components
│   │   ├── dynamic_nebula_background.dart # Animated background
│   │   └── navigation_card.dart     # Navigation components
│   ├── state/                       # State management (Riverpod/Provider)
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── user_provider.dart       # User data state
│   │   ├── wallet_provider.dart     # Wallet state
│   │   ├── proposal_provider.dart   # Governance proposals state
│   │   ├── ledger_provider.dart     # Ledger data state
│   │   ├── goodwill_processing_provider.dart # Goodwill actions state
│   │   └── nebula_state.dart        # UI nebula background state
│   ├── service/                     # Business logic services
│   │   ├── api_client.dart          # HTTP client wrapper
│   │   ├── api_service.dart         # Core API service
│   │   ├── wallet_service.dart      # Wallet operations
│   │   ├── wallet_manager.dart      # Wallet management
│   │   ├── account_service.dart     # Account management
│   │   ├── user_account_service.dart # User account operations
│   │   ├── proposal_service.dart    # Proposal CRUD operations
│   │   ├── vote_service.dart        # Voting operations
│   │   ├── goodwill_action_service.dart # Goodwill action submission
│   │   ├── loves_ledger_service.dart # Ledger service
│   │   ├── backend_status_service.dart # Backend health checks
│   │   └── recaptcha_service.dart   # reCAPTCHA verification
│   ├── utils/                       # Utility functions
│   └── firebase_options.dart        # Firebase configuration
├── test/                 # Unit and widget tests
├── integration_test/     # Integration tests
├── assets/               # Static assets (images, fonts, etc.)
├── docs/                 # Additional documentation
│   └── analysis/         # Code analysis reports
├── firebase/             # Firebase configuration files
├── infra/                # Infrastructure configuration
├── tools/                # Build and deployment tools
├── config.env            # Environment variables (not committed)
├── pubspec.yaml          # Project dependencies and metadata
├── analysis_options.yaml # Dart analyzer configuration
├── firebase.json         # Firebase hosting configuration
└── README.md             # This file
```

### Key Directories Explained

- **`lib/pages/`** - Complete application screens with full UI layouts
- **`lib/screens/`** - Smaller, focused screens (auth, utilities)
- **`lib/widgets/`** - Reusable components used across multiple pages
- **`lib/state/`** - State management using Riverpod providers
- **`lib/service/`** - Business logic separated from UI
- **`lib/models/`** - Data transfer objects and domain models
- **`test/`** - Unit tests for models, services, and widgets

---

## Development

### Testing

#### Run Unit Tests
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/models/user_test.dart

# Run tests in verbose mode
flutter test --verbose
```

#### Run Integration Tests
```bash
# Run integration tests on connected device
flutter test integration_test

# Run on specific device
flutter test integration_test -d chrome
```

#### Generate Coverage Report
```bash
# Generate coverage
flutter test --coverage

# View coverage HTML (requires genhtml from lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

### Linting

The project follows strict Dart linting rules defined in `analysis_options.yaml`.

```bash
# Analyze the entire project
flutter analyze

# Fix auto-fixable issues
dart fix --apply

# Format code
dart format lib/ test/

# Format and verify
dart format --set-exit-if-changed lib/ test/
```

### Building

#### Debug Builds
```bash
# Android Debug APK
flutter build apk --debug

# iOS Debug (requires macOS)
flutter build ios --debug
```

#### Release Builds
```bash
# Android Release APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS Release (requires macOS)
flutter build ios --release

# Web Release
flutter build web --release --web-renderer html

# Desktop Releases
flutter build windows --release
flutter build macos --release
flutter build linux --release
```

#### Build Optimization
```bash
# Build with tree shaking
flutter build apk --release --tree-shake-icons

# Build with obfuscation (recommended for production)
flutter build apk --release --obfuscate --split-debug-info=./debug-info

# Analyze app size
flutter build apk --analyze-size
```

---

## Deployment

### Web Deployment

#### Firebase Hosting
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase (if not already done)
firebase init hosting

# Build and deploy
flutter build web --release
firebase deploy --only hosting
```

#### Custom Server
```bash
# Build web app
flutter build web --release

# Deploy the build/web directory to your web server
# The built files will be in: build/web/
```

### Mobile App Deployment

#### Android (Google Play Store)
1. Build release app bundle:
   ```bash
   flutter build appbundle --release
   ```
2. The `.aab` file will be at: `build/app/outputs/bundle/release/app-release.aab`
3. Upload to Google Play Console

#### iOS (Apple App Store)
1. Build release app:
   ```bash
   flutter build ios --release
   ```
2. Open `ios/Runner.xcworkspace` in Xcode
3. Archive and submit to App Store Connect

### Desktop Deployment

Platform-specific installers can be created using the built applications in:
- Windows: `build/windows/runner/Release/`
- macOS: `build/macos/Build/Products/Release/`
- Linux: `build/linux/release/bundle/`

---

## API Documentation

The application communicates with the BrightActs backend API. Key endpoints include:

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/logout` - User logout

### User Management
- `GET /api/user/profile` - Get user profile
- `PUT /api/user/profile` - Update user profile
- `GET /api/user/account` - Get account details

### Goodwill Actions
- `POST /api/goodwill/submit` - Submit goodwill action
- `GET /api/goodwill/history` - Get user's goodwill history

### Governance
- `GET /api/proposals` - List all proposals
- `POST /api/proposals` - Create new proposal
- `POST /api/vote` - Cast vote on proposal

### Wallet
- `GET /api/wallet/balance` - Get wallet balance
- `GET /api/wallet/transactions` - Get transaction history

### Ledger
- `GET /api/ledger/public` - Get public ledger entries

> **Note**: Actual API endpoints and parameters may vary. Refer to the backend API documentation for complete details.

---

## Troubleshooting

### Common Issues

#### Flutter Doctor Issues
```bash
# Check Flutter installation
flutter doctor -v

# Upgrade Flutter
flutter upgrade

# Clean and rebuild
flutter clean
flutter pub get
```

#### Build Failures
```bash
# Clean build cache
flutter clean

# Remove pub cache and reinstall
rm -rf ~/.pub-cache
flutter pub get

# For Android: Clean Gradle cache
cd android && ./gradlew clean && cd ..

# For iOS: Clean build and pods
cd ios && rm -rf Pods Podfile.lock && pod install && cd ..
```

#### Firebase Issues
```bash
# Reconfigure Firebase
flutterfire configure

# Verify Firebase configuration
cat lib/firebase_options.dart
cat android/app/google-services.json  # Android
cat ios/Runner/GoogleService-Info.plist  # iOS
```

#### Environment Configuration
- Ensure `config.env` exists and contains all required variables
- Check that `config.env` is loaded in `main.dart`
- Verify API URLs are accessible from your network

#### Hot Reload Not Working
```bash
# Restart with hot reload
r  # Press 'r' in terminal

# Full restart
R  # Press 'R' in terminal

# Or restart the app completely
flutter run
```

### Platform-Specific Issues

#### Android
- **Gradle sync fails**: Update Gradle version in `android/build.gradle`
- **SDK not found**: Set `ANDROID_HOME` environment variable
- **Signing issues**: Check `android/key.properties` configuration

#### iOS
- **CocoaPods errors**: Run `pod repo update` then `pod install`
- **Code signing**: Configure signing in Xcode
- **Simulator not found**: Open Xcode → Preferences → Components

#### Web
- **CORS issues**: Configure backend to allow cross-origin requests
- **Routing issues**: Use hash routing for static hosting
- **Performance**: Use `--web-renderer canvaskit` for better graphics

---

## Contributing

We welcome developers, designers, and blockchain enthusiasts to help evolve and scale BrightActs!

### How to Contribute

1. **Fork the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/front-end-peoples-coin.git
   cd front-end-peoples-coin
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clean, documented code
   - Follow the existing code style
   - Add tests for new features
   - Update documentation as needed

4. **Test your changes**
   ```bash
   # Run tests
   flutter test
   
   # Run linter
   flutter analyze
   
   # Format code
   dart format lib/ test/
   ```

5. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```
   
   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation changes
   - `style:` - Code style changes (formatting, etc.)
   - `refactor:` - Code refactoring
   - `test:` - Adding or updating tests
   - `chore:` - Maintenance tasks

6. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **Open a Pull Request**
   - Go to the original repository
   - Click "New Pull Request"
   - Select your feature branch
   - Provide a clear description of your changes
   - Link any related issues

### Code Review Process

All contributions are reviewed with a focus on:
- **Clarity** - Code should be easy to understand
- **Maintainability** - Follow established patterns
- **Testing** - Include appropriate tests
- **Documentation** - Update docs for user-facing changes
- **Architecture Alignment** - Fit within the existing system design

### Development Guidelines

- **Code Style**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart) guidelines
- **Testing**: Aim for >80% code coverage for new features
- **Documentation**: Add dartdoc comments for public APIs
- **Commits**: Write clear, descriptive commit messages
- **PRs**: Keep pull requests focused and atomic

### Reporting Issues

Found a bug or have a feature request?

1. Check if the issue already exists
2. Create a new issue with:
   - Clear title and description
   - Steps to reproduce (for bugs)
   - Expected vs actual behavior
   - Flutter/Dart version info
   - Platform (Android/iOS/Web)
   - Screenshots if applicable

---

## Roadmap

### Current Version: 1.4.1

### Planned Features

#### Short-term (Next Release)
- [ ] Enhanced biometric authentication options
- [ ] Offline mode with local data caching
- [ ] Push notifications for governance events
- [ ] Multi-language support (i18n)
- [ ] Dark mode improvements
- [ ] Performance optimizations

#### Mid-term (Q2-Q3 2026)
- [ ] Advanced analytics dashboard
- [ ] Social features (share achievements)
- [ ] Custom themes and personalization
- [ ] Enhanced wallet features
- [ ] Improved onboarding experience
- [ ] Integration with more blockchain networks

#### Long-term (2026+)
- [ ] AI-powered recommendations
- [ ] Augmented reality features
- [ ] Advanced data visualization
- [ ] Decentralized identity integration
- [ ] Cross-chain compatibility
- [ ] Mobile app widgets

### Recently Completed
- [x] Initial public release (v1.4.1)
- [x] Firebase authentication integration
- [x] Basic wallet functionality
- [x] Governance voting system
- [x] Real-time ledger updates
- [x] Nebula background animations

---

## License

This project is available for **non‑commercial use only** under the terms of the included `license.md` file.
Commercial use requires a separate paid license.

---

## Contact & Support

### Getting Help

- **Documentation**: Check this README and files in the `/docs` directory
- **Issues**: [GitHub Issues](https://github.com/dfeen87/front-end-peoples-coin/issues)
- **Discussions**: [GitHub Discussions](https://github.com/dfeen87/front-end-peoples-coin/discussions)

### Community

- **Repository**: [github.com/dfeen87/front-end-peoples-coin](https://github.com/dfeen87/front-end-peoples-coin)
- **Contributors**: See [CONTRIBUTORS.md](CONTRIBUTORS.md) (if available)

### Project Maintainers

For questions about the project direction or architecture, please open an issue or discussion on GitHub.

---

## Screenshots & Demo

> **Note**: Screenshots and demo links will be added here showcasing the application's UI and features.

### Key Screens
- Welcome & Authentication
- Portfolio Dashboard
- Wallet Management
- Governance & Voting
- Public Ledger
- Goodwill Action Submission

---

## Acknowledgments

BrightActs Front-End leverages the amazing Flutter framework and the vibrant Dart ecosystem. Special thanks to:

- The Flutter team for the excellent cross-platform framework
- Firebase for backend infrastructure
- All open-source contributors whose libraries made this project possible
- The BrightActs community for their support and feedback

This project was developed with a combination of original ideas, hands‑on coding, and support from advanced AI systems. I would like to acknowledge **Microsoft Copilot**, **Anthropic Claude**, **Google Jules**, and **OpenAI ChatGPT** for their meaningful assistance in refining concepts, improving clarity, and strengthening the overall quality of this work.

---

## About

**BrightActs Front-End** is a cross-platform Flutter application that enables users to securely submit, track, and visualize Goodwill Actions in real time. It integrates seamlessly with the BrightActs back-end to provide governance participation, analytics, and interactive dashboards while maintaining strong data integrity and secure authentication.

**Project Version**: 1.4.1
**Last Updated**: February 2026  
**Maintained by**: BrightActs Development Team

---

<div align="center">

**Made with ❤️ using Flutter**

[⬆ Back to Top](#brightacts-front-end)

</div>
