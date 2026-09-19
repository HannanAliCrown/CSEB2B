import 'package:flutter_test/flutter_test.dart';

import 'package:cse_b2b/core/mock/partner_directory.dart';
import 'package:cse_b2b/features/chat/data/chat_repository.dart';
import 'package:cse_b2b/features/session/data/signed_in_user.dart';

final _installer = SignedInUser.fromAccount(
  PartnerDirectory.find('3004821190')!,
);

void main() {
  group('conversations', () {
    test('open with departments and partners already in the list', () async {
      final threads = await MockChatRepository().threads(_installer);

      expect(threads, isNotEmpty);
      expect(threads.any((t) => t.party.isDepartment), isTrue);
      expect(threads.any((t) => !t.party.isDepartment), isTrue);
    });

    test('never a conversation with yourself', () async {
      final threads = await MockChatRepository().threads(_installer);

      expect(
        threads.any(
          (t) =>
              t.party.address ==
              PartnerDirectory.normalise(_installer.mobileNumber),
        ),
        isFalse,
      );
    });

    test('the newest conversation is first', () async {
      final threads = await MockChatRepository().threads(_installer);

      for (var i = 1; i < threads.length; i++) {
        final newer = threads[i - 1].latest!.sentAt;
        final older = threads[i].latest!.sentAt;
        expect(
          newer.isBefore(older),
          isFalse,
          reason: 'threads are ordered newest first',
        );
      }
    });

    test('a number resolves to a partner, never to a stranger', () async {
      final chat = MockChatRepository();

      final found = await chat.partyForNumber('3007781204');
      expect(found?.name, 'Al-Noor Electric Store');
      expect(found?.isDepartment, isFalse);

      expect(await chat.partyForNumber('3009990000'), isNull);
    });

    test('the leading 0 and +92 forms reach the same partner', () async {
      final chat = MockChatRepository();

      for (final typed in ['03007781204', '+92 300 7781204', '3007781204']) {
        final found = await chat.partyForNumber(typed);
        expect(found?.name, 'Al-Noor Electric Store', reason: typed);
      }
    });

    test('opening a department creates one conversation, not two', () async {
      final chat = MockChatRepository();
      final party = ChatParty.department(Department.accounts);

      final first = await chat.openWith(_installer, party);
      final second = await chat.openWith(_installer, party);

      expect(identical(first, second), isTrue);
      final threads = await chat.threads(_installer);
      expect(
        threads.where((t) => t.party.address == party.address),
        hasLength(1),
      );
    });

    test('sending adds the message and moves the thread to the top', () async {
      final chat = MockChatRepository();
      final party = ChatParty.department(Department.accounts);

      await chat.send(user: _installer, party: party, text: 'Salam');

      final threads = await chat.threads(_installer);
      expect(threads.first.party.address, party.address);
      expect(threads.first.latest?.text, 'Salam');
      expect(threads.first.latest?.mine, isTrue);
    });

    test('opening a conversation clears its unread badge', () async {
      final chat = MockChatRepository();
      final unread = (await chat.threads(_installer))
          .firstWhere((t) => t.hasUnread);

      await chat.markRead(_installer, unread.party);

      final after = (await chat.threads(_installer))
          .firstWhere((t) => t.party.address == unread.party.address);
      expect(after.hasUnread, isFalse);
      expect(after.unread, 0);
    });

    test('every department can be reached', () async {
      final chat = MockChatRepository();

      for (final department in Department.values) {
        final thread = await chat.openWith(
          _installer,
          ChatParty.department(department),
        );
        expect(thread.party.name, contains(department.title));
      }
    });
  });
}
