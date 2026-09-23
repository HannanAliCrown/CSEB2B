// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/foundation.dart';

import '../../../core/mock/partner_directory.dart';
import '../../session/data/signed_in_user.dart';

/// A Crown Solar team a partner can always reach, whether or not anyone has
/// their number.
enum Department { crm, branding, technicalSupport, accounts }

extension DepartmentX on Department {
  String get title => switch (this) {
    Department.crm => 'CRM',
    Department.branding => 'Branding',
    Department.technicalSupport => 'Technical Support',
    Department.accounts => 'Accounts',
  };

  String get purpose => switch (this) {
    Department.crm => 'Accounts, device changes, points adjustments',
    Department.branding => 'Shop branding requests and suppliers',
    Department.technicalSupport => 'Product and installation questions',
    Department.accounts => 'Wallet, ledger and settlement queries',
  };

  /// Departments have no mobile number, so they are addressed by name.
  String get address => 'dept:$name';
}

/// Who a conversation is with: another partner, or a Crown Solar department.
class ChatParty {
  const ChatParty({
    required this.address,
    required this.name,
    required this.subtitle,
    required this.isDepartment,
  });

  factory ChatParty.partner(PartnerAccount account) => ChatParty(
    address: PartnerDirectory.normalise(account.mobileNumber),
    name: account.displayName,
    subtitle: '${account.role} · ${account.market}',
    isDepartment: false,
  );

  factory ChatParty.department(Department department) => ChatParty(
    address: department.address,
    name: '${department.title} · Crown Solar',
    subtitle: department.purpose,
    isDepartment: true,
  );

  /// Stable id: a partner's national digits, or `dept:<name>`.
  final String address;
  final String name;
  final String subtitle;
  final bool isDepartment;
}

/// How far a message has got.
enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.mine,
    required this.status,
  });

  final String id;
  final String text;
  final DateTime sentAt;

  /// True when the signed-in partner wrote it.
  final bool mine;
  final MessageStatus status;
}

/// One conversation and its messages.
class ChatThread {
  ChatThread({required this.party, required this.messages, this.unread = 0});

  final ChatParty party;
  final List<ChatMessage> messages;

  /// Messages the partner has not opened yet.
  int unread;

  ChatMessage? get latest => messages.isEmpty ? null : messages.last;

  bool get hasUnread => unread > 0;
}

/// Chat's data boundary. The mock below keeps everything in memory for the
/// session, so a message really appears in its thread and the list reorders.
abstract interface class ChatRepository {
  /// Fires whenever a thread changes, so open screens can refresh.
  Listenable get changes;

  Future<List<ChatThread>> threads(SignedInUser user);

  /// The existing conversation with this party, creating one if there is none.
  Future<ChatThread> openWith(SignedInUser user, ChatParty party);

  /// Resolves a scanned code or typed number to someone who can be messaged.
  Future<ChatParty?> partyForNumber(String mobileNumber);

  Future<ChatMessage> send({
    required SignedInUser user,
    required ChatParty party,
    required String text,
  });

  Future<void> markRead(SignedInUser user, ChatParty party);
}

class MockChatRepository implements ChatRepository {
  MockChatRepository();

  static const _latency = Duration(milliseconds: 180);

  final _changes = _Broadcast();
  var _nextId = 1;

  /// Threads per signed-in partner, keyed by their national digits.
  final Map<String, List<ChatThread>> _byUser = {};

  @override
  Listenable get changes => _changes;

  List<ChatThread> _threadsFor(SignedInUser user) => _byUser.putIfAbsent(
    PartnerDirectory.normalise(user.mobileNumber),
    () => _seed(user),
  );

  @override
  Future<List<ChatThread>> threads(SignedInUser user) async {
    await Future<void>.delayed(_latency);
    final threads = [..._threadsFor(user)];
    // Newest conversation first, as every chat app orders them.
    threads.sort((a, b) {
      final left = a.latest?.sentAt;
      final right = b.latest?.sentAt;
      if (left == null || right == null) return 0;
      return right.compareTo(left);
    });
    return threads;
  }

  @override
  Future<ChatThread> openWith(SignedInUser user, ChatParty party) async {
    final threads = _threadsFor(user);
    for (final thread in threads) {
      if (thread.party.address == party.address) return thread;
    }
    final fresh = ChatThread(party: party, messages: []);
    threads.add(fresh);
    _changes.announce();
    return fresh;
  }

  @override
  Future<ChatParty?> partyForNumber(String mobileNumber) async {
    await Future<void>.delayed(_latency);
    final account = PartnerDirectory.find(mobileNumber);
    return account == null ? null : ChatParty.partner(account);
  }

  @override
  Future<ChatMessage> send({
    required SignedInUser user,
    required ChatParty party,
    required String text,
  }) async {
    final thread = await openWith(user, party);
    final message = ChatMessage(
      id: 'M${_nextId++}',
      text: text,
      sentAt: DateTime.now(),
      mine: true,
      status: MessageStatus.sent,
    );
    thread.messages.add(message);
    _changes.announce();
    return message;
  }

  @override
  Future<void> markRead(SignedInUser user, ChatParty party) async {
    for (final thread in _threadsFor(user)) {
      if (thread.party.address != party.address) continue;
      if (thread.unread == 0) return;
      thread.unread = 0;
      _changes.announce();
      return;
    }
  }

  /// Opening conversations, so the list is never empty on first sight. Every
  /// partner thread is with someone who really exists in the directory.
  List<ChatThread> _seed(SignedInUser user) {
    // Only the partners the bundled directory already knows have a history.
    // Someone who registered on this phone has spoken to nobody yet, so
    // their Space stays empty until they start a conversation themselves.
    if (PartnerDirectory.find(user.mobileNumber) == null) {
      return <ChatThread>[];
    }

    final now = DateTime.now();
    final mine = PartnerDirectory.normalise(user.mobileNumber);

    ChatMessage from(String text, Duration ago) => ChatMessage(
      id: 'M${_nextId++}',
      text: text,
      sentAt: now.subtract(ago),
      mine: false,
      status: MessageStatus.delivered,
    );
    ChatMessage sentByMe(String text, Duration ago) => ChatMessage(
      id: 'M${_nextId++}',
      text: text,
      sentAt: now.subtract(ago),
      mine: true,
      status: MessageStatus.read,
    );

    final threads = <ChatThread>[
      ChatThread(
        party: ChatParty.department(Department.crm),
        unread: 2,
        messages: [
          sentByMe(
            'I scanned the same code twice by mistake.',
            const Duration(hours: 3),
          ),
          from(
            'We are checking both scans against the record.',
            const Duration(hours: 2),
          ),
          from('Nothing has been deducted from you.', const Duration(hours: 2)),
        ],
      ),
      ChatThread(
        party: ChatParty.department(Department.branding),
        messages: [
          from(
            'Your frontlit board request is approved. The supplier will call '
            'you before 30 September.',
            const Duration(days: 1),
          ),
        ],
      ),
    ];

    // A conversation with each partner in the directory, skipping yourself.
    final samples = <String, ({String text, bool mine, Duration ago})>{
      '3217745002': (
        text: 'Bhai, panels ka rate kya hai aaj?',
        mine: false,
        ago: Duration(hours: 5),
      ),
      '3007781204': (
        text: 'Cash bhej diya hai, please accept karein.',
        mine: true,
        ago: Duration(days: 1),
      ),
      '3014429911': (
        text: 'Stock 12 September ko pohnch jayega.',
        mine: false,
        ago: Duration(days: 2),
      ),
    };

    for (final account in PartnerDirectory.accounts) {
      final key = PartnerDirectory.normalise(account.mobileNumber);
      if (key == mine) continue;
      final sample = samples[key];
      if (sample == null) continue;

      threads.add(
        ChatThread(
          party: ChatParty.partner(account),
          unread: sample.mine ? 0 : 1,
          messages: [
            sample.mine
                ? sentByMe(sample.text, sample.ago)
                : from(sample.text, sample.ago),
          ],
        ),
      );
    }

    return threads;
  }
}

/// A [ChangeNotifier] its owner can fire, so the repository can announce a
/// change without exposing the whole notifier API.
class _Broadcast extends ChangeNotifier {
  void announce() => notifyListeners();
}
