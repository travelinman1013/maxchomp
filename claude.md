# MaxChomp Flutter Development Workflow Rules

## 🔄 Session Initialization Protocol
**CRITICAL: Always read implementation_plan.md FIRST before starting any development work**
- Check tasks.md for current progress and next priorities
- Review session_history.md if available for previous context
- Use "use context7" command for real-time Flutter/Dart documentation access

## 📋 Task Management Workflow
- Always update tasks.md when starting/completing tasks
- Use Planning Mode for complex Flutter features (PDF parsing, TTS integration, player controls)
- Break large features into Claude Code-friendly subtasks
- Cross-reference with implementation_plan.md milestones

## 🎯 Context Window Management
- Prioritize reading core Flutter files: main.dart, models/, services/, providers/
- Use focused file searches rather than reading entire directories
- Reference api_documentation.md for state integration patterns
- Maintain context for Material 3 theme consistency

## 📚 Context7 Integration Commands
- **"use context7"** - Access latest Flutter/Dart documentation
- **"use context7 riverpod"** - State management patterns
- **"use context7 material 3"** - UI component specifications
- **"use context7 firebase flutter"** - Backend integration guides
- **"use context7 tts flutter"** - Text-to-speech implementation

## 🏗️ State Management Guidelines (MaxChomp-Specific)

### Riverpod Architecture
- **AudioPlayerProvider**: TTS playback state, current position, speed controls
- **LibraryProvider**: PDF document list, import status, reading progress
- **SettingsProvider**: User preferences, voice selection, theme settings
- **AuthProvider**: Firebase authentication state
- **AppStateProvider**: Global app state, navigation, loading states

### Data Flow Patterns
```dart
// Always follow this pattern for state updates
1. UI triggers action → 
2. Provider/Notifier processes → 
3. Service layer executes → 
4. State updates → 
5. UI rebuilds
```

### Error Handling
- Use AsyncValue for async operations
- Implement proper loading states for PDF processing
- Handle TTS service failures gracefully
- Provide offline fallbacks where possible

## 🔧 API Integration Patterns

### Firebase Services
- **Authentication**: Support Google, Apple, Email sign-in
- **Firestore**: Store user progress, preferences, document metadata
- **Storage**: Optional PDF cloud storage
- **Analytics**: Track usage patterns, feature adoption
- **Remote Config**: Feature flags for A/B testing

### TTS Service Integration
- **Primary**: Google Cloud TTS API
- **Fallback**: Platform-native TTS (iOS/Android)
- **Error handling**: Network failures, unsupported languages
- **Caching**: Store generated audio segments for offline playback

### PDF Processing
- Use pdf package for text extraction
- Implement chunking for large documents
- Handle password-protected PDFs
- Support various PDF formats and encodings

## 🧪 Flutter Testing Strategy

### TDD Best Practices
- Write tests before implementation (Red-Green-Refactor cycle)
- Keep functions small and focused for testability
- Maintain high test coverage for critical business logic
- Use dependency injection for better testability
- Mock external dependencies and services

### Unit Tests (test/)
- PDF parsing logic
- TTS service calls
- State management providers
- Utility functions and helpers

### Widget Tests (test/)
- Library view components
- Player control widgets  
- Settings forms and dialogs
- Material 3 theme integration

### Integration Tests (integration_test/)
- PDF import to playback flow
- Authentication workflows
- State persistence across app restarts
- Cross-platform behavior verification

### Test Organization
```
test/
├── unit/
│   ├── providers/
│   ├── services/
│   └── utils/
├── widget/
│   ├── pages/
│   ├── components/
│   └── common/
└── integration/
    ├── auth_flow_test.dart
    ├── pdf_import_test.dart
    └── player_test.dart
```

## 🚀 Development Workflow

### Before Starting Development
1. Read implementation_plan.md for current phase
2. Check tasks.md for specific assignments
3. Review relevant Context7 documentation
4. Understand Material 3 design requirements

### During Development
- Follow Material 3 design system consistently
- Test on both iOS and Android platforms
- Implement accessibility features (VoiceOver/TalkBack)
- Optimize for tablet layouts and orientations
- Use Flutter DevTools for performance profiling

### Code Quality Standards
- Follow Dart/Flutter style guide
- Use meaningful variable and function names
- Implement proper error handling and logging
- Write comprehensive comments for complex logic
- Maintain consistent file structure

### Performance Considerations
- Lazy load PDF documents in library view
- Implement efficient text chunking for TTS
- Use proper disposal of resources and listeners
- Optimize build methods and widget rebuilds
- Handle large file processing asynchronously

## 📱 Platform-Specific Guidelines

### iOS Development
- Implement Apple Sign-In
- Follow iOS Human Interface Guidelines
- Support VoiceOver accessibility
- Use proper haptic feedback patterns
- Handle iOS-specific file access permissions

### Android Development  
- Implement Google Sign-In
- Follow Material Design principles
- Support TalkBack accessibility
- Handle Android storage permissions properly
- Implement proper back navigation patterns

### Cross-Platform Considerations
- Use responsive layouts for different screen sizes
- Handle platform-specific file pickers
- Implement platform-specific authentication flows
- Test orientation changes and tablet layouts
- Ensure consistent user experience across platforms

## 🔄 Session Continuity Instructions
- Always commit meaningful progress to tasks.md
- Document any architectural decisions or changes
- Note any blockers or dependencies discovered
- Update implementation_plan.md if scope changes
- Maintain clean git history with descriptive commits

## 🎨 Material 3 Integration
- Always reference claude-ui.md for UI development
- Use ThemeData.from() with ColorScheme.fromSeed()
- Implement proper dark/light theme switching
- Follow Material 3 typography and spacing guidelines
- Use appropriate Material 3 components and animations

---

**Remember**: This file serves as the foundation for all backend and state management work on MaxChomp. Always cross-reference with claude-ui.md for UI concerns and implementation_plan.md for project roadmap alignment.