import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class PasswordDigest {
  const PasswordDigest({
    required this.algorithm,
    required this.salt,
    required this.hash,
    required this.memory,
    required this.iterations,
    required this.parallelism,
  });

  final String algorithm;
  final String salt;
  final String hash;
  final int memory;
  final int iterations;
  final int parallelism;
}

class PasswordHasher {
  PasswordHasher({
    this.memory = 19 * 1024,
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
    Random? random,
  }) : _random = random ?? Random.secure();

  final int memory;
  final int iterations;
  final int parallelism;
  final int hashLength;
  final Random _random;

  Future<PasswordDigest> hash(String password) async {
    final salt = _randomBytes(16);
    final bytes = await _derive(
      password: password,
      salt: salt,
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: hashLength,
    );
    return PasswordDigest(
      algorithm: 'argon2id',
      salt: base64Encode(salt),
      hash: base64Encode(bytes),
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
    );
  }

  Future<bool> verify(String password, PasswordDigest digest) async {
    if (digest.algorithm != 'argon2id') return false;
    final expected = base64Decode(digest.hash);
    final actual = await _derive(
      password: password,
      salt: base64Decode(digest.salt),
      memory: digest.memory,
      iterations: digest.iterations,
      parallelism: digest.parallelism,
      hashLength: expected.length,
    );
    return _constantTimeEquals(expected, actual);
  }

  Future<List<int>> _derive({
    required String password,
    required List<int> salt,
    required int memory,
    required int iterations,
    required int parallelism,
    required int hashLength,
  }) async {
    final algorithm = Argon2id(
      memory: memory,
      iterations: iterations,
      parallelism: parallelism,
      hashLength: hashLength,
    );
    final key = await algorithm.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    return key.extractBytes();
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}

class SecureTokenService {
  SecureTokenService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  String newId() => _hex(_randomBytes(16));

  String newToken() {
    return base64UrlEncode(_randomBytes(32)).replaceAll('=', '');
  }

  Future<String> hashToken(String token) async {
    final hash = await Sha256().hash(utf8.encode(token));
    return base64UrlEncode(hash.bytes).replaceAll('=', '');
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  String _hex(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  }
}
