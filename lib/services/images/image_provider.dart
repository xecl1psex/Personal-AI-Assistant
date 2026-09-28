/// Placeholder for image generation / loading services.
///
/// Will later host avatars, AI-generated images and receipt photos.
/// Intentionally dependency-free for now (no image_picker / file IO yet).
class ImageProvider {
  ImageProvider._();

  static final ImageProvider instance = ImageProvider._();

  /// Returns a local filesystem path for storing images of [entity],
  /// e.g. 'avatars', 'receipts'.
  ///
  // TODO: реализация — использовать getApplicationDocumentsDirectory()
  // из path_provider (добавить зависимость позже).
  static String storageDirFor(String entity) {
    return 'images/$entity';
  }

  /// Load bytes of a stored image by [path].
  ///
  // TODO: реализация — чтение файла с диска.
  Future<List<int>?> loadImageBytes(String path) async {
    return null;
  }

  /// Save image [bytes] under [name] into [dir], returning the full path.
  ///
  // TODO: реализация — запись файла с диска.
  Future<String?> saveImage(
    List<int> bytes, {
    required String dir,
    required String name,
  }) async {
    return null;
  }

  /// Delete an image by [path].
  ///
  // TODO: реализация.
  Future<bool> deleteImage(String path) async {
    return false;
  }
}
