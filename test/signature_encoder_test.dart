import 'package:test/test.dart';
import 'package:wdk_safe_relay_kit_flutter/src/encoding/signature_encoder.dart';

void main() {
  group('encodeSafe4337Signature', () {
    test('encodes validAfter and validUntil as first 12 bytes', () {
      final result = encodeSafe4337Signature(
        sortedOwners: [],
        signatures: {},
      );
      expect(result, startsWith('0x'));
      expect(result.length, 2 + 12 * 2); // 0x + 12 hex bytes
    });

    test('encodes one 65-byte signature in owner order', () {
      const owner = '0x0000000000000000000000000000000000000001';
      final sig65 =
          '0x${List.filled(130, 'a').join()}'; // 65 bytes = 130 hex chars
      final result = encodeSafe4337Signature(
        sortedOwners: [owner],
        signatures: {owner: sig65},
      );
      expect(result, startsWith('0x'));
      expect(result.length, 2 + 12 * 2 + 65 * 2); // 0x + 12 + 65 bytes
    });

    test('encodes two owners in sorted order', () {
      const a = '0x0000000000000000000000000000000000000001';
      const b = '0x0000000000000000000000000000000000000002';
      final sig = '0x${List.filled(130, 'b').join()}';
      final result = encodeSafe4337Signature(
        sortedOwners: [a, b],
        signatures: {a: sig, b: sig},
      );
      expect(result.length, 2 + 12 * 2 + 65 * 2 * 2);
    });

    test('uses lowercase key for signature lookup', () {
      const owner = '0xAbCdEf0000000000000000000000000000000001';
      final sig = '0x${List.filled(130, 'c').join()}';
      final result = encodeSafe4337Signature(
        sortedOwners: [owner.toLowerCase()],
        signatures: {owner: sig},
      );
      expect(result.length, 2 + 12 * 2 + 65 * 2);
    });

    test('skips owners without signature', () {
      const a = '0x0000000000000000000000000000000000000001';
      const b = '0x0000000000000000000000000000000000000002';
      final sig = '0x${List.filled(130, 'd').join()}';
      final result = encodeSafe4337Signature(
        sortedOwners: [a, b],
        signatures: {a: sig},
      );
      expect(result.length, 2 + 12 * 2 + 65 * 2); // only one sig
    });

    test('accepts 64-byte compact signature', () {
      const owner = '0x0000000000000000000000000000000000000001';
      final sig64 = '0x${List.filled(128, 'e').join()}';
      final result = encodeSafe4337Signature(
        sortedOwners: [owner],
        signatures: {owner: sig64},
      );
      expect(result.length, 2 + 12 * 2 + 65 * 2);
    });

    test('throws on invalid signature length', () {
      expect(
        () => encodeSafe4337Signature(
          sortedOwners: ['0x0000000000000000000000000000000000000001'],
          signatures: {
            '0x0000000000000000000000000000000000000001': '0x1234',
          },
        ),
        throwsArgumentError,
      );
    });
  });
}
