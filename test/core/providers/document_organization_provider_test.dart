import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/core/models/document_folder.dart';
import 'package:maxchomp/core/services/document_organization_service.dart';
import 'package:maxchomp/core/providers/document_organization_provider.dart';

// Generate mocks
@GenerateMocks([SharedPreferences, DocumentOrganizationService])
import 'document_organization_provider_test.mocks.dart';

/// Test suite for DocumentOrganizationProvider following TDD and Context7 Riverpod patterns
/// 
/// This test file verifies the DocumentOrganizationProvider functionality including:
/// - StateNotifier implementation with proper isolation
/// - Async state management with loading, error, and success states
/// - Provider interactions and state updates
/// - Folder CRUD operations through the provider
/// - Error handling and recovery patterns
/// - Integration with DocumentOrganizationService
/// 
/// Tests follow Context7 Riverpod patterns with ProviderContainer.test() for isolation

void main() {
  group('DocumentOrganizationProvider Tests', () {
    late MockDocumentOrganizationService mockService;
    late DateTime testDate;
    late DocumentFolder rootFolder;
    late DocumentFolder childFolder;

    setUpAll(() {
      testDate = DateTime(2025, 1, 24, 10, 30);
    });

    setUp(() {
      mockService = MockDocumentOrganizationService();
      
      rootFolder = DocumentFolder(
        id: 'root-folder-123',
        name: 'Work Documents',
        description: 'Documents for work projects',
        createdAt: testDate,
        updatedAt: testDate,
        parentId: null,
        color: '#FF6B6B',
        documentIds: const ['doc1', 'doc2'],
        tags: const ['work', 'important'],
        isDefault: false,
        sortOrder: 0,
      );

      childFolder = DocumentFolder(
        id: 'child-folder-456',
        name: 'Archive',
        description: 'Archived documents',
        createdAt: testDate,
        updatedAt: testDate,
        parentId: 'root-folder-123',
        color: '#4ECDC4',
        documentIds: const ['doc3'],
        tags: const ['archive'],
        isDefault: false,
        sortOrder: 1,
      );

      // Setup default mock behaviors
      when(mockService.isInitialized).thenReturn(false);
      when(mockService.initialize()).thenAnswer((_) async {});
      when(mockService.getAllFolders()).thenReturn([]);
      when(mockService.getRootFolders()).thenReturn([]);
    });

    group('Provider Initialization and State Management', () {
      test('should initialize provider with loading state', () {
        final container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        final provider = container.read(documentOrganizationProvider);
        
        // Initial state should be loading
        expect(provider.isLoading, isTrue);
        expect(provider.hasError, isFalse);
        expect(provider.hasValue, isFalse);
      });

      test('should initialize service and load folders successfully', () async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder, childFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
        });

        final container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        // Wait for provider to initialize
        await container.read(documentOrganizationProvider.future);

        final providerState = container.read(documentOrganizationProvider);
        
        expect(providerState.isLoading, isFalse);
        expect(providerState.hasError, isFalse);
        expect(providerState.hasValue, isTrue);
        expect(providerState.value!.allFolders, hasLength(2));
        expect(providerState.value!.rootFolders, hasLength(1));
        
        verify(mockService.initialize()).called(1);
      });

      test('should handle initialization errors gracefully', () async {
        when(mockService.initialize()).thenThrow(Exception('Initialization failed'));

        final container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        final providerState = container.read(documentOrganizationProvider);
        
        expect(providerState.isLoading, isFalse);
        expect(providerState.hasError, isTrue);
        expect(providerState.error.toString(), contains('Initialization failed'));
      });

      test('should provide folder hierarchy state correctly', () async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder, childFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
          when(mockService.getChildFolders(rootFolder.id)).thenReturn([childFolder]);
        });

        final container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        await container.read(documentOrganizationProvider.future);
        final state = container.read(documentOrganizationProvider).requireValue;

        expect(state.allFolders, containsAll([rootFolder, childFolder]));
        expect(state.rootFolders, contains(rootFolder));
        expect(state.getChildFolders(rootFolder.id), contains(childFolder));
      });
    });

    group('Folder CRUD Operations', () {
      late ProviderContainer container;

      setUp(() async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
        });

        container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );

        // Initialize the provider
        await container.read(documentOrganizationProvider.future);
      });

      tearDown(() {
        container.dispose();
      });

      test('should create new folder successfully', () async {
        final newFolder = DocumentFolder(
          id: 'new-folder-789',
          name: 'New Project',
          description: 'A new project folder',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockService.createFolder(
          name: 'New Project',
          description: 'A new project folder',
          parentId: null,
          color: '#00FF00',
          tags: const ['project'],
        )).thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([rootFolder, newFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder, newFolder]);
          return newFolder;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.createFolder(
          name: 'New Project',
          description: 'A new project folder',
          color: '#00FF00',
          tags: const ['project'],
        );

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders, hasLength(2));
        expect(state.allFolders.any((f) => f.id == newFolder.id), isTrue);
        
        verify(mockService.createFolder(
          name: 'New Project',
          description: 'A new project folder',
          parentId: null,
          color: '#00FF00',
          tags: const ['project'],
        )).called(1);
      });

      test('should handle folder creation errors', () async {
        when(mockService.createFolder(
          name: 'Invalid Folder',
          description: any,
          parentId: any,
          color: any,
          tags: any,
        )).thenThrow(ArgumentError('Invalid folder name'));

        final notifier = container.read(documentOrganizationProvider.notifier);
        
        expect(
          () => notifier.createFolder(name: 'Invalid Folder'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should update folder successfully', () async {
        final updatedFolder = rootFolder.copyWith(
          name: 'Updated Work Documents',
          description: 'Updated description',
          updatedAt: testDate.add(const Duration(minutes: 5)),
        );

        when(mockService.updateFolder(
          rootFolder.id,
          name: 'Updated Work Documents',
          description: 'Updated description',
        )).thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([updatedFolder]);
          when(mockService.getRootFolders()).thenReturn([updatedFolder]);
          return updatedFolder;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.updateFolder(
          rootFolder.id,
          name: 'Updated Work Documents',
          description: 'Updated description',
        );

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders.first.name, equals('Updated Work Documents'));
        expect(state.allFolders.first.description, equals('Updated description'));
        
        verify(mockService.updateFolder(
          rootFolder.id,
          name: 'Updated Work Documents',
          description: 'Updated description',
        )).called(1);
      });

      test('should delete folder successfully', () async {
        when(mockService.deleteFolder(rootFolder.id)).thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([]);
          when(mockService.getRootFolders()).thenReturn([]);
          return true;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        final success = await notifier.deleteFolder(rootFolder.id);

        expect(success, isTrue);
        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders, isEmpty);
        
        verify(mockService.deleteFolder(rootFolder.id)).called(1);
      });

      test('should handle delete failure', () async {
        when(mockService.deleteFolder('invalid-id')).thenAnswer((_) async => false);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final success = await notifier.deleteFolder('invalid-id');

        expect(success, isFalse);
        verify(mockService.deleteFolder('invalid-id')).called(1);
      });
    });

    group('Document Association Operations', () {
      late ProviderContainer container;

      setUp(() async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
        });

        container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );

        await container.read(documentOrganizationProvider.future);
      });

      tearDown(() {
        container.dispose();
      });

      test('should add document to folder successfully', () async {
        final updatedFolder = rootFolder.copyWith(
          documentIds: [...rootFolder.documentIds, 'new-doc-123'],
        );

        when(mockService.addDocumentToFolder(rootFolder.id, 'new-doc-123'))
            .thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([updatedFolder]);
          return updatedFolder;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.addDocumentToFolder(rootFolder.id, 'new-doc-123');

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders.first.documentIds, contains('new-doc-123'));
        
        verify(mockService.addDocumentToFolder(rootFolder.id, 'new-doc-123')).called(1);
      });

      test('should remove document from folder successfully', () async {
        final updatedFolder = rootFolder.copyWith(
          documentIds: rootFolder.documentIds.where((id) => id != 'doc1').toList(),
        );

        when(mockService.removeDocumentFromFolder(rootFolder.id, 'doc1'))
            .thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([updatedFolder]);
          return updatedFolder;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.removeDocumentFromFolder(rootFolder.id, 'doc1');

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders.first.documentIds, isNot(contains('doc1')));
        
        verify(mockService.removeDocumentFromFolder(rootFolder.id, 'doc1')).called(1);
      });

      test('should move document between folders successfully', () async {
        final targetFolder = childFolder.copyWith(
          documentIds: [...childFolder.documentIds, 'doc1'],
        );
        final sourceFolder = rootFolder.copyWith(
          documentIds: rootFolder.documentIds.where((id) => id != 'doc1').toList(),
        );

        when(mockService.moveDocumentToFolder('doc1', rootFolder.id, childFolder.id))
            .thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([sourceFolder, targetFolder]);
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.moveDocumentToFolder('doc1', rootFolder.id, childFolder.id);

        verify(mockService.moveDocumentToFolder('doc1', rootFolder.id, childFolder.id)).called(1);
      });
    });

    group('Tag Management Operations', () {
      late ProviderContainer container;

      setUp(() async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
        });

        container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );

        await container.read(documentOrganizationProvider.future);
      });

      tearDown(() {
        container.dispose();
      });

      test('should add tag to folder successfully', () async {
        final updatedFolder = rootFolder.copyWith(
          tags: [...rootFolder.tags, 'new-tag'],
        );

        when(mockService.addTagToFolder(rootFolder.id, 'new-tag'))
            .thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([updatedFolder]);
          return updatedFolder;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.addTagToFolder(rootFolder.id, 'new-tag');

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders.first.tags, contains('new-tag'));
        
        verify(mockService.addTagToFolder(rootFolder.id, 'new-tag')).called(1);
      });

      test('should remove tag from folder successfully', () async {
        final updatedFolder = rootFolder.copyWith(
          tags: rootFolder.tags.where((tag) => tag != 'work').toList(),
        );

        when(mockService.removeTagFromFolder(rootFolder.id, 'work'))
            .thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([updatedFolder]);
          return updatedFolder;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.removeTagFromFolder(rootFolder.id, 'work');

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders.first.tags, isNot(contains('work')));
        
        verify(mockService.removeTagFromFolder(rootFolder.id, 'work')).called(1);
      });

      test('should get all unique tags', () async {
        when(mockService.getAllTags()).thenReturn(['work', 'important', 'archive']);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final tags = notifier.getAllTags();

        expect(tags, containsAll(['work', 'important', 'archive']));
        verify(mockService.getAllTags()).called(1);
      });

      test('should filter folders by tags', () async {
        when(mockService.filterFoldersByTags(['work'])).thenReturn([rootFolder]);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final filteredFolders = notifier.getFoldersByTags(['work']);

        expect(filteredFolders, contains(rootFolder));
        verify(mockService.filterFoldersByTags(['work'])).called(1);
      });
    });

    group('Search and Filtering Operations', () {
      late ProviderContainer container;

      setUp(() async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder, childFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
        });

        container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );

        await container.read(documentOrganizationProvider.future);
      });

      tearDown(() {
        container.dispose();
      });

      test('should search folders by query', () async {
        when(mockService.searchFolders('work')).thenReturn([rootFolder]);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final searchResults = notifier.searchFolders('work');

        expect(searchResults, contains(rootFolder));
        expect(searchResults, hasLength(1));
        verify(mockService.searchFolders('work')).called(1);
      });

      test('should filter folders by date range', () async {
        final fromDate = testDate.subtract(const Duration(days: 1));
        final toDate = testDate.add(const Duration(days: 1));

        when(mockService.filterFoldersByDateRange(fromDate, toDate))
            .thenReturn([rootFolder, childFolder]);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final filteredFolders = notifier.filterFoldersByDateRange(fromDate, toDate);

        expect(filteredFolders, containsAll([rootFolder, childFolder]));
        verify(mockService.filterFoldersByDateRange(fromDate, toDate)).called(1);
      });
    });

    group('Folder Hierarchy Operations', () {
      late ProviderContainer container;

      setUp(() async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder, childFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
          when(mockService.getChildFolders(rootFolder.id)).thenReturn([childFolder]);
        });

        container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );

        await container.read(documentOrganizationProvider.future);
      });

      tearDown(() {
        container.dispose();
      });

      test('should get folder path correctly', () async {
        when(mockService.getFolderPath(childFolder.id)).thenReturn([rootFolder, childFolder]);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final path = notifier.getFolderPath(childFolder.id);

        expect(path, hasLength(2));
        expect(path.first.id, equals(rootFolder.id));
        expect(path.last.id, equals(childFolder.id));
        verify(mockService.getFolderPath(childFolder.id)).called(1);
      });

      test('should get folder breadcrumbs correctly', () async {
        when(mockService.getFolderBreadcrumbs(childFolder.id))
            .thenReturn(['Work Documents', 'Archive']);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final breadcrumbs = notifier.getFolderBreadcrumbs(childFolder.id);

        expect(breadcrumbs, equals(['Work Documents', 'Archive']));
        verify(mockService.getFolderBreadcrumbs(childFolder.id)).called(1);
      });

      test('should move folder successfully', () async {
        final movedFolder = childFolder.copyWith(parentId: null);

        when(mockService.moveFolder(childFolder.id, null)).thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([rootFolder, movedFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder, movedFolder]);
          return movedFolder;
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.moveFolder(childFolder.id, null);

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.rootFolders, hasLength(2));
        verify(mockService.moveFolder(childFolder.id, null)).called(1);
      });
    });

    group('Import/Export Operations', () {
      late ProviderContainer container;

      setUp(() async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
        });

        container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );

        await container.read(documentOrganizationProvider.future);
      });

      tearDown(() {
        container.dispose();
      });

      test('should export folders data correctly', () async {
        final exportData = {
          'folders': [rootFolder.toJson()],
          'version': 1,
          'lastUpdated': testDate.toIso8601String(),
        };

        when(mockService.exportFoldersData()).thenReturn(exportData);

        final notifier = container.read(documentOrganizationProvider.notifier);
        final result = notifier.exportFoldersData();

        expect(result, equals(exportData));
        expect(result['folders'], isA<List>());
        expect(result['version'], equals(1));
        verify(mockService.exportFoldersData()).called(1);
      });

      test('should import folders data correctly', () async {
        final importData = {
          'folders': [childFolder.toJson()],
          'version': 1,
          'lastUpdated': testDate.toIso8601String(),
        };

        when(mockService.importFoldersData(importData)).thenAnswer((_) async {
          when(mockService.getAllFolders()).thenReturn([rootFolder, childFolder]);
          when(mockService.getRootFolders()).thenReturn([rootFolder]);
        });

        final notifier = container.read(documentOrganizationProvider.notifier);
        await notifier.importFoldersData(importData);

        final state = container.read(documentOrganizationProvider).requireValue;
        expect(state.allFolders, hasLength(2));
        verify(mockService.importFoldersData(importData)).called(1);
      });
    });

    group('State Isolation and Provider Refresh', () {
      test('should provide isolated state between container instances', () async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder]);
        });

        final container1 = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );
        final container2 = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );

        addTearDown(() {
          container1.dispose();
          container2.dispose();
        });

        await container1.read(documentOrganizationProvider.future);
        await container2.read(documentOrganizationProvider.future);

        final state1 = container1.read(documentOrganizationProvider);
        final state2 = container2.read(documentOrganizationProvider);

        // States should be independent
        expect(identical(state1, state2), isFalse);
        expect(state1.value!.allFolders.length, equals(state2.value!.allFolders.length));
      });

      test('should refresh provider state', () async {
        when(mockService.initialize()).thenAnswer((_) async {
          when(mockService.isInitialized).thenReturn(true);
          when(mockService.getAllFolders()).thenReturn([rootFolder]);
        });

        final container = ProviderContainer.test(
          overrides: [
            documentOrganizationServiceProvider.overrideWithValue(mockService),
          ],
        );
        addTearDown(container.dispose);

        await container.read(documentOrganizationProvider.future);

        // Invalidate and refresh
        container.invalidate(documentOrganizationProvider);
        
        // Should re-initialize
        await container.read(documentOrganizationProvider.future);
        
        verify(mockService.initialize()).called(2); // Called twice due to invalidation
      });
    });
  });
}