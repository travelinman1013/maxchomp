# MaxChomp App ASCII Wireframes

*Visual documentation of MaxChomp Flutter app interface design and Material 3 components*

---

## 📱 Main App Structure - Bottom Navigation

```
┌─────────────────────────────────────────┐
│ MaxChomp                           ⚙️📱 │ <- AppBar with settings
├─────────────────────────────────────────┤
│                                         │
│            MAIN CONTENT AREA            │
│         (Changes based on tab)          │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│  📚      ▶️       ⚙️                   │ <- Bottom Navigation
│Library  Player  Settings               │
└─────────────────────────────────────────┘
```

---

## 1. Library View (PDF Collection)

```
┌─────────────────────────────────────────┐
│ 📚 Library                    🔍  ⋮     │
├─────────────────────────────────────────┤
│ 🔍 Search documents...                  │
├─────────────────────────────────────────┤
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📄 Advanced Flutter Guide.pdf      │ │ <- PDF Card
│ │ 2.3 MB • 45 pages                  │ │
│ │ ████████░░ 80% complete             │ │ <- Progress bar
│ │ Last read: 2 hours ago       ▶️    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📄 Dart Language Tour.pdf          │ │
│ │ 1.8 MB • 32 pages                  │ │
│ │ ░░░░░░░░░░ Not started              │ │
│ │ Imported: Yesterday          ▶️    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 📄 Material Design 3.pdf           │ │
│ │ 3.1 MB • 67 pages                  │ │
│ │ ██████████ Complete ✓               │ │
│ │ Finished: 3 days ago         ▶️    │ │
│ └─────────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│  📚      ▶️       ⚙️                   │
│Library  Player  Settings               │
└─────────────────────────────────────────┘
                    ┌─────┐
                    │  +  │ <- FAB for import
                    └─────┘
```

---

## 2. Player View (TTS Playback)

```
┌─────────────────────────────────────────┐
│ ▶️ Player                               │
├─────────────────────────────────────────┤
│                                         │
│      📄 Advanced Flutter Guide.pdf     │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎵 Audio Waveform Visualization    │ │ <- Custom painter
│ │ ∿∿∿∿▲∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿∿ │ │
│ └─────────────────────────────────────┘ │
│                                         │
│        ████████████░░░░░░░░             │ <- Progress slider
│        12:34 / 18:45                    │
│                                         │
│     ⏮️    ⏸️    ⏭️    🔊    1.5x        │ <- Player controls
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Current Text Being Read:            │ │ <- Text display
│ │                                     │ │
│ │ "Flutter is Google's UI toolkit     │ │
│ │  for building beautiful, natively   │ │
│ │  compiled applications for mobile,  │ │ <- Highlighted sentence
│ │  web, and desktop from a single     │ │
│ │  codebase."                         │ │
│ └─────────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│  📚      ▶️       ⚙️                   │
│Library  Player  Settings               │
└─────────────────────────────────────────┘
```

---

## 3. Settings View (User Preferences)

```
┌─────────────────────────────────────────┐
│ ⚙️ Settings                             │
├─────────────────────────────────────────┤
│                                         │
│ 🎵 AUDIO PREFERENCES                    │
│ ┌─────────────────────────────────────┐ │
│ │ Voice Selection                     │ │
│ │ Sarah (English US) ▼                │ │ <- Dropdown
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Speech Rate                         │ │
│ │ ●━━━━━━━━━━ 1.2x                     │ │ <- Slider
│ └─────────────────────────────────────┘ │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ Volume                              │ │
│ │ ●━━━━━━━━━━ 85%                      │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 🎨 APPEARANCE                           │
│ ┌─────────────────────────────────────┐ │
│ │ Dark Mode              [  ●  ]      │ │ <- Toggle switch
│ └─────────────────────────────────────┘ │
│                                         │
│ ♿ ACCESSIBILITY                        │
│ ┌─────────────────────────────────────┐ │
│ │ Large Text            [  ●  ]       │ │
│ │ High Contrast         [     ]       │ │
│ └─────────────────────────────────────┘ │
│                                         │
├─────────────────────────────────────────┤
│  📚      ▶️       ⚙️                   │
│Library  Player  Settings               │
└─────────────────────────────────────────┘
```

---

## Voice Selection Modal (Settings)

```
┌─────────────────────────────────────────┐
│ 🎵 Select Voice                    ✕   │
├─────────────────────────────────────────┤
│                                         │
│ ENGLISH                                 │
│ ┌─────────────────────────────────────┐ │
│ │ ●  Sarah (US Female)       🔊  ▶️  │ │ <- Selected
│ │    David (US Male)         🔊  ▶️  │ │
│ │    Emma (UK Female)        🔊  ▶️  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ SPANISH                                 │
│ ┌─────────────────────────────────────┐ │
│ │    María (ES Female)       🔊  ▶️  │ │
│ │    Carlos (MX Male)        🔊  ▶️  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ FRENCH                                  │
│ ┌─────────────────────────────────────┐ │
│ │    Amélie (FR Female)      🔊  ▶️  │ │
│ └─────────────────────────────────────┘ │
│                                         │
│                    ┌──────┐ ┌────────┐  │
│                    │Cancel│ │ Select │  │
│                    └──────┘ └────────┘  │
└─────────────────────────────────────────┘
```

---

## PDF Import Screen

```
┌─────────────────────────────────────────┐
│ ← Import PDF                            │
├─────────────────────────────────────────┤
│                                         │
│               📄                        │
│                                         │
│      Drag & Drop PDF Files Here        │
│              or                         │
│                                         │
│         ┌─────────────────┐             │
│         │  Browse Files   │             │ <- Button
│         └─────────────────┘             │
│                                         │
│                                         │
│ ☁️ Import from Cloud                    │
│ ┌─────────────────────────────────────┐ │
│ │  📱 Google Drive                    │ │
│ │  📦 Dropbox                         │ │
│ │  ☁️ iCloud Drive                    │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ 📊 Supported Formats                    │
│ PDF, EPUB (coming soon)                 │
│ Max size: 50MB                          │
│                                         │
├─────────────────────────────────────────┤
│  📚      ▶️       ⚙️                   │
│Library  Player  Settings               │
└─────────────────────────────────────────┘
```

---

## Mini Player (Background Mode)

```
┌─────────────────────────────────────────┐
│ 📚 Library                    🔍  ⋮     │
├─────────────────────────────────────────┤
│                                         │
│           [Library Content]             │
│                                         │
│                ...                      │
│                                         │
├─────────────────────────────────────────┤
│ 📄 Flutter Guide.pdf        ⏸️  ⏹️  ▲ │ <- Mini player
│ ████████░░ "Google's UI toolkit..."     │
├─────────────────────────────────────────┤
│  📚      ▶️       ⚙️                   │
│Library  Player  Settings               │
└─────────────────────────────────────────┘
```

---

## 🎨 Material 3 Design Elements Used

### Core Components
- **🎨 Cards**: Elevated surfaces for PDF items and settings groups
- **🎛️ Controls**: Material 3 buttons, sliders, and toggles
- **📊 Progress**: Linear progress indicators with rounded corners
- **🎵 Navigation**: Bottom navigation with Material You theming
- **🎪 Modals**: Bottom sheets and dialogs with Material 3 styling
- **♿ Accessibility**: Large touch targets, semantic labels, high contrast support

### Design Principles
- **Dynamic Color Theming**: Material You color adaptation
- **Proper Elevation**: Layered surfaces with appropriate shadows
- **Responsive Design**: Adaptive layouts for phone and tablet
- **Typography**: Material 3 text styles and hierarchy
- **Interactive States**: Hover, focus, and selection feedback
- **Motion**: Smooth transitions and meaningful animations

### Accessibility Features
- **Touch Targets**: Minimum 48dp for all interactive elements
- **Semantic Labels**: Proper screen reader support
- **High Contrast**: Optional high contrast mode
- **Text Scaling**: Support for dynamic text sizing
- **Color Independence**: Information conveyed beyond color alone
- **Focus Management**: Clear focus indicators and logical navigation

---

## 📱 Platform Considerations

### iOS Specific
- **Native Navigation**: iOS-style back gestures and navigation patterns
- **Apple Sign-In**: Integrated authentication option
- **VoiceOver**: Full iOS accessibility support
- **Haptic Feedback**: Contextual haptic responses
- **Control Center**: Lock screen media controls integration

### Android Specific
- **Material Design**: Native Android Material You theming
- **Google Sign-In**: Integrated authentication option
- **TalkBack**: Full Android accessibility support
- **Foreground Service**: Background audio playback
- **Media Notifications**: Android media session integration

### Cross-Platform
- **Consistent UX**: Unified experience across platforms
- **Responsive Design**: Adaptive layouts for different screen sizes
- **State Management**: Riverpod-based state synchronization
- **Testing**: Comprehensive widget and integration tests
- **Performance**: Optimized for smooth 60fps animations

---

*Last Updated: 2025-07-23*
*Part of MaxChomp Flutter PDF-to-Audio Application*