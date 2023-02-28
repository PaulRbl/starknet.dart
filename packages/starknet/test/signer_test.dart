import 'dart:convert';
import 'package:starknet/starknet.dart';
import 'package:test/test.dart';

class TestKeyPair {
  final Felt private;
  final Felt public;

  TestKeyPair(this.private, this.public);

  TestKeyPair.fromJson(Map<String, dynamic> json)
      : private = Felt.fromHexString(json['private']),
        public = Felt.fromHexString(json['public']);
}

void main() {
  group('Signer', () {
    group('signTransactions', () {
      test('returns the right signature for invoke transaction version 0', () {
        final signature = Signer(privateKey: Felt.fromInt(1234)).signTransactions(
            transactions: [
              FunctionCall(
                  contractAddress: Felt.fromHexString(
                      "0x033233531959c1da39c28daf337e25e2deadda80ce988290306ffabcd735ccbd"),
                  entryPointSelector: getSelectorByName("mint"),
                  calldata: [])
            ],
            contractAddress: Felt.fromIntString(
                "219128243976675829890319084714200810078954121337483207856443222019910998953"),
            version: 0,
            maxFee: Felt.fromInt(10000000000000000),
            chainId: StarknetChainId.testNet);
        expect(
            signature,
            equals([
              Felt.fromIntString(
                  "3058050571719369759412738987533864549850323224007431810241940044840783019940"),
              Felt.fromIntString(
                  "1900499411596333527352644243441454261068804171091393084934334076069283020499")
            ]));
      });
    });

    group('Public key', () {
      test('returns the correct public key for given a private key', () {
        final keyPairsJson = '''
[
  {
    "public": "0x7e52885445756b313ea16849145363ccb73fb4ab0440dbac333cf9d13de82b9",
    "private": "0xe3e70682c2094cac629f6fbed82c07cd"
  }, {
    "public": "0x175666e92f540a19eb24fa299ce04c23f3b75cb2d2332e3ff2021bf6d615fa5",
    "private": "0xf728b4fa42485e3a0a5d2f346baa9455"
  }, {
    "public": "0x58100ffde2b924de16520921f6bfe13a8bdde9d296a338b9469dd7370ade6cb",
    "private": "0xeb1167b367a9c3787c65c1e582e2e662"
  }, {
    "public": "0xff104dba23c3aec5eb7c74a4605c05ef81a29ac94621c71dd88907f196aa2b",
    "private": "0xf7c1bd874da5e709d4713d60c8a70639"
  }, {
    "public": "0x1f0eea3a599b1eec7e02053a2d9a2712efefc3f61265d4b3166c14ade4152d8",
    "private": "0xe443df789558867f5ba91faf7a024204"
  }, {
    "public": "0x5801376a836c9feb6941157bee10f24d942efa42d6d5e90fef25349c9471816",
    "private": "0x23a7711a8133287637ebdcd9e87a1613"
  }, {
    "public": "0x5a5a41e723be9e339b73a41bd1de92cde8fa4ebf9022ca951a92b0ac95a3c44",
    "private": "0x1846d424c17c627923c6612f48268673"
  }, {
    "public": "0x5f2aa391b1548fa0c5fb216fc7c424328ffb7d1c8e2a1ff614683cc31896ca3",
    "private": "0xfcbd04c340212ef7cca5a5a19e4d6e3c"
  }, {
    "public": "0x2c94f628d125cd0e86eaefea735ba24c262b9a441728f63e5776661829a4066",
    "private": "0xb4862b21fb97d43588561712e8e5216a"
  }, {
    "public": "0xc11e246b1d54515a26204d2d3c8586ea25ed9eecae00df173405974cb86dbc",
    "private": "0x259f4329e6f4590b9a164106cf6a659e"
  }, {
    "public": "0x04e633f0627b70c55eb53afdfd368c464f5767efe600e36157487bf988a2a106",
    "private": "0x079474858947854da7c14f19cb5d2edb39414d358a7da68b9436caff9dfb04a6"
  }
      ]
''';
        final keyPairs = List<TestKeyPair>.from(
            (json.decode(keyPairsJson) as List)
                .map((e) => TestKeyPair.fromJson(e)));
        for (var e in keyPairs) {
          final signer = Signer(privateKey: e.private);
          expect(signer.publicKey, equals(e.public));
        }
      });
    });
  }, tags: ['unit']);
}
