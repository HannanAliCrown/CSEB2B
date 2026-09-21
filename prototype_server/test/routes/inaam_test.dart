import 'package:prototype_server/data/inaam_data_store.dart';
import 'package:prototype_server/router.dart';
import 'package:test/test.dart';

import '../support/fake_auth_data_store.dart';
import '../support/fake_inaam_data_store.dart';
import '../support/request_helpers.dart';

void main() {
  late FakeInaamDataStore inaam;
  late FakeAuthDataStore auth;

  const adnan = '3004821190';
  const stranger = '3009999999';

  ItemSchemeRow scheme({required int progress, String measure = 'scans'}) =>
      ItemSchemeRow(
        id: 'scheme1',
        name: 'Inverter Scan Scheme',
        measure: measure,
        progress: progress,
        startsOn: DateTime.utc(2026, 7),
        endsOn: DateTime.utc(2026, 12, 31),
        tiers: [
          SchemeTierRow(
            id: 'silver',
            name: 'Silver',
            threshold: 150,
            rewardPaisa: 1400000,
            reached: progress >= 150,
          ),
          SchemeTierRow(
            id: 'gold',
            name: 'Gold',
            threshold: 300,
            rewardPaisa: 2500000,
            reached: progress >= 300,
          ),
        ],
      );

  setUp(() {
    inaam = FakeInaamDataStore();
    auth = FakeAuthDataStore();
    inaam.addAccount(mobileNumber: adnan);
  });

  dynamic router() => buildRouter(auth, inaam: inaam);

  group('the wheel', () {
    test('counts the entitlement from today\'s scans', () async {
      inaam.scanned(adnan, 24);

      final body =
          (await getJson(router(), '/inaam/spin?mobileNumber=$adnan'))['body']
              as Map;

      expect(body['scansToday'], 24);
      expect(body['spinsAvailable'], 2);
      expect(body['scansToNextSpin'], 6);
    });

    test('sends the segments without their odds', () async {
      final segments =
          ((await getJson(router(), '/inaam/spin?mobileNumber=$adnan'))['body']
                  as Map)['segments']
              as List;

      expect(segments, hasLength(3));
      for (final segment in segments) {
        expect((segment as Map).containsKey('weight'), isFalse);
      }
    });

    test('a spin spends the entitlement it used', () async {
      inaam.scanned(adnan, 20);

      final spin = await postJson(router(), '/inaam/spin', {
        'mobileNumber': adnan,
      });
      expect(spin['statusCode'], 201);
      expect((spin['body'] as Map)['reference'], isNotEmpty);

      final after =
          (await getJson(router(), '/inaam/spin?mobileNumber=$adnan'))['body']
              as Map;
      expect(after['spinsAvailable'], 1);
      expect((after['history'] as List), hasLength(1));
    });

    test('refuses a spin that has not been earned', () async {
      inaam.scanned(adnan, 9);

      final response = await postJson(router(), '/inaam/spin', {
        'mobileNumber': adnan,
      });

      expect(response['statusCode'], 409);
      expect((response['body'] as Map)['error'], 'no_spins_available');
    });

    test('says so when the wheel has not been set up', () async {
      inaam.unconfigure();

      final body =
          (await getJson(router(), '/inaam/spin?mobileNumber=$adnan'))['body']
              as Map;
      expect(body['scansPerSpin'], 0);
      expect(body['scansToNextSpin'], 0);

      final spin = await postJson(router(), '/inaam/spin', {
        'mobileNumber': adnan,
      });
      expect(spin['statusCode'], 409);
      expect((spin['body'] as Map)['error'], 'not_configured');
    });

    test('an unknown number is not a spin of zero', () async {
      final response = await getJson(
        router(),
        '/inaam/spin?mobileNumber=$stranger',
      );

      expect(response['statusCode'], 404);
    });
  });

  group('item schemes', () {
    test('carry progress and which tiers are reached', () async {
      inaam.addScheme(scheme(progress: 184));

      final schemes =
          ((await getJson(
                    router(),
                    '/inaam/item-schemes?mobileNumber=$adnan',
                  ))['body']
                  as Map)['schemes']
              as List;

      expect(schemes, hasLength(1));
      final tiers = (schemes.first as Map)['tiers'] as List;
      expect((tiers[0] as Map)['reached'], isTrue);
      expect((tiers[1] as Map)['reached'], isFalse);
    });

    test('a claim is recorded with what it paid', () async {
      inaam.addScheme(scheme(progress: 184));

      final response = await postJson(router(), '/inaam/item-schemes/claim', {
        'mobileNumber': adnan,
        'schemeId': 'scheme1',
        'tierId': 'silver',
      });

      expect(response['statusCode'], 201);
      expect((response['body'] as Map)['claimedTierName'], 'Silver');
      expect((response['body'] as Map)['claimedAmountPaisa'], 1400000);
    });

    test('a second claim is refused, ever', () async {
      inaam.addScheme(scheme(progress: 400));

      await postJson(router(), '/inaam/item-schemes/claim', {
        'mobileNumber': adnan,
        'schemeId': 'scheme1',
        'tierId': 'silver',
      });
      final second = await postJson(router(), '/inaam/item-schemes/claim', {
        'mobileNumber': adnan,
        'schemeId': 'scheme1',
        'tierId': 'gold',
      });

      expect(second['statusCode'], 409);
      expect((second['body'] as Map)['error'], 'already_claimed');
    });

    test('a tier that has not been reached cannot be taken', () async {
      inaam.addScheme(scheme(progress: 184));

      final response = await postJson(router(), '/inaam/item-schemes/claim', {
        'mobileNumber': adnan,
        'schemeId': 'scheme1',
        'tierId': 'gold',
      });

      expect(response['statusCode'], 409);
      expect((response['body'] as Map)['error'], 'not_reached');
    });

    test('an unknown tier is not a refusal about targets', () async {
      inaam.addScheme(scheme(progress: 400));

      final response = await postJson(router(), '/inaam/item-schemes/claim', {
        'mobileNumber': adnan,
        'schemeId': 'scheme1',
        'tierId': 'platinum',
      });

      expect(response['statusCode'], 404);
      expect((response['body'] as Map)['error'], 'unknown_tier');
    });

    test('an amount scheme keeps its measure', () async {
      inaam.addScheme(scheme(progress: 84000000, measure: 'amount'));

      final schemes =
          ((await getJson(
                    router(),
                    '/inaam/item-schemes?mobileNumber=$adnan',
                  ))['body']
                  as Map)['schemes']
              as List;

      expect((schemes.first as Map)['measure'], 'amount');
      expect((schemes.first as Map)['progress'], 84000000);
    });
  });

  group('the reward program', () {
    test('carries this month alongside last month\'s award', () async {
      inaam.setProgram(
        adnan,
        RewardProgramRow(
          label: 'September 2026',
          startsOn: DateTime.utc(2026, 9),
          endsOn: DateTime.utc(2026, 9, 30),
          scans: 14,
          tiers: const [
            ProgramTierRow(name: 'SILVER', scanTarget: 10, bonusPercent: 25),
            ProgramTierRow(name: 'GOLD', scanTarget: 25, bonusPercent: 50),
          ],
          awardTierName: 'SILVER',
          awardBonusPercent: 25,
          awardAppliesUntil: DateTime.utc(2026, 9, 30),
        ),
      );

      final body =
          (await getJson(
                router(),
                '/inaam/reward-program?mobileNumber=$adnan',
              ))['body']
              as Map;

      expect(body['label'], 'September 2026');
      expect(body['scans'], 14);
      expect(body['awardBonusPercent'], 25);
      expect((body['tiers'] as List), hasLength(2));
    });

    test('no award is null rather than a bonus of zero', () async {
      final body =
          (await getJson(
                router(),
                '/inaam/reward-program?mobileNumber=$adnan',
              ))['body']
              as Map;

      expect(body['awardTierName'], isNull);
      expect(body['awardBonusPercent'], isNull);
      expect(body['label'], isNull);
    });
  });
}
