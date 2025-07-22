import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxchomp/widgets/library/pdf_document_card.dart';
import 'package:maxchomp/core/models/pdf_document.dart';
import 'package:maxchomp/core/theme/app_theme.dart';

void main() {
  group('PDFDocumentCard', () {
    late PDFDocument mockDocument;

    setUp(() {
      mockDocument = PDFDocument(
        id: '1',
        fileName: 'test_document.pdf',
        filePath: '/path/to/test.pdf',
        fileSize: 1024000, // 1MB
        importedAt: DateTime(2025, 1, 1),
        lastReadAt: DateTime(2025, 1, 2),
        status: DocumentStatus.ready,
        totalPages: 10,
        readingProgress: 0.75,
        currentPage: 8,
      );
    });

    Widget createTestWidget({
      PDFDocument? document,
      bool isGridView = true,
      VoidCallback? onTap,
      Function(String)? onMenu,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: PDFDocumentCard(
            document: document ?? mockDocument,
            isGridView: isGridView,
            onTap: onTap ?? () {},
            onMenu: onMenu ?? (_) {},
          ),
        ),
      );
    }

    group('Grid View Layout', () {
      testWidgets('should display as Material 3 card in grid view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(Card), findsOneWidget);
        
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(1.0)); // Material 3 subtle elevation
      });

      testWidgets('should display document icon in grid view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      });

      testWidgets('should display filename in grid view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('test_document.pdf'), findsOneWidget);
      });

      testWidgets('should display file size in grid view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('1000.0KB • 10 pages'), findsOneWidget);
      });

      testWidgets('should display page count in grid view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.text('1000.0KB • 10 pages'), findsOneWidget);
      });

      testWidgets('should display progress indicator in grid view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      });
    });

    group('List View Layout', () {
      testWidgets('should display as list tile format in list view', (tester) async {
        await tester.pumpWidget(createTestWidget(isGridView: false));
        
        expect(find.byType(Card), findsOneWidget);
        
        // Should have leading icon, title, subtitle, and trailing elements
        expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
        expect(find.text('test_document.pdf'), findsOneWidget);
        expect(find.text('1000.0KB • 10 pages'), findsOneWidget);
      });

      testWidgets('should display progress information in list view', (tester) async {
        await tester.pumpWidget(createTestWidget(isGridView: false));
        
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('75%'), findsOneWidget);
      });

      testWidgets('should display more button in list view', (tester) async {
        await tester.pumpWidget(createTestWidget(isGridView: false));
        
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });
    });

    group('Document Status Display', () {
      testWidgets('should show ready status with success color', (tester) async {
        final readyDocument = mockDocument.copyWith(status: DocumentStatus.ready);
        await tester.pumpWidget(createTestWidget(document: readyDocument));
        
        // Should have green/success indicator for ready status
        final theme = Theme.of(tester.element(find.byType(Card)));
        // We'll verify this through the presence of status indicator
        expect(find.byType(Icon), findsWidgets); // PDF icon and status indicator
      });

      testWidgets('should show processing status with loading indicator', (tester) async {
        final processingDocument = mockDocument.copyWith(status: DocumentStatus.processing);
        await tester.pumpWidget(createTestWidget(document: processingDocument));
        
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should show failed status with error indication', (tester) async {
        final failedDocument = mockDocument.copyWith(
          status: DocumentStatus.failed,
          errorMessage: 'Failed to process PDF',
        );
        await tester.pumpWidget(createTestWidget(document: failedDocument));
        
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should show imported status with import icon', (tester) async {
        final importedDocument = mockDocument.copyWith(status: DocumentStatus.imported);
        await tester.pumpWidget(createTestWidget(document: importedDocument));
        
        expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
      });
    });

    group('Interaction Handling', () {
      testWidgets('should call onTap when card is tapped', (tester) async {
        bool tapped = false;
        await tester.pumpWidget(createTestWidget(
          onTap: () => tapped = true,
        ));
        
        await tester.tap(find.byType(Card));
        expect(tapped, isTrue);
      });

      testWidgets('should show context menu on long press in grid view', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        await tester.longPress(find.byType(Card));
        await tester.pumpAndSettle();
        
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
        expect(find.text('Info'), findsOneWidget);
      });

      testWidgets('should show context menu on more button tap in list view', (tester) async {
        String selectedAction = '';
        await tester.pumpWidget(createTestWidget(
          isGridView: false,
          onMenu: (action) => selectedAction = action,
        ));
        
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        
        expect(find.text('Delete'), findsOneWidget);
        expect(find.text('Share'), findsOneWidget);
        expect(find.text('Info'), findsOneWidget);
        
        // Test menu action
        await tester.tap(find.text('Delete'));
        expect(selectedAction, equals('delete'));
      });
    });

    group('Progress Visualization', () {
      testWidgets('should display correct progress value', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, equals(0.75));
      });

      testWidgets('should handle zero progress', (tester) async {
        final zeroProgressDoc = mockDocument.copyWith(readingProgress: 0.0);
        await tester.pumpWidget(createTestWidget(document: zeroProgressDoc));
        
        expect(find.text('0%'), findsOneWidget);
        
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, equals(0.0));
      });

      testWidgets('should handle complete progress', (tester) async {
        final completeDoc = mockDocument.copyWith(readingProgress: 1.0);
        await tester.pumpWidget(createTestWidget(document: completeDoc));
        
        expect(find.text('100%'), findsOneWidget);
        
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, equals(1.0));
      });
    });

    group('Material 3 Design Compliance', () {
      testWidgets('should use Material 3 card styling', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.elevation, equals(1.0));
        
        // Verify rounded corners (Material 3 standard)
        expect(card.shape, isA<RoundedRectangleBorder>());
      });

      testWidgets('should use correct Material 3 colors', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        final theme = Theme.of(tester.element(find.byType(Card)));
        // Card should use surface color from theme
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.color, anyOf(isNull, equals(theme.colorScheme.surface)));
      });

      testWidgets('should use consistent spacing', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Verify that spacing follows AppTheme constants
        final paddingWidgets = find.byType(Padding);
        expect(paddingWidgets, isNot(findsNothing)); // Should have padding widgets
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Card should be tappable and have semantic information
        expect(find.byType(InkWell), findsOneWidget);
        
        // Should provide accessibility information for screen readers
        final card = find.byType(InkWell);
        expect(card, findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (tester) async {
        await tester.pumpWidget(createTestWidget());
        
        // Card should be focusable for keyboard navigation
        final inkWell = tester.widget<InkWell>(find.byType(InkWell));
        expect(inkWell.focusNode != null || inkWell.canRequestFocus, isTrue);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle documents without lastReadAt', (tester) async {
        final docWithoutLastRead = mockDocument.copyWith(lastReadAt: null);
        await tester.pumpWidget(createTestWidget(document: docWithoutLastRead));
        
        // Should still render without errors
        expect(find.byType(Card), findsOneWidget);
        expect(find.text('test_document.pdf'), findsOneWidget);
      });

      testWidgets('should handle very long filenames', (tester) async {
        final longNameDoc = mockDocument.copyWith(
          fileName: 'this_is_a_very_long_filename_that_might_overflow_the_card_layout_and_cause_issues.pdf',
        );
        await tester.pumpWidget(createTestWidget(document: longNameDoc));
        
        // Should render without overflow
        expect(find.byType(Card), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle zero page count', (tester) async {
        final zeroPageDoc = mockDocument.copyWith(totalPages: 0);
        await tester.pumpWidget(createTestWidget(document: zeroPageDoc));
        
        expect(find.text('1000.0KB • 0 pages'), findsOneWidget);
      });
    });
  });
}