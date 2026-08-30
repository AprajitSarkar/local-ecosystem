// lib/core/web/web_file_picker_stub.dart

class WebPickedFile {
  final String name;
  final int size;
  final Object? nativeHandle;

  WebPickedFile({
    required this.name,
    required this.size,
    this.nativeHandle,
  });
}

Future<List<WebPickedFile>> pickFilesWeb() async {
  return [];
}

Future<void> uploadFileWeb({
  required WebPickedFile file,
  required String uploadUrl,
  required String senderName,
  required void Function(double progress, double speedMBps, String status) onProgress,
}) async {
  throw UnsupportedError('uploadFileWeb is only supported on Web');
}
