import 'dart:math';

import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/client/matrix/matrix_room.dart';
import 'package:commet/client/matrix/matrix_timeline.dart';
import 'package:commet/utils/rng.dart';
import 'package:matrix/matrix.dart' as matrix;

// ignore: implementation_imports
import 'package:matrix/src/models/timeline_chunk.dart' as c;

const benchmarkUserId = "@benchy:example.com";
const _roomId = "!benchmark:example.com";
const finalEventMessage = "End Test Here";

extension BenchmarkUtils on MatrixClient {
  MatrixRoom createRoomWithData() {
    // Timeline event menus call room.canRedact → ownPowerLevel → client.userID!
    final mx = getMatrixClient();
    mx.setUserId(benchmarkUserId);

    var mxRoom = matrix.Room.fromJson({
      'id': _roomId,
      'membership': 'join',
      'notification_count': 0,
      'highlight_count': 0,
      'prev_batch': 'fake_batch_id',
      'summary': {
        'm.joined_member_count': 100,
        'm.invited_member_count': 0,
      },
    }, mx);

    mxRoom.setState(matrix.Event.fromJson({
      'type': 'm.room.create',
      'state_key': '',
      'sender': benchmarkUserId,
      'content': {'creator': benchmarkUserId, 'room_version': '10'},
    }, mxRoom));

    mxRoom.setState(matrix.Event.fromJson({
      'type': 'm.room.member',
      'state_key': benchmarkUserId,
      'sender': benchmarkUserId,
      'content': {'displayname': 'Benchy', 'membership': 'join'}
    }, mxRoom));

    mxRoom.setState(matrix.Event.fromJson({
      'type': 'm.room.power_levels',
      'state_key': '',
      'sender': benchmarkUserId,
      'content': {
        'users': {benchmarkUserId: 100},
        'users_default': 0,
        'events_default': 0,
        'state_default': 50,
        'ban': 50,
        'kick': 50,
        'redact': 50,
        'invite': 50,
      },
    }, mxRoom));

    var room = MatrixRoom(this, mxRoom, mx);
    rooms.add(room);
    return room;
  }
}

extension BenchmarkTimeline on MatrixRoom {
  MatrixTimeline getBenchmarkTimeline() {
    int count = 500;
    var chunk = c.TimelineChunk(events: [
      for (var i = 0; i < count; i++) createRandomEvent(i, count),
      createTestEndEvent(count),

      // create more events so it doent try to fetch more from server
      for (var i = 0; i < 50; i++) createRandomEvent(count + 1 + i, count),
    ]);

    var mxTimeline = matrix.Timeline(chunk: chunk, room: matrixRoom);

    return MatrixTimeline(client as MatrixClient, this, matrixRoom,
        initialTimeline: mxTimeline);
  }

  matrix.Event createTestEndEvent(int eventCount) {
    var event = matrix.Event.fromJson({
      'event_id': '\$final',
      'type': 'm.room.message',
      'content': {'body': finalEventMessage, 'msgtype': 'm.text'},
      'sender': benchmarkUserId,
      'room_id': matrixRoom.id,
      'origin_server_ts': DateTime.now()
          .subtract(Duration(days: eventCount))
          .millisecondsSinceEpoch
    }, matrixRoom);

    return event;
  }

  matrix.Event createRandomEvent(int seed, int limit) {
    final r = Random(seed);

    var relatedEventId = '\$${seed + 5}';
    bool canBeRelatedEvent = seed < limit - 10;

    var json = {
      'event_id': '\$$seed',
      'sender': benchmarkUserId,
      'room_id': matrixRoom.id,
      'origin_server_ts':
          DateTime.now().subtract(Duration(days: seed)).millisecondsSinceEpoch
    };

    if (r.nextDouble() < 0.33 && canBeRelatedEvent) {
      json['type'] = 'm.reaction';
      json['content'] = {
        'm.relates_to': {
          'event_id': relatedEventId,
          'rel_type': 'm.annotation',
          'key': r.nextBool() ? 'String Reaction' : "❤️"
        }
      };

      return matrix.Event.fromJson(json, matrixRoom);
    }

    var contentLength = r.nextInt(200) + 10;

    bool isThreadReply = r.nextBool();

    var event = matrix.Event.fromJson({
      'event_id': '\$$seed',
      'type': 'm.room.message',
      'content': {
        'body':
            '($seed) https://example.com ${RandomUtils.getRandomSentence(contentLength)}',
        'msgtype': 'm.text',
        if (canBeRelatedEvent)
          'm.relates_to': {
            if (isThreadReply) 'event_id': relatedEventId,
            if (isThreadReply) 'rel_type': 'm.thread',
            if (isThreadReply) 'is_falling_back': true,
            if (isThreadReply == false)
              'm.in_reply_to': {'event_id': relatedEventId}
          },
      },
      'sender': benchmarkUserId,
      'room_id': matrixRoom.id,
      'origin_server_ts':
          DateTime.now().subtract(Duration(days: seed)).millisecondsSinceEpoch
    }, matrixRoom);

    return event;
  }
}
