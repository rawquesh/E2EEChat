import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:asn1lib/asn1lib.dart';
import 'package:e2ee_android_app/backend/chats/chat_repository.dart';
import 'package:e2ee_models_app/configs/constants.dart';
import 'package:e2ee_models_app/utils/my_print.dart';
import 'package:e2ee_models_app/utils/storage_manager.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();

  factory EncryptionService() => _instance;

  EncryptionService._internal();

  final SecureStorageManager _secureStorage = SecureStorageManager();
  RSAPublicKey? _myPublicKey;
  RSAPrivateKey? _myPrivateKey;

  Map<String, String> _recipientPublicKeys = {};

  Future<void> init() async {
    final publicKeyPem = await _secureStorage.getString(MySharedPreferenceVariables.myPublicKey);
    final privateKeyPem = await _secureStorage.getString(MySharedPreferenceVariables.myPrivateKey);

    if (publicKeyPem != null && privateKeyPem != null) {
      _myPublicKey = _parsePublicKeyFromPem(publicKeyPem);
      _myPrivateKey = _parsePrivateKeyFromPem(privateKeyPem);
    } else {
      await _generateAndStoreKeys();
    }
    MyPrint.printOnConsole("XXEN EncryptionService initialized with public key: ${_myPublicKey?.modulus}");
  }

  Future<void> _generateAndStoreKeys() async {
    AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> keyPair = _generateRsaKeyPair();
    _myPublicKey = keyPair.publicKey;
    _myPrivateKey = keyPair.privateKey;

    await _secureStorage.setString(MySharedPreferenceVariables.myPublicKey, _encodePublicKeyToPem(_myPublicKey!));
    await _secureStorage.setString(MySharedPreferenceVariables.myPrivateKey, _encodePrivateKeyToPem(_myPrivateKey!));
  }

  // This method fetches the public key for a user, either from local storage or by making a network request .
  Future<String?> fetchPublicKey(String userId, String token) async {
    var localKey = _recipientPublicKeys.containsKey(userId) ? _recipientPublicKeys[userId] : await ChatRepository().fetchPublicKey(token: token, userId: userId);

    if (localKey != null) {
      _recipientPublicKeys[userId] = localKey;
    }

    MyPrint.printOnConsole("XXEN fetchPublicKey fn localKey: $localKey");
    return localKey;
  }

  Future<Map<String, dynamic>?> encryptPayload({required Map<String, dynamic> payload, required List<String> recipientIds, required String token}) async {
    if (recipientIds.isEmpty) {
      MyPrint.printOnConsole("XXEN Encryption failed: Recipient list is empty.");
      return null;
    }

    // 1. Encrypt the message content ONCE
    final aesKey = _generateRandomBytes(32);
    final iv = _generateRandomBytes(12);
    final payloadBytes = utf8.encode(jsonEncode(payload));
    final encryptedPayload = _aesGcmEncrypt(payloadBytes, aesKey, iv);

    // 2. Encrypt the AES key for EACH recipient in the list
    final Map<String, String> encryptedKeys = {};
    for (String userId in recipientIds) {
      final recipientPublicKeyPem = await fetchPublicKey(userId, token);
      if (recipientPublicKeyPem != null) {
        try {
          final recipientPublicKey = _parsePublicKeyFromPem(recipientPublicKeyPem);
          final encryptedAesKey = _rsaEncrypt(aesKey, recipientPublicKey);
          encryptedKeys[userId] = base64Encode(encryptedAesKey);
        } catch (e) {
          MyPrint.printOnConsole("Could not encrypt for user $userId due to invalid key. Skipping.");
        }
      } else {
        MyPrint.printOnConsole("XXEN Could not fetch public key for user: $userId. Skipping.");
      }
    }

    // If no keys could be encrypted, the message can't be sent securely.
    if (encryptedKeys.isEmpty) return null;

    // 3. Return the final payload
    return {'iv': base64Encode(iv), 'payload': base64Encode(encryptedPayload), 'keys': encryptedKeys};
  }

  /*Future<Map<String, dynamic>?> encryptPayload({required Map<String, dynamic> payload, required List<String> recipientIds, required String token}) async {
    if (recipientIds.isEmpty) {
      MyPrint.printOnConsole("XXEN Encryption failed: Recipient list is empty.");
      return null;
    }

    // 1. Encrypt the message content ONCE
    final aesKey = _generateRandomBytes(32);
    final iv = _generateRandomBytes(12);
    final payloadBytes = utf8.encode(jsonEncode(payload));
    final encryptedPayload = _aesGcmEncrypt(payloadBytes, aesKey, iv);

    // 2. Encrypt the AES key for EACH recipient in the list
    final Map<String, String> encryptedKeys = {};
    for (String userId in recipientIds) {
      final recipientPublicKeyPem = await fetchPublicKey(userId, token);
      if (recipientPublicKeyPem != null) {
        final recipientPublicKey = _parsePublicKeyFromPem(recipientPublicKeyPem);
        final encryptedAesKey = _rsaEncrypt(aesKey, recipientPublicKey);
        encryptedKeys[userId] = base64Encode(encryptedAesKey);
      } else {
        MyPrint.printOnConsole("XXEN Could not fetch public key for user: $userId. Skipping.");
      }
    }

    // If no keys could be encrypted, the message can't be sent securely.
    if (encryptedKeys.isEmpty) return null;

    // 3. Return the final payload
    return {'iv': base64Encode(iv), 'payload': base64Encode(encryptedPayload), 'keys': encryptedKeys};
  }*/

  Future<Map<String, dynamic>?> decryptMessagePayload({
    required Map<String, dynamic> encryptedData,
    required String myUserId, // The ID of the current user is now needed
  }) async {
    if (_myPrivateKey == null) await init();
    if (_myPrivateKey == null) {
      MyPrint.printOnConsole("XXEN Error: Private key not available for decryption.");
      return null;
    }

    try {
      String? encryptedAesKeyBase64;

      // Check if it's a group message or single message
      if (encryptedData.containsKey('keys')) {
        // GROUP CHAT: Find the key intended for me
        final keysMap = encryptedData['keys'] as Map<String, dynamic>;
        encryptedAesKeyBase64 = keysMap[myUserId];
      } else if (encryptedData.containsKey('key')) {
        // SINGLE CHAT: Use the single key
        encryptedAesKeyBase64 = encryptedData['key'];
      }

      if (encryptedAesKeyBase64 == null) {
        MyPrint.printOnConsole("XXEN Decryption failed: No encrypted key found for user $myUserId.");
        return null;
      }

      final encryptedAesKey = base64Decode(encryptedAesKeyBase64);
      final iv = base64Decode(encryptedData['iv']);
      final encryptedPayload = base64Decode(encryptedData['payload']);

      final aesKey = _rsaDecrypt(encryptedAesKey, _myPrivateKey!);
      final decryptedPayloadBytes = _aesGcmDecrypt(encryptedPayload, aesKey, iv);

      final payloadJson = utf8.decode(decryptedPayloadBytes);
      return jsonDecode(payloadJson) as Map<String, dynamic>;
    } catch (e) {
      MyPrint.printOnConsole("XXEN Decryption failed: $e");
      return null;
    }
  }

  // --- CRYPTOGRAPHIC HELPERS ---
  Uint8List _generateRandomBytes(int length) {
    final secureRandom = FortunaRandom();

    // Use Dart's built-in secure random number generator to create a 32-byte seed
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(256));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom.nextBytes(length);
  }

  // FIX: Explicitly cast the generated key pair to the required RSA types.
  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateRsaKeyPair() {
    final keyGen = RSAKeyGenerator()..init(ParametersWithRandom(RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64), FortunaRandom()..seed(KeyParameter(_generateRandomBytes(32)))));

    final keyPair = keyGen.generateKeyPair();

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(keyPair.publicKey as RSAPublicKey, keyPair.privateKey as RSAPrivateKey);
  }

  Uint8List _rsaEncrypt(Uint8List data, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding(RSAEngine())..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    return encryptor.process(data);
  }

  Uint8List _rsaDecrypt(Uint8List data, RSAPrivateKey privateKey) {
    final decryptor = OAEPEncoding(RSAEngine())..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    return decryptor.process(data);
  }

  Uint8List _aesGcmEncrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine())..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(data);
  }

  Uint8List _aesGcmDecrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final cipher = GCMBlockCipher(AESEngine())..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));
    return cipher.process(data);
  }

  // --- PEM ENCODING/DECODING HELPERS ---
  String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    // FIX: Use the ASN1ObjectIdentifier constructor directly.
    var algorithm = ASN1Sequence()
      ..add(ASN1ObjectIdentifier([1, 2, 840, 113549, 1, 1, 1])) // OID for rsaEncryption
      ..add(ASN1Null());
    var publicKeySequence = ASN1Sequence()
      ..add(ASN1Integer(publicKey.modulus!))
      ..add(ASN1Integer(publicKey.exponent!));
    var publicKeyBitString = ASN1BitString(publicKeySequence.encodedBytes);
    var topLevelSequence = ASN1Sequence()
      ..add(algorithm)
      ..add(publicKeyBitString);
    return """-----BEGIN PUBLIC KEY-----\n${base64.encode(topLevelSequence.encodedBytes)}\n-----END PUBLIC KEY-----""";
  }

  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    var privateKeySequence = ASN1Sequence()
      ..add(ASN1Integer(BigInt.from(0)))
      ..add(ASN1Integer(privateKey.n!))
      ..add(ASN1Integer(privateKey.exponent!))
      ..add(ASN1Integer(privateKey.privateExponent!))
      ..add(ASN1Integer(privateKey.p!))
      ..add(ASN1Integer(privateKey.q!))
      ..add(ASN1Integer(privateKey.privateExponent! % (privateKey.p! - BigInt.one)))
      ..add(ASN1Integer(privateKey.privateExponent! % (privateKey.q! - BigInt.one)))
      ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));
    return """-----BEGIN RSA PRIVATE KEY-----\n${base64.encode(privateKeySequence.encodedBytes)}\n-----END RSA PRIVATE KEY-----""";
  }

  /*RSAPublicKey _parsePublicKeyFromPem(String pem) {
    final bytes = base64.decode(pem.replaceAll(RegExp(r'-----(BEGIN|END) PUBLIC KEY-----|\n'), ''));
    var asn1Parser = ASN1Parser(bytes);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    var publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
    var publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes());
    var publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    var modulus = publicKeySeq.elements[0] as ASN1Integer;
    var exponent = publicKeySeq.elements[1] as ASN1Integer;
    return RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
  }
*/

  RSAPublicKey _parsePublicKeyFromPem(String pem) {
    if (!pem.startsWith('-----BEGIN PUBLIC KEY-----') || !pem.endsWith('-----END PUBLIC KEY-----')) {
      MyPrint.printOnConsole("Invalid PEM format for public key: $pem");
      throw Exception("Invalid PEM format");
    }

    final bytes = base64.decode(pem.replaceAll(RegExp(r'-----(BEGIN|END) PUBLIC KEY-----|\n'), ''));
    var asn1Parser = ASN1Parser(bytes);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    var publicKeyBitString = topLevelSeq.elements[1] as ASN1BitString;
    var publicKeyAsn = ASN1Parser(publicKeyBitString.contentBytes());
    var publicKeySeq = publicKeyAsn.nextObject() as ASN1Sequence;
    var modulus = publicKeySeq.elements[0] as ASN1Integer;
    var exponent = publicKeySeq.elements[1] as ASN1Integer;
    return RSAPublicKey(modulus.valueAsBigInteger, exponent.valueAsBigInteger);
  }

  RSAPrivateKey _parsePrivateKeyFromPem(String pem) {
    final bytes = base64.decode(pem.replaceAll(RegExp(r'-----(BEGIN|END) RSA PRIVATE KEY-----|\n'), ''));
    var asn1Parser = ASN1Parser(bytes);
    var topLevelSeq = asn1Parser.nextObject() as ASN1Sequence;
    return RSAPrivateKey(
      (topLevelSeq.elements[1] as ASN1Integer).valueAsBigInteger,
      (topLevelSeq.elements[3] as ASN1Integer).valueAsBigInteger,
      (topLevelSeq.elements[4] as ASN1Integer).valueAsBigInteger,
      (topLevelSeq.elements[5] as ASN1Integer).valueAsBigInteger,
    );
  }
}
