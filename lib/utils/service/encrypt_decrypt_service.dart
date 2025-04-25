import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptDecryptService {
  final encrypt.Key _key;
  late final encrypt.Encrypter _encrypter;

  EncryptDecryptService()
      : _key = encrypt.Key.fromUtf8('my32lengthsupersecretnooneknows1') {
    _encrypter = encrypt.Encrypter(encrypt.AES(_key));
  }

  String encryptData(String plainText) {
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypted = _encrypter.encrypt(plainText, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  String decryptData(String encryptedText) {
    final parts = encryptedText.split(':');
    if (parts.length != 2) throw FormatException('Invalid encrypted format');
    final iv = encrypt.IV.fromBase64(parts[0]);
    final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
    return _encrypter.decrypt(encrypted, iv: iv);
  }
}
