// Constructor parameters are named for their public API rather than the
// private fields they populate, so the initializing-formal shorthand the
// linter suggests is not available here.
// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../session/data/signed_in_user.dart';
import 'space_repository.dart';

/// Space, read from the database behind `prototype_server`.
///
/// Posts are written by a separate Crown Solar application, so nothing here
/// creates one — the partner app reads the feed and adds only its own hearts
/// and comments. That is why there is no `publish` method to be found.
class HttpSpaceRepository implements SpaceRepository {
  HttpSpaceRepository({required String baseUrl, http.Client? client})
    : _baseUrl = baseUrl,
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final _changes = _Broadcast();

  /// The last state read for each post. [post] answers from here, and every
  /// write refreshes the entry from the server before announcing — so an open
  /// detail screen shows what was stored, not what was hoped for.
  final Map<String, SpacePost> _seen = {};

  @override
  Listenable get changes => _changes;

  @override
  Future<List<SpacePost>> feed(SignedInUser user) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/space/feed')
          .replace(queryParameters: {'mobileNumber': user.mobileNumber}),
    );
    if (response.statusCode != 200) return const [];

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final posts = [
      for (final entry in body['posts'] as List? ?? const [])
        _postFrom(entry as Map<String, dynamic>),
    ];
    for (final post in posts) {
      _seen[post.id] = post;
    }
    return posts;
  }

  @override
  Future<SpacePost?> post(String id) async => _seen[id];

  @override
  Future<SpacePost?> toggleHeart({
    required String postId,
    required SignedInUser user,
  }) async {
    final updated = await _post('/space/posts/$postId/heart', {
      'mobileNumber': user.mobileNumber,
    });
    if (updated == null) return null;

    final post = _postFrom(updated);
    _seen[post.id] = post;
    _changes.announce();
    return post;
  }

  @override
  Future<PostComment?> comment({
    required String postId,
    required SignedInUser user,
    required String body,
  }) async {
    final created = await _post('/space/posts/$postId/comments', {
      'mobileNumber': user.mobileNumber,
      'body': body,
    });
    if (created == null) return null;
    await _reload(postId, user);
    _changes.announce();
    return _commentFrom(created);
  }

  @override
  Future<PostReply?> reply({
    required String postId,
    required String commentId,
    required SignedInUser user,
    required String body,
  }) async {
    final created = await _post('/space/comments/$commentId/replies', {
      'mobileNumber': user.mobileNumber,
      'body': body,
    });
    if (created == null) return null;
    await _reload(postId, user);
    _changes.announce();

    final comment = _commentFrom(created);
    return PostReply(
      id: comment.id,
      author: comment.author,
      body: comment.body,
      postedAt: comment.postedAt,
      official: comment.official,
    );
  }

  /// Re-reads one post from the server into the cache, so whatever is on
  /// screen catches up with what was actually written.
  Future<void> _reload(String postId, SignedInUser user) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/space/posts/$postId')
          .replace(queryParameters: {'mobileNumber': user.mobileNumber}),
    );
    if (response.statusCode != 200) return;
    final post = _postFrom(jsonDecode(response.body) as Map<String, dynamic>);
    _seen[post.id] = post;
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

  SpacePost _postFrom(Map<String, dynamic> json) => SpacePost(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    postedAt: DateTime.parse(json['postedAt'] as String).toLocal(),
    audience: switch (json['audience']) {
      'installer' => PostAudience.installers,
      'retailer' => PostAudience.retailers,
      'trade' => PostAudience.trade,
      _ => PostAudience.everyone,
    },
    image: json['imageUrl'] as String?,
    hearts: (json['hearts'] as num?)?.toInt() ?? 0,
    heartedByMe: json['heartedByMe'] == true,
    comments: [
      for (final entry in json['comments'] as List? ?? const [])
        _commentFrom(entry as Map<String, dynamic>),
    ],
  );

  PostComment _commentFrom(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String,
    author: json['author'] as String? ?? '',
    body: json['body'] as String? ?? '',
    postedAt: DateTime.parse(json['postedAt'] as String).toLocal(),
    official: json['official'] == true,
    replies: [
      for (final entry in json['replies'] as List? ?? const [])
        PostReply(
          id: (entry as Map<String, dynamic>)['id'] as String,
          author: entry['author'] as String? ?? '',
          body: entry['body'] as String? ?? '',
          postedAt: DateTime.parse(entry['postedAt'] as String).toLocal(),
          official: entry['official'] == true,
        ),
    ],
  );
}

/// A [ChangeNotifier] its owner can fire, so the repository can announce a
/// change without exposing the whole notifier API.
class _Broadcast extends ChangeNotifier {
  void announce() => notifyListeners();
}
