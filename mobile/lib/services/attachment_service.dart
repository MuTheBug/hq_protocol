import 'dart:io';
import 'dart:math' as math;

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// خدمة المرفقات: التقاط الصور (كاميرا/معرض) ونسخها لتخزين دائم داخل التطبيق.
///
/// تُخزَّن كل الصور في `<app-docs>/attachments/` ويُحفظ في حقول النموذج المسار
/// الكامل للملف. عند المزامنة تُرفع كأجزاء multipart منفصلة.
class AttachmentService {
  AttachmentService._();
  static final AttachmentService instance = AttachmentService._();

  final ImagePicker _picker = ImagePicker();
  Directory? _dir;
  final math.Random _rng = math.Random.secure();

  Future<Directory> _ensureDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final d = Directory(p.join(docs.path, 'attachments'));
    if (!await d.exists()) await d.create(recursive: true);
    _dir = d;
    return d;
  }

  String _token() {
    final ts = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final r = _rng.nextInt(1 << 32).toRadixString(36);
    return '$ts-$r';
  }

  Future<String?> takePhoto() async {
    final x = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 2000,
    );
    if (x == null) return null;
    return _saveLocal(File(x.path), suggestedExt: p.extension(x.path));
  }

  Future<String?> pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 2400,
    );
    if (x == null) return null;
    return _saveLocal(File(x.path), suggestedExt: p.extension(x.path));
  }

  Future<String> _saveLocal(File src, {String suggestedExt = '.jpg'}) async {
    final dir = await _ensureDir();
    final ext = suggestedExt.isEmpty ? '.jpg' : suggestedExt;
    final dest = File(p.join(dir.path, '${_token()}$ext'));
    await src.copy(dest.path);
    return dest.path;
  }

  /// حذف ملف مرفق محلي (يُستدعى عند استبدال الصورة أو حذف السجل).
  Future<void> tryDelete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  /// هل المسار صورة محلية موجودة فعلاً؟
  Future<bool> exists(String? path) async {
    if (path == null || path.isEmpty) return false;
    return File(path).exists();
  }
}
