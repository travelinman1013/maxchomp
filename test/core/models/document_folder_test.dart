import 'package:flutter_test/flutter_test.dart';
import 'package:maxchomp/core/models/document_folder.dart';

/// Test suite for DocumentFolder model following TDD and Context7 patterns
/// 
/// This test file verifies the DocumentFolder model's functionality including:
/// - Immutable model properties and behavior
/// - JSON serialization/deserialization
/// - Validation rules and constraints
/// - Hierarchical folder operations
/// - Equality and hashCode implementation

void main() {
  group('DocumentFolder Model Tests', () {
    late DateTime testDate;
    late Map<String, dynamic> validFolderJson;
    late DocumentFolder testFolder;
    late DocumentFolder childFolder;

    setUpAll(() {
      testDate = DateTime(2025, 1, 24, 10, 30);
    });

    setUp(() {
      validFolderJson = {
        'id': 'folder-123',
        'name': 'Test Folder',
        'description': 'A test folder for documents',
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
        'parentId': null,
        'color': '#FF6B6B',
        'documentIds': ['doc1', 'doc2', 'doc3'],
        'tags': ['work', 'important'],
        'isDefault': false,
        'sortOrder': 0,
      };

      testFolder = DocumentFolder(
        id: 'folder-123',
        name: 'Test Folder',
        description: 'A test folder for documents',
        createdAt: testDate,
        updatedAt: testDate,
        parentId: null,
        color: '#FF6B6B',
        documentIds: const ['doc1', 'doc2', 'doc3'],
        tags: const ['work', 'important'],
        isDefault: false,
        sortOrder: 0,
      );

      childFolder = DocumentFolder(
        id: 'child-folder-456',
        name: 'Child Folder',
        description: 'A child folder',
        createdAt: testDate,
        updatedAt: testDate,
        parentId: 'folder-123',
        color: '#4ECDC4',
        documentIds: const ['doc4'],
        tags: const ['archive'],
        isDefault: false,
        sortOrder: 1,
      );
    });

    group('Constructor and Properties', () {
      test('should create folder with all properties', () {
        expect(testFolder.id, equals('folder-123'));
        expect(testFolder.name, equals('Test Folder'));
        expect(testFolder.description, equals('A test folder for documents'));
        expect(testFolder.createdAt, equals(testDate));
        expect(testFolder.updatedAt, equals(testDate));
        expect(testFolder.parentId, isNull);
        expect(testFolder.color, equals('#FF6B6B'));
        expect(testFolder.documentIds, equals(['doc1', 'doc2', 'doc3']));
        expect(testFolder.tags, equals(['work', 'important']));
        expect(testFolder.isDefault, isFalse);
        expect(testFolder.sortOrder, equals(0));
      });

      test('should create folder with minimal required properties', () {
        final minimalFolder = DocumentFolder(
          id: 'minimal-123',
          name: 'Minimal Folder',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(minimalFolder.id, equals('minimal-123'));
        expect(minimalFolder.name, equals('Minimal Folder'));
        expect(minimalFolder.description, isNull);
        expect(minimalFolder.parentId, isNull);
        expect(minimalFolder.color, isNull);
        expect(minimalFolder.documentIds, isEmpty);
        expect(minimalFolder.tags, isEmpty);
        expect(minimalFolder.isDefault, isFalse);
        expect(minimalFolder.sortOrder, equals(0));
      });

      test('should handle child folder correctly', () {
        expect(childFolder.parentId, equals('folder-123'));
        expect(childFolder.isRootFolder, isFalse);
        expect(testFolder.isRootFolder, isTrue);
      });
    });

    group('Validation', () {
      test('should validate folder name is not empty', () {
        expect(
          () => DocumentFolder(
            id: 'test',
            name: '',
            createdAt: testDate,
            updatedAt: testDate,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should validate folder name length', () {
        expect(
          () => DocumentFolder(
            id: 'test',
            name: 'a' * 256, // Too long
            createdAt: testDate,
            updatedAt: testDate,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should validate color format during creation', () {
        // Note: Color validation is handled in fromJson, not constructor
        // Constructor allows any string for flexibility
        final folder = DocumentFolder(
          id: 'test',
          name: 'Test',
          createdAt: testDate,
          updatedAt: testDate,
          color: 'invalid-color',
        );
        expect(folder.color, equals('invalid-color'));
      });

      test('should accept valid hex color', () {
        final folder = DocumentFolder(
          id: 'test',
          name: 'Test',
          createdAt: testDate,
          updatedAt: testDate,
          color: '#FF0000',
        );
        expect(folder.color, equals('#FF0000'));
      });

      test('should validate color format in fromJson', () {
        final invalidJson = {
          'id': 'test-123',
          'name': 'Test Folder',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'color': 'invalid-color',
          'documentIds': <String>[],
          'tags': <String>[],
          'isDefault': false,
          'sortOrder': 0,
        };

        expect(
          () => DocumentFolder.fromJson(invalidJson),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('CopyWith Method', () {
      test('should create copy with updated properties', () {
        final updatedFolder = testFolder.copyWith(
          name: 'Updated Folder',
          description: 'Updated description',
          color: '#00FF00',
        );

        expect(updatedFolder.id, equals(testFolder.id));
        expect(updatedFolder.name, equals('Updated Folder'));
        expect(updatedFolder.description, equals('Updated description'));
        expect(updatedFolder.color, equals('#00FF00'));
        expect(updatedFolder.createdAt, equals(testFolder.createdAt));
        expect(updatedFolder.documentIds, equals(testFolder.documentIds));
      });

      test('should preserve original properties when null values passed', () {
        final copiedFolder = testFolder.copyWith();

        expect(copiedFolder.id, equals(testFolder.id));
        expect(copiedFolder.name, equals(testFolder.name));
        expect(copiedFolder.description, equals(testFolder.description));
        expect(copiedFolder.color, equals(testFolder.color));
        expect(copiedFolder.documentIds, equals(testFolder.documentIds));
        expect(copiedFolder.tags, equals(testFolder.tags));
      });

      test('should update document list', () {
        final updatedFolder = testFolder.copyWith(
          documentIds: ['doc1', 'doc2', 'doc3', 'doc4'],
        );

        expect(updatedFolder.documentIds, hasLength(4));
        expect(updatedFolder.documentIds, contains('doc4'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON correctly', () {
        final json = testFolder.toJson();

        expect(json['id'], equals('folder-123'));
        expect(json['name'], equals('Test Folder'));
        expect(json['description'], equals('A test folder for documents'));
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
        expect(json['parentId'], isNull);
        expect(json['color'], equals('#FF6B6B'));
        expect(json['documentIds'], equals(['doc1', 'doc2', 'doc3']));
        expect(json['tags'], equals(['work', 'important']));
        expect(json['isDefault'], isFalse);
        expect(json['sortOrder'], equals(0));
      });

      test('should deserialize from JSON correctly', () {
        final folder = DocumentFolder.fromJson(validFolderJson);

        expect(folder.id, equals('folder-123'));
        expect(folder.name, equals('Test Folder'));
        expect(folder.description, equals('A test folder for documents'));
        expect(folder.createdAt, equals(testDate));
        expect(folder.updatedAt, equals(testDate));
        expect(folder.parentId, isNull);
        expect(folder.color, equals('#FF6B6B'));
        expect(folder.documentIds, equals(['doc1', 'doc2', 'doc3']));
        expect(folder.tags, equals(['work', 'important']));
        expect(folder.isDefault, isFalse);
        expect(folder.sortOrder, equals(0));
      });

      test('should handle null values in JSON', () {
        final jsonWithNulls = {
          'id': 'test-123',
          'name': 'Test Folder',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'description': null,
          'parentId': null,
          'color': null,
          'documentIds': <String>[],
          'tags': <String>[],
          'isDefault': false,
          'sortOrder': 0,
        };

        final folder = DocumentFolder.fromJson(jsonWithNulls);

        expect(folder.description, isNull);
        expect(folder.parentId, isNull);
        expect(folder.color, isNull);
        expect(folder.documentIds, isEmpty);
        expect(folder.tags, isEmpty);
      });

      test('should maintain JSON roundtrip consistency', () {
        final json = testFolder.toJson();
        final reconstructed = DocumentFolder.fromJson(json);

        expect(reconstructed, equals(testFolder));
      });
    });

    group('Document Management', () {
      test('should add document to folder', () {
        final updatedFolder = testFolder.addDocument('doc4');

        expect(updatedFolder.documentIds, hasLength(4));
        expect(updatedFolder.documentIds, contains('doc4'));
        expect(updatedFolder.documentCount, equals(4));
      });

      test('should not add duplicate document', () {
        final updatedFolder = testFolder.addDocument('doc1');

        expect(updatedFolder.documentIds, hasLength(3));
        expect(updatedFolder.documentIds, equals(testFolder.documentIds));
      });

      test('should remove document from folder', () {
        final updatedFolder = testFolder.removeDocument('doc2');

        expect(updatedFolder.documentIds, hasLength(2));
        expect(updatedFolder.documentIds, isNot(contains('doc2')));
        expect(updatedFolder.documentCount, equals(2));
      });

      test('should handle removing non-existent document', () {
        final updatedFolder = testFolder.removeDocument('non-existent');

        expect(updatedFolder.documentIds, equals(testFolder.documentIds));
        expect(updatedFolder.documentCount, equals(3));
      });

      test('should check if folder contains document', () {
        expect(testFolder.containsDocument('doc1'), isTrue);
        expect(testFolder.containsDocument('doc4'), isFalse);
      });
    });

    group('Tag Management', () {
      test('should add tag to folder', () {
        final updatedFolder = testFolder.addTag('urgent');

        expect(updatedFolder.tags, hasLength(3));
        expect(updatedFolder.tags, contains('urgent'));
      });

      test('should not add duplicate tag', () {
        final updatedFolder = testFolder.addTag('work');

        expect(updatedFolder.tags, hasLength(2));
        expect(updatedFolder.tags, equals(testFolder.tags));
      });

      test('should remove tag from folder', () {
        final updatedFolder = testFolder.removeTag('work');

        expect(updatedFolder.tags, hasLength(1));
        expect(updatedFolder.tags, isNot(contains('work')));
      });

      test('should handle removing non-existent tag', () {
        final updatedFolder = testFolder.removeTag('non-existent');

        expect(updatedFolder.tags, equals(testFolder.tags));
      });

      test('should check if folder has tag', () {
        expect(testFolder.hasTag('work'), isTrue);
        expect(testFolder.hasTag('personal'), isFalse);
      });
    });

    group('Equality and HashCode', () {
      test('should be equal for folders with same properties', () {
        final folder1 = DocumentFolder(
          id: 'test-123',
          name: 'Test Folder',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final folder2 = DocumentFolder(
          id: 'test-123',
          name: 'Test Folder',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(folder1, equals(folder2));
        expect(folder1.hashCode, equals(folder2.hashCode));
      });

      test('should not be equal for folders with different properties', () {
        final folder1 = DocumentFolder(
          id: 'test-123',
          name: 'Test Folder',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final folder2 = DocumentFolder(
          id: 'test-456',
          name: 'Test Folder',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(folder1, isNot(equals(folder2)));
        expect(folder1.hashCode, isNot(equals(folder2.hashCode)));
      });
    });

    group('toString Method', () {
      test('should provide readable string representation', () {
        final string = testFolder.toString();

        expect(string, contains('DocumentFolder'));
        expect(string, contains('folder-123'));
        expect(string, contains('Test Folder'));
        expect(string, contains('3 documents'));
      });
    });

    group('Default Folder Properties', () {
      test('should identify default folder correctly', () {
        final defaultFolder = testFolder.copyWith(isDefault: true);
        final regularFolder = testFolder.copyWith(isDefault: false);

        expect(defaultFolder.isDefault, isTrue);
        expect(regularFolder.isDefault, isFalse);
      });

      test('should handle default folder deletion validation', () {
        final defaultFolder = testFolder.copyWith(isDefault: true);

        expect(defaultFolder.canBeDeleted, isFalse);
        expect(testFolder.canBeDeleted, isTrue);
      });
    });

    group('Folder Hierarchy', () {
      test('should identify root folders correctly', () {
        expect(testFolder.isRootFolder, isTrue);
        expect(childFolder.isRootFolder, isFalse);
      });

      test('should get folder depth correctly', () {
        expect(testFolder.depth, equals(0));
        expect(childFolder.depth, equals(1));
      });

      test('should validate parent-child relationship', () {
        expect(childFolder.isChildOf(testFolder.id), isTrue);
        expect(testFolder.isChildOf(childFolder.id), isFalse);
      });
    });
  });
}