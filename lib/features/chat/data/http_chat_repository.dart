// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/staff/raised_by.dart';
import '../../session/data/signed_in_user.dart';
import 'chat_repository.dart';

/// Chat, read from the database behind `prototype_server`.
///
/// A conversation is stored once, not once per side, so a message really does
/// appear for the partner it was sent to.
class HttpChatRepository implements ChatRepository {
  HttpChatRepository({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final _changes = _Broadcast();

  @override
  Listenable get changes => _changes;

  @override
  Future<List<ChatThread>> threads(SignedInUser user) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/chat/threads')
          .replace(queryParameters: {'mobileNumber': user.mobileNumber}),
    );
    if (response.statusCode != 200) return const [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return [
      for (final entry in body['threads'] as List? ?? const [])
        _threadFrom(entry as Map<String, dynamic>, user),
    ];
  }

  @override
  Future<ChatThread> openWith(SignedInUser user, ChatParty party) async {
    final body = await _post('/chat/threads/open', {
      'mobileNumber': user.mobileNumber,
      'partyAddress': party.address,
    });
    if (body == null) return ChatThread(party: party, messages: []);

    _changes.announce();
    return _threadFrom(body, user);
  }

  @override
  Future<ChatParty?> partyForNumber(String mobileNumber) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/chat/party')
          .replace(queryParameters: {'address': mobileNumber}),
    );
    if (response.statusCode != 200) return null;
    return _partyFrom(jsonDecode(response.body) as Map<String, dynamic>);
  }

  @override
  Future<ChatMessage> send({
    required SignedInUser user,
    required ChatParty party,
    required String text,
  }) async {
    final body = await _post('/chat/messages', {
      'mobileNumber': user.mobileNumber,
      'partyAddress': party.address,
      'body': text,
    });
    _changes.announce();

    // The server answers with the whole conversation, so the message that
    // comes back is the one it actually stored rather than a hopeful copy.
    final thread = body == null ? null : _threadFrom(body, user);
    return thread?.latest ??
        ChatMessage(
          id: 'unsent',
          text: text,
          sentAt: DateTime.now(),
          mine: true,
          status: MessageStatus.sending,
        );
  }

  @override
  Future<void> markRead(SignedInUser user, ChatParty party) async {
    await _post('/chat/threads/read', {
      'mobileNumber': user.mobileNumber,
      'partyAddress': party.address,
    });
    _changes.announce();
  }

  Future<Map<String, dynamic>?> _post(
    String path,
    Map<String, Object?> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl$path'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) return null;
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  ChatThread _threadFrom(Map<String, dynamic> json, SignedInUser user) {
    final party = _partyFrom(json['party'] as Map<String, dynamic>);
    final mine = _nationalDigits(user.mobileNumber);

    return ChatThread(
      party: party,
      unread: (json['unread'] as num?)?.toInt() ?? 0,
      messages: [
        for (final entry in json['messages'] as List? ?? const [])
          ChatMessage(
            id: (entry as Map<String, dynamic>)['id'] as String,
            text: entry['body'] as String? ?? '',
            sentAt: DateTime.parse(entry['sentAt'] as String).toLocal(),
            mine: entry['senderAddress'] == mine,
            status: switch (entry['status']) {
              'sending' => MessageStatus.sending,
              'delivered' => MessageStatus.delivered,
              'read' => MessageStatus.read,
              _ => MessageStatus.sent,
            },
          ),
      ],
    );
  }

  /// A department's title and purpose live in [Department], not in the
  /// database — one place for that copy rather than two that can disagree.
  ChatParty _partyFrom(Map<String, dynamic> json) {
    final address = json['address'] as String;

    if (json['isDepartment'] == true) {
      final department = Department.values
          .where((value) => value.address == address)
          .firstOrNull;
      if (department != null) return ChatParty.department(department);
      return ChatParty(
        address: address,
        name: 'Crown Solar',
        subtitle: '',
        isDepartment: true,
      );
    }

    final role = _roleLabel(json['role'] as String?);
    final market = json['market'] as String? ?? '';
    return ChatParty(
      address: address,
      name: json['name'] as String? ?? address,
      subtitle: [role, market].where((part) => part.isNotEmpty).join(' · '),
      isDepartment: false,
    );
  }

  static String _roleLabel(String? userType) => switch (userType) {
    'installer' => 'Installer',
    'retailer' => 'Retailer',
    'wholesaler' => 'Wholesaler',
    'distributor' => 'Distributor',
    // A Crown Solar Teams officer (specs/013-teams-support, CSE-5).
    'mo' || 'asm' || 'rsm' => staffRoleLabel(userType),
    _ => '',
  };

  /// The ten national digits, matching how the database stores a number.
  static String _nationalDigits(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0092')) digits = digits.substring(4);
    if (digits.startsWith('92')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }
}

/// A [ChangeNotifier] its owner can fire, so the repository can announce a
/// change without exposing the whole notifier API.
class _Broadcast extends ChangeNotifier {
  void announce() => notifyListeners();
}
