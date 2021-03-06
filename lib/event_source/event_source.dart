import 'dart:async' show Future, Stream, StreamController;
import 'dart:convert' show LineSplitter;
import 'package:http/http.dart' as http;

// NOTE THIS DOES NOT CURRENTLY WORK!
// I think Dart's http client buffers data, which is not good for event-streams.

class MessageEvent {
  final String name;
  final String data;

  MessageEvent({this.name, this.data});
}

/// A client for server-sent events. An EventSource instance opens a persistent connection to an HTTP server, which sends events in `text/event-stream` format.
class EventSource {
  /// Event name for a block in case no `event:` line was seen.
  static const _DEFAULT_EVENT_NAME = 'message';
  /// Expected mime type of an EventSource endpoint.
  static const _MIME_TYPE = 'text/event-stream';

  /// readyState: connection setup in progress.
  static const int CONNECTING = 0;
  /// readyState: connection complete.
  static const int OPEN = 1;
  /// readyState: connection closed.
  static const int CLOSED = 2;

  /// Client used for the request.
  http.Client _client;
  /// Data controller for the `.events` attribute.
  final StreamController<MessageEvent> _streamController =
    StreamController.broadcast();
  /// Mutable readyState.
  int _readyState = CONNECTING;
  /// Time in ms to wait before reconnecting.
  int _reconnectTime = 3000;
  /// The last-seen event ID, used when reconnecting.
  String _lastEventID;
  /// The `event:` value for the current block.
  String _nextEventName;
  /// The data value for the current block.
  String _nextData;

  /// The URL of the EventSource endpoint.
  final Uri url;

  /// A number representing the state of the connection.
  int get readyState => this._readyState;

  /// A stream of events coming in from the endpoint.
  Stream<MessageEvent> get events => this._streamController.stream;

  /// Create an EventSource for a given remote URL.
  EventSource(this.url);

  /// Opens the connection. Once the returned Future completes, events will start coming in on the `.events` attribute.
  Future<Null> open() async {
    _readyState = CONNECTING;
    final request = http.Request('GET', this.url);
    request.headers['Accept'] = _MIME_TYPE;
    if (_lastEventID != null) {
      request.headers['Last-Event-ID'] = _lastEventID;
    }

    _client = http.Client();
    final response = await _client.send(request);
    _readyState = OPEN;

    response.stream
      .toStringStream()
      .transform(LineSplitter())
      .listen((line) {
        _onMessage(line);
      });
  }

  /// Closes the connection, if any, and sets the `readyState` attribute to `CLOSED`.
  /// If the connection is already closed, the method does nothing.
  void close() {
    if (_readyState != CLOSED) {
      _client.close();
      _client = null;
      _readyState = CLOSED;
    }
  }

  /// Process a partial message (a line).
  void _onMessage(String message) {
    if (message == '') {
      if (_nextEventName == null && _nextData == null) {
        return;
      }

      _streamController.add(MessageEvent(
        name: _nextEventName ?? _DEFAULT_EVENT_NAME,
        data: _nextData,
      ));
      _nextEventName = null;
      _nextData = null;
      return;
    }
    if (message.startsWith(':')) {
      // comment
      return;
    }

    String name = message;
    String value;
    final colon = message.indexOf(':');
    if (colon != -1) {
      name = message.substring(0, colon);
      value = message.substring(message[colon + 1] == ' ' ? colon + 2 : colon + 1);
    }

    if (name == 'event') {
      _nextEventName = value;
    } else if (name == 'data') {
      if (_nextData == null) {
        _nextData = value;
      } else {
        _nextData += '\n$value';
      }
      _nextEventName = null;
    } else if (name == 'id') {
      _lastEventID = value;
    } else if (name == 'retry') {
      _reconnectTime = int.parse(value, radix: 10);
    }
  }
}
