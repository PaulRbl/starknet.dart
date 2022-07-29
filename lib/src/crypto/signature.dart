import 'dart:typed_data';
import 'package:crypto/crypto.dart' as crypto;
import 'package:starknet/starknet.dart';

const nbFieldPrimeBits = 251;
final maxHash = BigInt.two.pow(nbFieldPrimeBits);
final seed = 1;

class Signature {
  final BigInt r;
  final BigInt s;
  Signature(this.r, this.s);
}

/// Signs a message hash using the given private key according to Starknet specs.
///
/// Spec: https://github.com/starkware-libs/cairo-lang/blob/13cef109cd811474de114925ee61fd5ac84a25eb/src/starkware/crypto/starkware/crypto/signature/signature.py#L135-L171
Signature starknet_sign(BigInt privateKey, BigInt messageHash) {
  assert(messageHash >= BigInt.zero && messageHash < maxHash);

  while (true) {
    final k = starknet_generateK(privateKey, messageHash);

    final x = (generatorPoint * k)!.x;

    final BigInt r = x?.toBigInteger() as BigInt;
    if (!(r >= BigInt.one && r < maxHash)) {
      continue;
    }

    final t = messageHash + r * privateKey;
    if (t % pedersenParams.ecOrder == BigInt.zero) {
      continue;
    }

    final w =
        (k * t.modInverse(pedersenParams.ecOrder)) % pedersenParams.ecOrder;
    if (!(w >= BigInt.one && w < maxHash)) {
      continue;
    }

    final s = w.modInverse(pedersenParams.ecOrder);

    return Signature(r, s);
  }
}

/// Generates a k value according to Starknet specs.
///
/// Spec: https://github.com/starkware-libs/cairo-lang/blob/13cef109cd811474de114925ee61fd5ac84a25eb/src/starkware/crypto/starkware/crypto/signature/signature.py#L115-L132
BigInt starknet_generateK(BigInt privateKey, BigInt messageHash) {
  // Pad the message hash, for consistency with the elliptic.js library.
  final bytesLength = messageHash.bitLength % 8;
  if (bytesLength >= 1 && bytesLength <= 4 && messageHash.bitLength >= 248) {
    messageHash *= BigInt.from(16);
  }

  return generateK(pedersenParams.ecOrder, privateKey, crypto.sha256,
      bigIntToBytes(messageHash));
}

/// Generates a k value, the nonce for DSA.
///
/// Spec: https://tools.ietf.org/html/rfc6979#section-3.2
BigInt generateK(
    BigInt order, BigInt privateKey, crypto.Hash hashFunction, List<int> data) {
  final qlen = order.bitLength;
  final holen = 32; // digest length is 256 bits for sha256
  final rolen = orderlen(order);
  var bx = numberToString(privateKey, order) + bits2Octets(data, order);

  // Step B
  var v = List<int>.filled(holen, 0x01);

  // Step C
  var k = List<int>.filled(holen, 0x00);

  // Step D
  k = crypto.Hmac(hashFunction, k).convert(v + [0x00] + bx).bytes;

  // Step E
  v = crypto.Hmac(hashFunction, k).convert(v).bytes;

  // Step F
  k = crypto.Hmac(hashFunction, k).convert(v + [0x01] + bx).bytes;

  // Step G
  v = crypto.Hmac(hashFunction, k).convert(v).bytes;

  while (true) {
    // Step H1
    var t = <int>[];

    // Step H2
    while (t.length < rolen) {
      v = crypto.Hmac(hashFunction, k).convert(v).bytes;
      t = t + v;
    }

    // Step H3
    var secret = bits2Int(t, qlen);

    if (secret >= BigInt.one && secret < order) {
      return secret;
    }

    k = crypto.Hmac(hashFunction, k).convert(v + [0x00]).bytes;
    v = crypto.Hmac(hashFunction, k).convert(v).bytes;
  }
}

// https://tools.ietf.org/html/rfc6979#section-2.3.4
List<int> bits2Octets(List<int> data, BigInt order) {
  var z1 = bits2Int(data, order.bitLength);
  var z2 = z1 - order;

  if (z2 < BigInt.zero) {
    z2 = z1;
  }

  return numberToString(z2, order);
}

BigInt bits2Int(List<int> data, int qlen) {
  var x = bytesToBigInt(data);
  var l = data.length * 8;

  if (l > qlen) {
    return x >> (l - qlen);
  }
  return x;
}

List<int> numberToString(BigInt v, BigInt order) {
  var l = orderlen(order);

  var vBytes = bigIntToBytes(v);
  vBytes =
      Uint8List.fromList([...List.filled(l - vBytes.length, 0x00), ...vBytes]);

  return vBytes;
}

orderlen(BigInt order) {
  return (order.bitLength + 7) ~/ 8;
}
