import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/social_data_store.dart';
import 'json_helpers.dart';

/// Space and Chat.
///
/// There is no endpoint that creates a Space post, and that is deliberate:
/// posts are published by a separate Crown Solar application straight into
/// the database. This app reads them and adds only hearts and comments.
Router socialRoutes(SocialDataStore store) {
  final router = Router();

  // --- Space ---

  /// `GET /space/feed?mobileNumber=` — the posts this partner's role sees,
  /// newest first, each with its hearts and its conversation.
  router.get('/space/feed', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final posts = await store.spaceFeed(mobileNumber);
    return jsonResponse(200, {
      'posts': [for (final post in posts) post.toJson()],
    });
  });

  /// `GET /space/posts/<id>?mobileNumber=` — one post as this partner sees
  /// it. What the detail screen re-reads after saying something, so it shows
  /// what was stored rather than what it hoped was stored.
  router.get('/space/posts/<id>', (Request request, String id) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final post = await store.spacePost(postId: id, mobileNumber: mobileNumber);
    if (post == null) return jsonResponse(404, {'error': 'post_not_found'});
    return jsonResponse(200, post.toJson());
  });

  /// `POST /space/posts/<id>/heart` — on if it was off, off if it was on.
  router.post('/space/posts/<id>/heart', (Request request, String id) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    if (mobileNumber == null) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final post = await store.toggleHeart(
      postId: id,
      mobileNumber: mobileNumber,
    );
    if (post == null) return jsonResponse(404, {'error': 'post_not_found'});
    return jsonResponse(200, post.toJson());
  });

  /// `POST /space/posts/<id>/comments` — a new top-level comment.
  router.post('/space/posts/<id>/comments', (Request request, String id) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final text = (body['body'] as String?)?.trim();
    if (mobileNumber == null || text == null || text.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber and body are required'});
    }
    final comment = await store.addComment(
      postId: id,
      mobileNumber: mobileNumber,
      body: text,
    );
    if (comment == null) return jsonResponse(404, {'error': 'post_not_found'});
    return jsonResponse(201, comment.toJson());
  });

  /// `POST /space/comments/<id>/replies` — a reply under one comment. The
  /// database refuses a reply to a reply; the app only ever shows two levels.
  router.post('/space/comments/<id>/replies', (
    Request request,
    String id,
  ) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final text = (body['body'] as String?)?.trim();
    if (mobileNumber == null || text == null || text.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber and body are required'});
    }
    try {
      final reply = await store.addReply(
        commentId: id,
        mobileNumber: mobileNumber,
        body: text,
      );
      if (reply == null) {
        return jsonResponse(404, {'error': 'comment_not_found'});
      }
      return jsonResponse(201, reply.toJson());
    } on Object {
      return jsonResponse(409, {'error': 'replies_are_one_level_deep'});
    }
  });

  // --- Chat ---

  /// `GET /chat/threads?mobileNumber=` — this partner's conversations.
  router.get('/chat/threads', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }
    final threads = await store.chatThreads(mobileNumber);
    return jsonResponse(200, {
      'threads': [for (final thread in threads) thread.toJson()],
    });
  });

  /// `GET /chat/party?address=` — who a scanned code or typed number is.
  router.get('/chat/party', (Request request) async {
    final address = request.url.queryParameters['address'];
    if (address == null || address.isEmpty) {
      return jsonResponse(400, {'error': 'address is required'});
    }
    final party = await store.resolveParty(address);
    if (party == null) return jsonResponse(404, {'error': 'unknown_party'});
    return jsonResponse(200, party.toJson());
  });

  /// `POST /chat/threads/open` — the conversation with a party, started if
  /// there is none.
  router.post('/chat/threads/open', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final partyAddress = body['partyAddress'] as String?;
    if (mobileNumber == null || partyAddress == null) {
      return jsonResponse(400, {
        'error': 'mobileNumber and partyAddress are required',
      });
    }
    final thread = await store.openThread(
      mobileNumber: mobileNumber,
      partyAddress: partyAddress,
    );
    if (thread == null) return jsonResponse(404, {'error': 'unknown_party'});
    return jsonResponse(200, thread.toJson());
  });

  /// `POST /chat/messages` — says something, and returns the conversation as
  /// it now stands so the screen never has to guess where the message landed.
  router.post('/chat/messages', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final partyAddress = body['partyAddress'] as String?;
    final text = (body['body'] as String?)?.trim();
    if (mobileNumber == null ||
        partyAddress == null ||
        text == null ||
        text.isEmpty) {
      return jsonResponse(400, {
        'error': 'mobileNumber, partyAddress and body are required',
      });
    }
    final thread = await store.sendMessage(
      mobileNumber: mobileNumber,
      partyAddress: partyAddress,
      body: text,
    );
    if (thread == null) return jsonResponse(404, {'error': 'unknown_party'});
    return jsonResponse(201, thread.toJson());
  });

  /// `POST /chat/threads/read` — clears this partner's unread badge.
  router.post('/chat/threads/read', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final partyAddress = body['partyAddress'] as String?;
    if (mobileNumber == null || partyAddress == null) {
      return jsonResponse(400, {
        'error': 'mobileNumber and partyAddress are required',
      });
    }
    await store.markThreadRead(
      mobileNumber: mobileNumber,
      partyAddress: partyAddress,
    );
    return jsonResponse(200, {'status': 'read'});
  });

  return router;
}
