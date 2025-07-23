import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:maxchomp/pages/library_page.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/providers/library_provider.dart';
import 'package:maxchomp/core/theme/app_theme.dart';

void main() {
  group('LibraryPage', () {
    late List<PDFDocument> mockDocuments;

    setUp(() {
      mockDocuments = [
        PDFDocument(
          id: '1',
          fileName: 'test_document_1.pdf',
          filePath: '/path/to/test1.pdf',
          fileSize: 1024000,
          importedAt: DateTime(2025, 1, 1),
          status: DocumentStatus.ready,
          totalPages: 10,
          readingProgress: 0.5,
        ),
        PDFDocument(
          id: '2',
          fileName: 'test_document_2.pdf',
          filePath: '/path/to/test2.pdf',
          fileSize: 2048000,
          importedAt: DateTime(2025, 1, 2),
          status: DocumentStatus.processing,
          totalPages: 20,
          readingProgress: 0.0,
        ),
      ];
    });

    Widget createTestWidget({List<PDFDocument>? documents}) {
      return ProviderScope(
        overrides: [
          libraryProvider.overrideWith((ref) => LibraryNotifier()
            ..state = LibraryState(documents: documents ?? mockDocuments)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme(),
          home: const LibraryPage(),
        ),
      );
    }

    group('UI Structure', () {
      testWidgets('should display app bar with correct title', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('Library'), findsOneWidget);
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('should display search and view toggle buttons in app bar', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byIcon(Icons.search), findsOneWidget);
        expect(find.byIcon(Icons.view_list), findsOneWidget);
      });

      testWidgets('should display floating action button', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });
    });

    group('Document Display', () {
      testWidgets('should display documents in grid view by default', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(GridView), findsOneWidget);
        expect(find.text('test_document_1.pdf'), findsOneWidget);
        expect(find.text('test_document_2.pdf'), findsOneWidget);
      });

      testWidgets('should switch to list view when toggle is pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Initially in grid view
        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(ListView), findsNothing);
        
        // Tap the view toggle button
        await tester.tap(find.byIcon(Icons.view_list));
        await tester.pump();
        
        // Should switch to list view
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(GridView), findsNothing);
        expect(find.byIcon(Icons.grid_view), findsOneWidget);
      });
    });

    group('Empty State', () {
      testWidgets('should display empty state when no documents', (tester) async {
        await tester.pumpWidget(createTestWidget(documents: []));
        
        expect(find.text('Your library is empty'), findsOneWidget);
        expect(find.text('Import your first PDF to get started'), findsOneWidget);
        expect(find.byIcon(Icons.library_books_outlined), findsOneWidget);
        // Should find Import PDF text in both empty state and floating action button
        expect(find.text('Import PDF'), findsNWidgets(2));
        // Verify FloatingActionButton specifically
        expect(find.byType(FloatingActionButton), findsOneWidget);
      });

      testWidgets('should display no results message when search has no matches', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Open search dialog
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        
        // Search for non-existent document
        await tester.enterText(find.byType(TextField), 'nonexistent.pdf');
        await tester.tap(find.text('Search'));
        await tester.pump();
        
        expect(find.text('No documents found'), findsOneWidget);
        expect(find.text('Try adjusting your search terms'), findsOneWidget);
      });
    });

    group('Search Functionality', () {
      testWidgets('should open search dialog when search button is pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        
        expect(find.text('Search Library'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('should filter documents based on search query', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Open search dialog
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        
        // Search for specific document
        await tester.enterText(find.byType(TextField), 'test_document_1');
        await tester.tap(find.text('Search'));
        await tester.pump();
        
        // Should only show matching document
        expect(find.text('test_document_1.pdf'), findsOneWidget);
        expect(find.text('test_document_2.pdf'), findsNothing);
      });

      testWidgets('should clear search when clear button is pressed', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Open search dialog and search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'test_document_1');
        await tester.tap(find.text('Search'));
        await tester.pump();
        
        // Verify filtered state
        expect(find.text('test_document_1.pdf'), findsOneWidget);
        expect(find.text('test_document_2.pdf'), findsNothing);
        
        // Clear search
        await tester.tap(find.byIcon(Icons.search));
        await tester.pump();
        await tester.tap(find.text('Clear'));
        await tester.pump();
        
        // Should show all documents again
        expect(find.text('test_document_1.pdf'), findsOneWidget);
        expect(find.text('test_document_2.pdf'), findsOneWidget);
      });
    });

    group('Responsive Design', () {
      testWidgets('should show 2 columns on mobile width', (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(createTestWidget());
        
        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, equals(2));
      });

      testWidgets('should show 3 columns on tablet width', (tester) async {
        tester.view.physicalSize = const Size(700, 1000);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(createTestWidget());
        
        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, equals(3));
      });

      testWidgets('should show 4 columns on desktop width', (tester) async {
        tester.view.physicalSize = const Size(1000, 800);
        tester.view.devicePixelRatio = 1.0;
        
        await tester.pumpWidget(createTestWidget());
        
        final gridView = tester.widget<GridView>(find.byType(GridView));
        final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
        expect(delegate.crossAxisCount, equals(4));
      });
    });

    group('Refresh Functionality', () {
      testWidgets('should support pull-to-refresh', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(RefreshIndicator), findsOneWidget);
      });
    });

    group('Material 3 Theme Integration', () {
      testWidgets('should use correct Material 3 colors', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        final theme = Theme.of(tester.element(find.byType(AppBar)));
        
        expect(appBar.backgroundColor, equals(theme.colorScheme.surface));
        expect(appBar.foregroundColor, equals(theme.colorScheme.onSurface));
        expect(appBar.elevation, equals(0));
      });

      testWidgets('should use consistent spacing throughout', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Verify padding uses AppTheme constants
        final padding = tester.widget<Padding>(find.byType(Padding).first);
        expect(padding.padding, equals(const EdgeInsets.all(AppTheme.spaceMD)));
      });
    });
  });
}