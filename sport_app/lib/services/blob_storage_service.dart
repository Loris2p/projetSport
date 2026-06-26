abstract class BlobStorageService {
  Future<String> uploadBlob(String path, List<int> bytes);
}

class LocalMockBlobStorage implements BlobStorageService {
  @override
  Future<String> uploadBlob(String path, List<int> bytes) async {
    // Simuler le délai réseau
    await Future.delayed(const Duration(milliseconds: 800));
    return 'https://mockstorage.example.com/uploads/$path';
  }
}
