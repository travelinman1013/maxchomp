import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:maxchomp/core/models/document_folder.dart';
import 'package:maxchomp/core/services/document_organization_service.dart';

// Generate mocks
@GenerateMocks([SharedPreferences])
import 'document_organization_service_test.mocks.dart';

/// Test suite for DocumentOrganizationService following TDD and Context7 patterns
/// 
/// This test file verifies the DocumentOrganizationService functionality including:
/// - CRUD operations for folders and tags
/// - Data persistence and retrieval
/// - Hierarchical folder management
/// - Error handling and validation
/// - Performance optimization for large datasets
/// 
/// Tests follow Context7 patterns with proper isolation and realistic mocking

void main() {
  group('DocumentOrganizationService Tests', () {
    late MockSharedPreferences mockPreferences;
    late DocumentOrganizationService service;
    late DateTime testDate;
    late DocumentFolder rootFolder;
    late DocumentFolder childFolder;
    late Map<String, dynamic> testFoldersJson;

    setUpAll(() {
      testDate = DateTime(2025, 1, 24, 10, 30);
    });

    setUp(() {
      mockPreferences = MockSharedPreferences();
      service = DocumentOrganizationService(mockPreferences);

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

      testFoldersJson = {
        'folders': [rootFolder.toJson(), childFolder.toJson()],
        'version': 1,
        'lastUpdated': testDate.toIso8601String(),
      };

      // Setup default mock behaviors
      when(mockPreferences.getString(any)).thenReturn(null);
      when(mockPreferences.setString(any, any)).thenAnswer((_) async => true);
      when(mockPreferences.remove(any)).thenAnswer((_) async => true);
      when(mockPreferences.containsKey(any)).thenReturn(false);
    });

    group('Initialization and Setup', () {
      test('should initialize service successfully', () {
        expect(service, isNotNull);
        expect(service.isInitialized, isFalse);
      });

      test('should initialize with default folder when no data exists', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);

        await service.initialize();

        expect(service.isInitialized, isTrue);
        expect(service.getAllFolders(), hasLength(1));
        expect(service.getAllFolders().first.name, equals('Documents'));
        expect(service.getAllFolders().first.isDefault, isTrue);
      });

      test('should load existing folders on initialization', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn('{"folders":[${json.encode(rootFolder.toJson())}],"version":1}');

        await service.initialize();

        expect(service.isInitialized, isTrue);
        final folders = service.getAllFolders();
        expect(folders, hasLength(1));
        expect(folders.first.name, equals(rootFolder.name));
        expect(folders.first.description, equals(rootFolder.description));
      });

      test('should handle corrupted data gracefully during initialization', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn('invalid-json');

        await service.initialize();

        expect(service.isInitialized, isTrue);
        // Should create a default "Documents" folder when data is corrupted
        expect(service.getRootFolders(), hasLength(1));
        expect(service.getRootFolders().first.name, equals('Documents'));
        expect(service.getRootFolders().first.isDefault, isTrue);
      });

      test('should create default Documents folder when initializing empty', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);

        await service.initialize();

        final rootFolders = service.getRootFolders();
        expect(rootFolders, hasLength(1));
        expect(rootFolders.first.name, equals('Documents'));
        expect(rootFolders.first.isDefault, isTrue);
        expect(rootFolders.first.parentId, isNull);
      });
    });

    group('Folder CRUD Operations', () {
      setUp(() async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();
      });

      test('should create new folder successfully', () async {
        final newFolder = await service.createFolder(
          name: 'New Folder',
          description: 'A test folder',
          parentId: null,
          color: '#00FF00',
          tags: const ['test'],
        );

        expect(newFolder, isNotNull);
        expect(newFolder.name, equals('New Folder'));
        expect(newFolder.description, equals('A test folder'));
        expect(newFolder.color, equals('#00FF00'));
        expect(newFolder.tags, contains('test'));
        expect(newFolder.id, isNotEmpty);
        expect(newFolder.createdAt, isNotNull);
        expect(newFolder.updatedAt, isNotNull);

        // Verify folder was added to service
        final allFolders = service.getAllFolders();
        expect(allFolders.any((f) => f.id == newFolder.id), isTrue);

        // Verify persistence was called properly (once during init for default folder, once for new folder)
        verify(mockPreferences.setString(
          DocumentOrganizationService.foldersKey,
          any,
        )).called(2);
      });

      test('should create child folder with valid parent', () async {
        // First create parent folder
        final parentFolder = await service.createFolder(
          name: 'Parent Folder',
          description: 'Parent folder',
        );

        // Then create child folder
        final childFolder = await service.createFolder(
          name: 'Child Folder',
          description: 'Child folder',
          parentId: parentFolder.id,
        );

        expect(childFolder.parentId, equals(parentFolder.id));
        expect(childFolder.isRootFolder, isFalse);
        expect(childFolder.isChildOf(parentFolder.id), isTrue);

        // Verify hierarchy
        final children = service.getChildFolders(parentFolder.id);
        expect(children, hasLength(1));
        expect(children.first.id, equals(childFolder.id));
      });

      test('should throw error when creating folder with invalid parent', () async {
        expect(
          () => service.createFolder(
            name: 'Test Folder',
            parentId: 'non-existent-parent',
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error when creating folder with duplicate name in same parent', () async {
        await service.createFolder(name: 'Duplicate Folder');

        expect(
          () => service.createFolder(name: 'Duplicate Folder'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should get folder by ID successfully', () async {
        final createdFolder = await service.createFolder(name: 'Test Folder');
        final retrievedFolder = service.getFolderById(createdFolder.id);

        expect(retrievedFolder, isNotNull);
        expect(retrievedFolder!.id, equals(createdFolder.id));
        expect(retrievedFolder.name, equals('Test Folder'));
      });

      test('should return null when getting non-existent folder', () {
        final folder = service.getFolderById('non-existent-id');
        expect(folder, isNull);
      });

      test('should update folder successfully', () async {
        final originalFolder = await service.createFolder(
          name: 'Original Name',
          description: 'Original description',
        );

        final updatedFolder = await service.updateFolder(
          originalFolder.id,
          name: 'Updated Name',
          description: 'Updated description',
          color: '#FF0000',
        );

        expect(updatedFolder, isNotNull);
        expect(updatedFolder!.id, equals(originalFolder.id));
        expect(updatedFolder.name, equals('Updated Name'));
        expect(updatedFolder.description, equals('Updated description'));
        expect(updatedFolder.color, equals('#FF0000'));
        expect(updatedFolder.updatedAt.isAfter(originalFolder.updatedAt), isTrue);

        // Verify persistence was called (init creates default folder, then create folder, then update)
        verify(mockPreferences.setString(
          DocumentOrganizationService.foldersKey,
          any,
        )).called(3); // Once for init default, once for create, once for update
      });

      test('should return null when updating non-existent folder', () async {
        final result = await service.updateFolder(
          'non-existent-id',
          name: 'New Name',
        );
        expect(result, isNull);
      });

      test('should delete folder successfully', () async {
        final folder = await service.createFolder(name: 'To Delete');
        final folderId = folder.id;

        final success = await service.deleteFolder(folderId);

        expect(success, isTrue);
        expect(service.getFolderById(folderId), isNull);

        // Verify persistence was called (init creates default folder, then create folder, then delete)
        verify(mockPreferences.setString(
          DocumentOrganizationService.foldersKey,
          any,
        )).called(3); // Once for init default, once for create, once for delete
      });

      test('should not delete default folder', () async {
        // Get the default "Documents" folder
        final defaultFolder = service.getRootFolders().first;
        expect(defaultFolder.isDefault, isTrue);

        expect(
          () => service.deleteFolder(defaultFolder.id),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should delete folder and all children recursively', () async {
        // Create parent folder
        final parent = await service.createFolder(name: 'Parent');
        
        // Create child folders
        final child1 = await service.createFolder(
          name: 'Child 1',
          parentId: parent.id,
        );
        final child2 = await service.createFolder(
          name: 'Child 2',
          parentId: parent.id,
        );
        
        // Create grandchild
        final grandchild = await service.createFolder(
          name: 'Grandchild',
          parentId: child1.id,
        );

        // Delete parent folder (should delete all children)
        final success = await service.deleteFolder(parent.id);

        expect(success, isTrue);
        expect(service.getFolderById(parent.id), isNull);
        expect(service.getFolderById(child1.id), isNull);
        expect(service.getFolderById(child2.id), isNull);
        expect(service.getFolderById(grandchild.id), isNull);
      });

      test('should return false when deleting non-existent folder', () async {
        final success = await service.deleteFolder('non-existent-id');
        expect(success, isFalse);
      });
    });

    group('Folder Hierarchy Operations', () {
      late DocumentFolder parentFolder;
      late DocumentFolder childFolder1;
      late DocumentFolder childFolder2;
      late DocumentFolder grandchildFolder;

      setUp(() async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();

        // Create folder hierarchy
        parentFolder = await service.createFolder(name: 'Parent');
        childFolder1 = await service.createFolder(
          name: 'Child 1',
          parentId: parentFolder.id,
        );
        childFolder2 = await service.createFolder(
          name: 'Child 2',
          parentId: parentFolder.id,
        );
        grandchildFolder = await service.createFolder(
          name: 'Grandchild',
          parentId: childFolder1.id,
        );
      });

      test('should get root folders correctly', () {
        final rootFolders = service.getRootFolders();
        
        // Should include default "Documents" folder and our parent folder
        expect(rootFolders, hasLength(2));
        expect(rootFolders.any((f) => f.id == parentFolder.id), isTrue);
        expect(rootFolders.any((f) => f.isDefault), isTrue);
      });

      test('should get child folders correctly', () {
        final children = service.getChildFolders(parentFolder.id);
        
        expect(children, hasLength(2));
        expect(children.any((f) => f.id == childFolder1.id), isTrue);
        expect(children.any((f) => f.id == childFolder2.id), isTrue);
      });

      test('should get folder path correctly', () {
        final path = service.getFolderPath(grandchildFolder.id);
        
        expect(path, hasLength(3)); // parent -> child1 -> grandchild
        expect(path[0].id, equals(parentFolder.id));
        expect(path[1].id, equals(childFolder1.id));
        expect(path[2].id, equals(grandchildFolder.id));
      });

      test('should get folder breadcrumbs correctly', () {
        final breadcrumbs = service.getFolderBreadcrumbs(grandchildFolder.id);
        
        expect(breadcrumbs, hasLength(3));
        expect(breadcrumbs[0], equals('Parent'));
        expect(breadcrumbs[1], equals('Child 1'));
        expect(breadcrumbs[2], equals('Grandchild'));
      });

      test('should move folder to new parent successfully', () async {
        final movedFolder = await service.moveFolder(
          grandchildFolder.id,
          childFolder2.id,
        );

        expect(movedFolder, isNotNull);
        expect(movedFolder!.parentId, equals(childFolder2.id));

        // Verify old parent no longer has the folder
        final oldParentChildren = service.getChildFolders(childFolder1.id);
        expect(oldParentChildren, isEmpty);

        // Verify new parent has the folder
        final newParentChildren = service.getChildFolders(childFolder2.id);
        expect(newParentChildren, hasLength(1));
        expect(newParentChildren.first.id, equals(grandchildFolder.id));
      });

      test('should not allow moving folder to its own child', () async {
        expect(
          () => service.moveFolder(parentFolder.id, childFolder1.id),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Document Association', () {
      late DocumentFolder testFolder;

      setUp(() async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();
        testFolder = await service.createFolder(name: 'Test Folder');
      });

      test('should add document to folder successfully', () async {
        final updatedFolder = await service.addDocumentToFolder(
          testFolder.id,
          'document-123',
        );

        expect(updatedFolder, isNotNull);
        expect(updatedFolder!.documentIds, contains('document-123'));
        expect(updatedFolder.documentCount, equals(1));
      });

      test('should not add duplicate document to folder', () async {
        // Add document first time
        await service.addDocumentToFolder(testFolder.id, 'document-123');
        
        // Try to add same document again
        final updatedFolder = await service.addDocumentToFolder(
          testFolder.id,
          'document-123',
        );

        expect(updatedFolder!.documentIds, hasLength(1));
        expect(updatedFolder.documentCount, equals(1));
      });

      test('should remove document from folder successfully', () async {
        // Add document first
        await service.addDocumentToFolder(testFolder.id, 'document-123');
        
        // Then remove it
        final updatedFolder = await service.removeDocumentFromFolder(
          testFolder.id,
          'document-123',
        );

        expect(updatedFolder, isNotNull);
        expect(updatedFolder!.documentIds, isNot(contains('document-123')));
        expect(updatedFolder.documentCount, equals(0));
      });

      test('should get folders containing document', () async {
        // Add document to multiple folders
        await service.addDocumentToFolder(testFolder.id, 'document-123');
        
        final anotherFolder = await service.createFolder(name: 'Another Folder');
        await service.addDocumentToFolder(anotherFolder.id, 'document-123');

        final foldersWithDocument = service.getFoldersContainingDocument('document-123');

        expect(foldersWithDocument, hasLength(2));
        expect(foldersWithDocument.any((f) => f.id == testFolder.id), isTrue);
        expect(foldersWithDocument.any((f) => f.id == anotherFolder.id), isTrue);
      });

      test('should move document between folders successfully', () async {
        // Add document to first folder
        await service.addDocumentToFolder(testFolder.id, 'document-123');
        
        // Create second folder and move document there
        final targetFolder = await service.createFolder(name: 'Target Folder');
        await service.moveDocumentToFolder(
          'document-123',
          testFolder.id,
          targetFolder.id,
        );

        // Verify document was moved
        final sourceFolder = service.getFolderById(testFolder.id);
        final destFolder = service.getFolderById(targetFolder.id);

        expect(sourceFolder!.documentIds, isNot(contains('document-123')));
        expect(destFolder!.documentIds, contains('document-123'));
      });
    });

    group('Tag Management', () {
      late DocumentFolder testFolder;

      setUp(() async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();
        testFolder = await service.createFolder(
          name: 'Test Folder',
          tags: const ['initial-tag'],
        );
      });

      test('should add tag to folder successfully', () async {
        final updatedFolder = await service.addTagToFolder(
          testFolder.id,
          'new-tag',
        );

        expect(updatedFolder, isNotNull);
        expect(updatedFolder!.tags, contains('new-tag'));
        expect(updatedFolder.tags, contains('initial-tag'));
        expect(updatedFolder.tags, hasLength(2));
      });

      test('should not add duplicate tag to folder', () async {
        final updatedFolder = await service.addTagToFolder(
          testFolder.id,
          'initial-tag',
        );

        expect(updatedFolder!.tags, hasLength(1));
        expect(updatedFolder.tags, contains('initial-tag'));
      });

      test('should remove tag from folder successfully', () async {
        final updatedFolder = await service.removeTagFromFolder(
          testFolder.id,
          'initial-tag',
        );

        expect(updatedFolder, isNotNull);
        expect(updatedFolder!.tags, isNot(contains('initial-tag')));
        expect(updatedFolder.tags, isEmpty);
      });

      test('should get all unique tags across folders', () async {
        // Create folders with different tags
        await service.createFolder(name: 'Folder 1', tags: const ['work', 'important']);
        await service.createFolder(name: 'Folder 2', tags: const ['personal', 'work']);
        await service.createFolder(name: 'Folder 3', tags: const ['archive']);

        final allTags = service.getAllTags();

        expect(allTags, hasLength(5));
        expect(allTags, containsAll(['work', 'important', 'personal', 'archive', 'initial-tag']));
      });

      test('should get folders by tag', () async {
        // Create folders with specific tags
        final workFolder1 = await service.createFolder(
          name: 'Work Folder 1',
          tags: const ['work', 'important'],
        );
        final workFolder2 = await service.createFolder(
          name: 'Work Folder 2',
          tags: const ['work'],
        );
        await service.createFolder(
          name: 'Personal Folder',
          tags: const ['personal'],
        );

        final workFolders = service.getFoldersByTag('work');

        expect(workFolders, hasLength(2));
        expect(workFolders.any((f) => f.id == workFolder1.id), isTrue);
        expect(workFolders.any((f) => f.id == workFolder2.id), isTrue);
      });
    });

    group('Search and Filtering', () {
      setUp(() async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();

        // Create test folders with different properties
        await service.createFolder(
          name: 'Work Documents',
          description: 'Documents for work projects',
          tags: const ['work', 'important'],
        );
        await service.createFolder(
          name: 'Personal Files',
          description: 'Personal documents and files',
          tags: const ['personal'],
        );
        await service.createFolder(
          name: 'Archive',
          description: 'Archived work documents',
          tags: const ['work', 'archive'],
        );
      });

      test('should search folders by name successfully', () {
        final results = service.searchFolders('work');
        
        expect(results, hasLength(2)); // "Work Documents" and "Archive" (contains "work")
        expect(results.any((f) => f.name.contains('Work')), isTrue);
        expect(results.any((f) => f.description!.contains('work')), isTrue);
      });

      test('should search folders case-insensitively', () {
        final results = service.searchFolders('WORK');
        
        expect(results, hasLength(2));
      });

      test('should search folders by description', () {
        final results = service.searchFolders('personal');
        
        expect(results, hasLength(1));
        expect(results.first.name, equals('Personal Files'));
      });

      test('should filter folders by multiple tags', () {
        final results = service.filterFoldersByTags(['work', 'important']);
        
        expect(results, hasLength(1));
        expect(results.first.name, equals('Work Documents'));
      });

      test('should filter folders by date range', () {
        final fromDate = DateTime.now().subtract(const Duration(days: 1));
        final toDate = DateTime.now().add(const Duration(days: 1));
        
        final results = service.filterFoldersByDateRange(fromDate, toDate);
        
        // Should include the folders created during test setup + default folder
        expect(results.length, greaterThanOrEqualTo(3)); // At least 3 folders
      });
    });

    group('Performance and Error Handling', () {
      test('should handle large number of folders efficiently', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();

        const folderCount = 1000;
        final stopwatch = Stopwatch()..start();

        // Create many folders
        for (int i = 0; i < folderCount; i++) {
          await service.createFolder(name: 'Folder $i');
        }

        stopwatch.stop();
        
        // Should complete within reasonable time (adjust threshold as needed)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // 5 seconds
        expect(service.getAllFolders(), hasLength(folderCount + 1)); // +1 for default folder
      });

      test('should handle persistence failures gracefully', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();

        // Mock setString to return false (failure)
        when(mockPreferences.setString(any, any))
            .thenAnswer((_) async => false);

        expect(
          () => service.createFolder(name: 'Test Folder'),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate folder names properly', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();

        // Test empty name
        expect(
          () => service.createFolder(name: ''),
          throwsA(isA<ArgumentError>()),
        );

        // Test name too long
        expect(
          () => service.createFolder(name: 'a' * 256),
          throwsA(isA<ArgumentError>()),
        );

        // Test name with only whitespace
        expect(
          () => service.createFolder(name: '   '),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Data Migration and Versioning', () {
      test('should handle version migration gracefully', () async {
        // Mock old version data structure
        final oldVersionData = {
          'folders': [rootFolder.toJson()],
          'version': 0, // Old version
        };

        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(oldVersionData.toString());

        await service.initialize();

        expect(service.isInitialized, isTrue);
        // Should still work with old data format
        expect(service.getAllFolders(), isNotEmpty);
      });

      test('should export folders data correctly', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();

        await service.createFolder(name: 'Test Folder');
        
        final exportData = service.exportFoldersData();
        
        expect(exportData, isNotNull);
        expect(exportData['folders'], isA<List>());
        expect(exportData['version'], isA<int>());
        expect(exportData['lastUpdated'], isA<String>());
      });

      test('should import folders data correctly', () async {
        when(mockPreferences.getString(DocumentOrganizationService.foldersKey))
            .thenReturn(null);
        await service.initialize();

        final importData = {
          'folders': [rootFolder.toJson()],
          'version': 1,
          'lastUpdated': testDate.toIso8601String(),
        };

        await service.importFoldersData(importData);

        final folders = service.getAllFolders();
        expect(folders.any((f) => f.id == rootFolder.id), isTrue);
      });
    });
  });
}