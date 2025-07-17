import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyManager {
  static final algorithm = Ed25519();
  static final storage = FlutterSecureStorage();

  static Future<Map<String, dynamic>> generateAndStoreKeys() async {
    // 1. Identity KeyPair
    final identityKeyPair = await algorithm.newKeyPair();
    final identityPublic = await identityKeyPair.extractPublicKey();

    // 2. Signed PreKey
    final signedPreKeyPair = await algorithm.newKeyPair();
    final signedPreKeyPublic = await signedPreKeyPair.extractPublicKey();

    // 3. Signature (signedPreKey signed with identityKey)
    final signature = await algorithm.sign(
      signedPreKeyPublic.bytes,
      keyPair: identityKeyPair,
    );

    // 4. One-Time PreKeys
    List<SimplePublicKey> oneTimePreKeys = [];
    for (int i = 0; i < 10; i++) {
      final kp = await algorithm.newKeyPair();
      oneTimePreKeys.add(await kp.extractPublicKey());
      // Store private part securely
      await storage.write(
        key: 'oneTimePreKeyPrivate_$i',
        value: base64Encode(await kp.extractPrivateKeyBytes()),
      );
    }

    // Store private keys securely
    await storage.write(
        key: 'identityPrivateKey',
        value: base64Encode(await identityKeyPair.extractPrivateKeyBytes()));
    await storage.write(
        key: 'signedPreKeyPrivate',
        value: base64Encode(await signedPreKeyPair.extractPrivateKeyBytes()));

    return {
      "identity_public_key": base64Encode(identityPublic.bytes),
      "signed_prekey": base64Encode(signedPreKeyPublic.bytes),
      "prekey_signature": base64Encode(signature.bytes),
      "onetime_prekeys": oneTimePreKeys.map((k) => base64Encode(k.bytes)).toList(),
    };
  }
}