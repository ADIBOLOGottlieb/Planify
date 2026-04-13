import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ReceiptService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickAndSaveReceipt() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory('${dir.path}/receipts');
    if (!await receiptsDir.exists()) {
      await receiptsDir.create(recursive: true);
    }

    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = await File(picked.path).copy('${receiptsDir.path}/$fileName');
    return saved.path;
  }
}
