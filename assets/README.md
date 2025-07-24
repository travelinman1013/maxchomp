# MaxChomp Assets

This directory contains sample assets for testing and development of the MaxChomp PDF-to-audio application.

## Sample PDFs

### `quick_test.pdf` (3.0 KB)
- **Purpose**: Short test document for rapid testing cycles
- **Content**: Basic app introduction with technical terms and various formats
- **Duration**: ~2-3 minutes when read aloud
- **Use Case**: Quick functionality testing, pronunciation testing

### `flutter_basics.pdf` (4.9 KB)
- **Purpose**: Medium-length technical document
- **Content**: Introduction to Flutter development concepts
- **Duration**: ~5-7 minutes when read aloud
- **Use Case**: Testing text extraction, longer audio sessions, technical pronunciation

### `multilingual_sample.pdf` (3.7 KB)
- **Purpose**: Multi-language testing document
- **Content**: Programming terms and descriptions in English, Spanish, French, and German
- **Duration**: ~4-5 minutes when read aloud
- **Use Case**: Voice selection testing, multi-language TTS capabilities

## Usage in Development

These PDFs are automatically included in the app bundle via the `pubspec.yaml` assets configuration:

```yaml
flutter:
  assets:
    - assets/pdfs/
    - assets/images/
```

### Testing Scenarios

1. **Quick Testing**: Use `quick_test.pdf` for rapid iteration during development
2. **Performance Testing**: Use `flutter_basics.pdf` for testing larger document handling
3. **Voice Testing**: Use `multilingual_sample.pdf` to test different TTS voices and languages
4. **User Flow Testing**: Test complete import → extraction → playback flow with any of these documents

### File Characteristics

- **Format**: Standard PDF with selectable text
- **Encoding**: UTF-8 text content
- **Layout**: Simple text layout optimized for text extraction
- **Size Range**: 3-5 KB (small files for efficient testing)

## Adding More Test PDFs

To add additional test PDFs:

1. Place PDF files in this directory
2. Ensure they're under 10 MB for mobile app efficiency
3. Test with various content types (technical, narrative, etc.)
4. Consider different languages for TTS voice testing

## Notes

- All PDFs contain original content created specifically for MaxChomp testing
- Content is designed to test various aspects of PDF-to-speech conversion
- Files are optimized for mobile app bundle size while providing comprehensive testing coverage

*Last Updated: 2025-07-23*