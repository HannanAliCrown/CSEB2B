import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../data/complaints_data_store.dart';
import 'json_helpers.dart';

/// Complaints and notifications.
Router complaintsRoutes(ComplaintsDataStore store) {
  final router = Router();

  /// `GET /complaints/catalogue` — the categories, sub-types and targets the
  /// wizard offers. Registered before `/complaints/<reference>`, which would
  /// otherwise swallow it.
  router.get('/complaints/catalogue', (Request request) async {
    final types = await store.catalogue();
    return jsonResponse(200, {
      'types': [for (final type in types) type.toJson()],
    });
  });

  /// `GET /complaints?mobileNumber=` — this partner's tickets, newest first,
  /// with the counts the two tabs are labelled with.
  router.get('/complaints', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final complaints = await store.complaints(mobileNumber);
    if (complaints == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }

    return jsonResponse(200, {
      'complaints': [for (final complaint in complaints) complaint.toJson()],
      'inProgress': complaints.where((c) => c.status == 'in_progress').length,
      'resolved': complaints.where((c) => c.status == 'resolved').length,
    });
  });

  /// `GET /complaints/<reference>?mobileNumber=` — one ticket and its
  /// history.
  router.get('/complaints/<reference>', (
    Request request,
    String reference,
  ) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final complaint = await store.complaint(
      mobileNumber: mobileNumber,
      reference: reference,
    );
    // Another partner's reference is not found rather than forbidden: the
    // answer must not confirm that the ticket exists.
    if (complaint == null) {
      return jsonResponse(404, {'error': 'unknown_complaint'});
    }
    return jsonResponse(200, complaint.toJson());
  });

  /// `POST /complaints` — raises a ticket.
  router.post('/complaints', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    final typeId = body['typeId'] as String?;
    final priority = body['priority'] as String?;
    final title = body['title'] as String?;
    final detail = body['detail'] as String?;

    if (mobileNumber == null ||
        typeId == null ||
        priority == null ||
        title == null ||
        detail == null) {
      return jsonResponse(400, {
        'error':
            'mobileNumber, typeId, priority, title and detail are '
            'required',
      });
    }

    final (complaint, refusal) = await store.raiseComplaint(
      mobileNumber: mobileNumber,
      typeId: typeId,
      priority: priority,
      title: title,
      detail: detail,
    );

    return switch (refusal) {
      null => jsonResponse(201, complaint!.toJson()),
      ComplaintRefusal.unknownAccount => jsonResponse(404, {
        'error': 'unknown_account',
      }),
      ComplaintRefusal.unknownType => jsonResponse(400, {
        'error': 'unknown_type',
      }),
      ComplaintRefusal.incomplete => jsonResponse(400, {
        'error': 'title_and_detail_required',
      }),
    };
  });

  /// `GET /notifications?mobileNumber=` — the bell's list and its badge.
  router.get('/notifications', (Request request) async {
    final mobileNumber = request.url.queryParameters['mobileNumber'];
    if (mobileNumber == null || mobileNumber.isEmpty) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final notifications = await store.notifications(mobileNumber);
    if (notifications == null) {
      return jsonResponse(404, {'error': 'unknown_account'});
    }

    return jsonResponse(200, {
      'notifications': [for (final item in notifications) item.toJson()],
      'unread': notifications.where((item) => item.readAt == null).length,
    });
  });

  /// `POST /notifications/read` — one, or all of them when no id is given.
  router.post('/notifications/read', (Request request) async {
    final body = await readJsonBody(request);
    final mobileNumber = body['mobileNumber'] as String?;
    if (mobileNumber == null) {
      return jsonResponse(400, {'error': 'mobileNumber is required'});
    }

    final marked = await store.markRead(
      mobileNumber: mobileNumber,
      id: body['id'] as String?,
    );
    return jsonResponse(200, {'marked': marked});
  });

  return router;
}
