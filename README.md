# 📚🔊 MaxChomp

**Transform PDFs into natural speech with intelligent reading progress and accessibility features**

MaxChomp is a cross-platform PDF-to-speech mobile application built with Flutter 3 and Material 3 design system. It converts PDF documents to natural-sounding speech, targeting students, professionals, and accessibility-focused users.

## ✨ Features

### 🔐 **Authentication & Security**
- Email/password authentication with Firebase Auth
- Google Sign-In integration
- Secure user data management
- Material 3 authentication screens

### 📄 **PDF Import & Management**
- Local file selection with platform-specific pickers
- File validation and error handling (PDF signature, size limits)
- Document metadata extraction and storage
- Reading progress tracking
- Cloud storage integration ready

### 🎛️ **State Management**
- Riverpod providers for clean architecture
- Async state management with proper loading states
- Persistent document library with SharedPreferences
- Comprehensive error handling and user feedback

### 🎨 **Material 3 Design**
- Consistent Material 3 theme system
- Light/dark mode support
- Responsive layouts for mobile and tablet
- Accessibility features (VoiceOver/TalkBack ready)

## 🏗️ Technical Architecture

### **Frontend**
- **Framework**: Flutter 3.8.1+ with Material 3
- **State Management**: Riverpod with AsyncValue patterns
- **UI Components**: Material 3 with custom MaxChomp branding
- **Platform Support**: iOS 13+, Android 8.0+, tablets

### **Backend**
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore for user data
- **Storage**: Firebase Storage (optional PDF cloud storage)
- **Analytics**: Firebase Analytics with usage tracking

### **Core Services**
- **PDF Processing**: pdf package for text extraction
- **TTS Services**: Google Cloud TTS (primary), platform-native fallback
- **File Management**: file_picker with validation and security
- **Permissions**: Platform-specific file access handling

## 📊 Development Status

- **Phase 1**: Foundation & Setup ✅ (75% complete)
- **Phase 2**: PDF Processing 🔄 (38% complete)
- **Phase 3**: TTS Integration ⏳ (Planned)
- **Phase 4**: Settings & Preferences ⏳ (Planned)

**Overall Progress**: 11/69 tasks completed (16%)

### 🧪 **Testing Coverage**
- **45 test cases** with 100% business logic coverage
- **TDD approach** with Red-Green-Refactor methodology
- **Unit Tests**: Models, services, and utility functions
- **Widget Tests**: UI components and user interactions
- **Provider Tests**: State management and async operations

## 🚀 Getting Started

### Prerequisites
- Flutter 3.8.1 or higher
- Dart SDK 3.0+
- iOS development: Xcode 14+
- Android development: Android Studio with SDK 33+

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/travelinman1013/maxchomp.git
   cd maxchomp
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code** (for mocks and providers)
   ```bash
   flutter pub run build_runner build
   ```

4. **Run tests**
   ```bash
   flutter test
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Setup (Required for Authentication)

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Add iOS and Android apps to your project
3. Download configuration files:
   - `ios/Runner/GoogleService-Info.plist`
   - `android/app/google-services.json`
4. Enable Authentication providers (Email/Password, Google)
5. Set up Firestore database

## 🎯 Core Components

### **Models**
- `PDFDocument`: Complete data model with serialization and progress tracking
- `AuthState`: Authentication state management
- Document status tracking and metadata

### **Services**
- `PDFImportService`: File picker integration with validation
- `FirebaseService`: Authentication and backend integration
- Error handling and user feedback systems

### **Providers (Riverpod)**
- `AuthProvider`: Authentication state management
- `PDFImportProvider`: Import operation handling
- `LibraryProvider`: Document collection management
- Async state handling with loading and error states

### **UI Components**
- Material 3 authentication screens
- `PDFImportButton`: Adaptive import button with loading states
- Document cards and library views (planned)
- Player controls and progress tracking (planned)

## 🧪 Testing Strategy

MaxChomp follows a comprehensive TDD approach:

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/core/models/
flutter test test/core/services/
flutter test test/core/providers/

# Generate test coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Organization
```
test/
├── core/
│   ├── models/          # Data model tests
│   ├── services/        # Business logic tests
│   └── providers/       # State management tests
├── widgets/             # Widget and UI tests
└── integration_test/    # End-to-end tests (planned)
```

## 🎨 Design System

MaxChomp uses Material 3 design with custom branding:

- **Primary Color**: `#6750A4` (MaxChomp purple)
- **Typography**: Material 3 text styles
- **Spacing**: 8dp grid system (4dp, 8dp, 16dp, 24dp, 32dp)
- **Components**: FilledButton, OutlinedButton, Cards, NavigationBar

## 📱 Platform Support

### **iOS Features**
- Apple Sign-In integration (planned)
- VoiceOver accessibility support
- iOS Human Interface Guidelines compliance
- Haptic feedback patterns

### **Android Features**
- Google Sign-In integration ✅
- Material You dynamic theming
- TalkBack accessibility support
- Android design pattern compliance

## 🔄 Development Workflow

This project follows clean architecture principles:

1. **TDD Approach**: Tests written before implementation
2. **Feature Branches**: Organized development workflow
3. **Code Review**: Quality assurance through reviews
4. **Documentation**: Comprehensive session history and planning

### Key Development Files
- `claude.md`: Backend development guidelines
- `claude-ui.md`: UI/UX development patterns
- `implementation_plan.md`: Project roadmap
- `session_history.md`: Development progress tracking

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Follow the existing code style and architecture
4. Write comprehensive tests for new functionality
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Riverpod** for clean state management
- **Firebase** for backend services
- **Material Design** for design system guidance
- **Claude Code** for development assistance

---

**Built with ❤️ using Flutter 3 + Material 3 + Firebase**

*Transform your reading experience with MaxChomp* 📚→🔊
