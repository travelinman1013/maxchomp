# MaxChomp UI/UX Flutter Development Workflow

## 🎨 Material 3 Theme System Setup

### Theme Initialization
```dart
// Always start with this theme structure for MaxChomp
ThemeData.from(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF6750A4), // MaxChomp primary brand color
    brightness: Brightness.light, // or Brightness.dark
  ),
  useMaterial3: true,
)
```

### Dynamic Color Integration
- Support system dynamic colors on Android 12+
- Provide fallback brand colors for older platforms
- Implement theme switching in Settings page
- Store theme preference in SharedPreferences

### Color Scheme Guidelines
- **Primary**: Main brand color for FABs, prominent buttons
- **Secondary**: Accent color for secondary actions
- **Surface**: Background for cards, sheets, menus
- **Error**: For error states, failed operations
- **Outline**: Borders, dividers, inactive states

## 📱 Core UI Components for MaxChomp

### App Structure
```dart
// Bottom navigation with 3 main sections
BottomNavigationBar(
  items: [
    BottomNavigationBarItem(icon: Icons.library_books, label: 'Library'),
    BottomNavigationBarItem(icon: Icons.play_circle, label: 'Player'), 
    BottomNavigationBarItem(icon: Icons.settings, label: 'Settings'),
  ],
)
```

### Library View Components
- **PDF Grid/List Toggle**: Switch between grid and list layouts
- **Import FAB**: FloatingActionButton for adding PDFs
- **Progress Indicators**: Linear progress bars for reading progress
- **Document Cards**: Material 3 cards with elevation and rounded corners
- **Search AppBar**: Expandable search functionality

### Player View Components
- **Waveform Display**: Custom painter for audio visualization
- **Player Controls**: Play/pause, skip, speed controls
- **Progress Slider**: Seekable progress bar with current position
- **Text Highlight**: Scrollable text view with current sentence highlighting
- **Speed Selector**: Bottom sheet with speed options (0.5x to 2.0x)

### Settings Components
- **ListTile Groups**: Organized settings with Material 3 styling
- **Switch Tiles**: Theme toggle, accessibility options
- **Dropdown Menus**: Voice selection, language preferences
- **Slider**: Default playback speed adjustment

## 🎯 Widget Development Workflows

### Component Creation Process
1. **Read claude.md** for state management integration points
2. **Check Context7** for latest Material 3 specifications
3. **Design responsive**: Mobile-first, then tablet adaptations
4. **Implement accessibility**: Screen reader support, semantic labels
5. **Test interactions**: Touch targets, haptic feedback, animations

### Material 3 Component Usage

#### Cards and Surfaces
```dart
Card(
  elevation: 1, // Material 3 subtle elevation
  child: Padding(
    padding: EdgeInsets.all(16),
    child: // Card content
  ),
)
```

#### Buttons and Actions
```dart
// Primary actions
FilledButton(onPressed: onPressed, child: Text('Import PDF'))

// Secondary actions  
OutlinedButton(onPressed: onPressed, child: Text('Cancel'))

// Tertiary actions
TextButton(onPressed: onPressed, child: Text('Learn More'))
```

#### Input Fields
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'Search documents',
    prefixIcon: Icon(Icons.search),
    border: OutlineInputBorder(),
  ),
)
```

## 📐 Responsive Design Guidelines

### Breakpoints for MaxChomp
- **Mobile**: 0-599dp (single column, bottom nav)
- **Tablet Portrait**: 600-839dp (single column, rail nav option)
- **Tablet Landscape**: 840dp+ (two-pane layout, navigation rail)

### Layout Patterns

#### Mobile Layout
- Single column with bottom navigation
- Full-screen player view
- Stack-based navigation for deep content

#### Tablet Layout
- Two-pane: Library list + PDF preview/player
- Navigation rail instead of bottom navigation
- Modal dialogs for settings instead of full screens

### Orientation Handling
```dart
OrientationBuilder(
  builder: (context, orientation) {
    return orientation == Orientation.portrait
        ? PortraitLayout()
        : LandscapeLayout();
  },
)
```

## 🎭 Flutter UI Patterns for MaxChomp

### PDF Library Patterns
- **Pull-to-refresh**: RefreshIndicator for library updates
- **Infinite scroll**: Pagination for large libraries
- **Swipe actions**: Edit, delete, share actions on list items
- **Grid/List toggle**: AppBar action for view switching

### Player Interface Patterns
- **Gesture controls**: Tap to play/pause, swipe for chapters
- **Mini player**: Persistent bottom player when navigating
- **Full-screen mode**: Immersive reading experience
- **Background play**: Continue audio when app backgrounded

### Settings Patterns
- **Grouped sections**: Related settings in visual groups
- **Immediate feedback**: Live preview of font size, speed changes
- **Reset options**: Restore default settings functionality
- **Import/Export**: Backup and restore user preferences

## 🎨 Animation and Transitions

### Material 3 Motion Guidelines
- **Duration**: 200-300ms for micro-interactions
- **Easing**: Emphasized easing for prominent actions
- **Shared element**: Hero animations between screens
- **Page transitions**: Material motion between routes

### MaxChomp-Specific Animations
```dart
// Smooth player controls animation
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  curve: Curves.easeInOut,
  // Player UI updates
)

// Text highlighting animation
AnimatedBuilder(
  animation: highlightAnimation,
  builder: (context, child) {
    return // Animated text highlighting
  },
)
```

## ♿ Accessibility Implementation

### Screen Reader Support
- **Semantic labels**: Meaningful labels for all interactive elements
- **Reading order**: Logical focus order for navigation
- **Live regions**: Announce playback status changes
- **Context**: Provide context for icon-only buttons

### Visual Accessibility
- **Color contrast**: WCAG AA compliance (4.5:1 ratio minimum)
- **Large touch targets**: Minimum 44dp for interactive elements
- **Text scaling**: Support Dynamic Type/Font Scale
- **High contrast**: Respect system accessibility settings

### Motor Accessibility
- **Touch target size**: Comfortable spacing between buttons
- **Hold alternatives**: Voice commands for motor-impaired users
- **Simplified navigation**: Reduce navigation complexity

## 📱 Platform-Specific UI Considerations

### iOS Adaptations
- **Safe Area**: Proper handling of notches and home indicators
- **Navigation**: iOS-style back gestures and navigation
- **Haptics**: UIFeedbackGenerator for button presses
- **Styling**: iOS-appropriate fonts and spacing when needed

### Android Adaptations
- **Material You**: Dynamic color support on Android 12+
- **Navigation**: Material navigation patterns and gestures
- **Haptics**: Android vibration patterns
- **System UI**: Proper status bar and navigation bar handling

## 🔄 UI Development Workflow

### Pre-Development
1. **Review implementation_plan.md** for current UI phase
2. **Check api_documentation.md** for state integration requirements
3. **Use Context7** for latest Material 3 component specs
4. **Design accessibility-first** approach

### During Development
- **Test on real devices**: Both iOS and Android
- **Use Flutter Inspector**: Debug widget tree and layouts
- **Profile performance**: Identify rebuild bottlenecks
- **Validate accessibility**: Use accessibility scanner

### Widget Testing Protocol
```dart
testWidgets('Player controls respond to user input', (tester) async {
  // Arrange
  await tester.pumpWidget(MaterialApp(home: PlayerPage()));
  
  // Act
  await tester.tap(find.byIcon(Icons.play_arrow));
  await tester.pump();
  
  // Assert
  expect(find.byIcon(Icons.pause), findsOneWidget);
});
```

## 🎨 Design System Integration

### Component Library
- Create reusable components in `lib/widgets/common/`
- Follow atomic design principles: atoms → molecules → organisms
- Maintain consistent spacing using multiples of 8dp
- Use theme colors and typography throughout

### Typography Scale
```dart
// MaxChomp typography usage
Text('Document Title', style: Theme.of(context).textTheme.headlineMedium)
Text('Reading progress', style: Theme.of(context).textTheme.bodyMedium)
Text('Settings label', style: Theme.of(context).textTheme.labelLarge)
```

### Spacing System
```dart
// Consistent spacing throughout MaxChomp
static const double spaceXS = 4.0;   // Tight spacing
static const double spaceSM = 8.0;   // Small spacing  
static const double spaceMD = 16.0;  // Medium spacing (most common)
static const double spaceLG = 24.0;  // Large spacing
static const double spaceXL = 32.0;  // Extra large spacing
```

## 🔧 Flutter DevTools Integration

### UI Debugging Workflow
1. **Widget Inspector**: Analyze widget tree and properties
2. **Layout Explorer**: Debug Flex and intrinsic dimensions
3. **Performance**: Profile UI rebuilds and frame rates
4. **Accessibility**: Test screen reader functionality

### Performance Optimization
- **const constructors**: Use const widgets where possible
- **RepaintBoundary**: Isolate expensive custom painters
- **AutomaticKeepAliveClientMixin**: Cache expensive list items
- **ListView.builder**: Efficient scrolling for large lists

---

**Cross-Reference**: Always coordinate with claude.md for state management integration and implementation_plan.md for development phases. This file focuses purely on UI/UX implementation while maintaining Material 3 design consistency throughout MaxChomp.