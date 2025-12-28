import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Event types from Gemini Live API
sealed class GeminiLiveEvent {}

class GeminiLiveConnected extends GeminiLiveEvent {}

class GeminiLiveDisconnected extends GeminiLiveEvent {}

class GeminiLiveTranscription extends GeminiLiveEvent {
  final String text;
  final bool isFinal;
  GeminiLiveTranscription({required this.text, this.isFinal = false});
}

class GeminiLiveAudioResponse extends GeminiLiveEvent {
  final Uint8List audioData;
  GeminiLiveAudioResponse({required this.audioData});
}

class GeminiLiveTextResponse extends GeminiLiveEvent {
  final String text;
  final bool isFinal;
  GeminiLiveTextResponse({required this.text, this.isFinal = false});
}

class GeminiLiveError extends GeminiLiveEvent {
  final String message;
  GeminiLiveError({required this.message});
}

/// Service for Gemini Live API bidirectional audio streaming
class GeminiLiveService {
  WebSocketChannel? _channel;
  final StreamController<GeminiLiveEvent> _eventController =
      StreamController<GeminiLiveEvent>.broadcast();

  bool _isConnected = false;

  /// Stream of events from Gemini Live API
  Stream<GeminiLiveEvent> get events => _eventController.stream;

  /// Whether the service is connected
  bool get isConnected => _isConnected;

  /// Connect to Gemini Live API
  Future<void> connect({
    required String apiKey,
    String? systemInstruction,
    String model = 'gemini-2.0-flash-exp',
  }) async {
    if (_isConnected) {
      debugPrint('GeminiLiveService: Already connected');
      return;
    }

    try {
      // Gemini Live API WebSocket endpoint
      final uri = Uri.parse(
        'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent?key=$apiKey',
      );

      debugPrint('GeminiLiveService: Connecting to Gemini Live API...');
      _channel = WebSocketChannel.connect(uri);

      // Wait for connection
      await _channel!.ready;
      _isConnected = true;
      debugPrint('GeminiLiveService: Connected!');

      // Send initial setup message
      final setupMessage = {
        'setup': {
          'model': 'models/$model',
          'generation_config': {
            'response_modalities': ['AUDIO', 'TEXT'],
            'speech_config': {
              'voice_config': {
                'prebuilt_voice_config': {
                  'voice_name': 'Aoede', // Female voice, natural-sounding
                },
              },
            },
          },
          if (systemInstruction != null)
            'system_instruction': {
              'parts': [
                {'text': systemInstruction},
              ],
            },
        },
      };

      _channel!.sink.add(jsonEncode(setupMessage));
      debugPrint('GeminiLiveService: Setup message sent');

      // Listen for responses
      _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          debugPrint('GeminiLiveService: WebSocket error: $error');
          _eventController.add(GeminiLiveError(message: error.toString()));
          _isConnected = false;
        },
        onDone: () {
          debugPrint('GeminiLiveService: WebSocket closed');
          _isConnected = false;
          _eventController.add(GeminiLiveDisconnected());
        },
      );

      _eventController.add(GeminiLiveConnected());
    } catch (e) {
      debugPrint('GeminiLiveService: Connection failed: $e');
      _isConnected = false;
      _eventController.add(GeminiLiveError(message: 'Connection failed: $e'));
      rethrow;
    }
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic message) {
    try {
      final data = message is String
          ? message
          : utf8.decode(message as List<int>);
      final json = jsonDecode(data) as Map<String, dynamic>;

      debugPrint('GeminiLiveService: Received message: ${json.keys}');

      // Handle setup complete
      if (json.containsKey('setupComplete')) {
        debugPrint('GeminiLiveService: Setup complete');
        return;
      }

      // Handle server content (responses)
      if (json.containsKey('serverContent')) {
        final serverContent = json['serverContent'] as Map<String, dynamic>;
        final modelTurn = serverContent['modelTurn'] as Map<String, dynamic>?;
        final turnComplete = serverContent['turnComplete'] as bool? ?? false;

        if (modelTurn != null && modelTurn.containsKey('parts')) {
          final parts = modelTurn['parts'] as List;
          for (final part in parts) {
            final partMap = part as Map<String, dynamic>;

            // Handle text response
            if (partMap.containsKey('text')) {
              final text = partMap['text'] as String;
              _eventController.add(
                GeminiLiveTextResponse(text: text, isFinal: turnComplete),
              );
            }

            // Handle audio response (inline data)
            if (partMap.containsKey('inlineData')) {
              final inlineData = partMap['inlineData'] as Map<String, dynamic>;
              final mimeType = inlineData['mimeType'] as String?;
              final dataBase64 = inlineData['data'] as String?;

              if (mimeType?.startsWith('audio/') == true &&
                  dataBase64 != null) {
                final audioData = base64Decode(dataBase64);
                _eventController.add(
                  GeminiLiveAudioResponse(
                    audioData: Uint8List.fromList(audioData),
                  ),
                );
              }
            }
          }
        }

        // Handle input transcription
        if (serverContent.containsKey('inputTranscription')) {
          final transcription =
              serverContent['inputTranscription'] as Map<String, dynamic>;
          final text = transcription['text'] as String? ?? '';
          _eventController.add(
            GeminiLiveTranscription(text: text, isFinal: turnComplete),
          );
        }
      }

      // Handle tool calls (if any)
      if (json.containsKey('toolCall')) {
        debugPrint('GeminiLiveService: Tool call received (not implemented)');
      }
    } catch (e) {
      debugPrint('GeminiLiveService: Error parsing message: $e');
    }
  }

  /// Send audio data to Gemini
  void sendAudio(Uint8List audioData) {
    if (!_isConnected || _channel == null) {
      debugPrint('GeminiLiveService: Cannot send audio - not connected');
      return;
    }

    final message = {
      'realtimeInput': {
        'mediaChunks': [
          {'mimeType': 'audio/pcm;rate=16000', 'data': base64Encode(audioData)},
        ],
      },
    };

    _channel!.sink.add(jsonEncode(message));
  }

  /// Send text message to Gemini
  void sendText(String text) {
    if (!_isConnected || _channel == null) {
      debugPrint('GeminiLiveService: Cannot send text - not connected');
      return;
    }

    final message = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turnComplete': true,
      },
    };

    _channel!.sink.add(jsonEncode(message));
    debugPrint('GeminiLiveService: Sent text message');
  }

  /// Signal end of audio input (user stopped speaking)
  void endAudioInput() {
    if (!_isConnected || _channel == null) return;

    final message = {
      'clientContent': {'turnComplete': true},
    };

    _channel!.sink.add(jsonEncode(message));
    debugPrint('GeminiLiveService: Audio input ended');
  }

  /// Disconnect from Gemini Live API
  Future<void> disconnect() async {
    if (_channel != null) {
      debugPrint('GeminiLiveService: Disconnecting...');
      await _channel!.sink.close();
      _channel = null;
    }
    _isConnected = false;
  }

  /// Dispose of resources
  void dispose() {
    disconnect();
    _eventController.close();
  }
}
