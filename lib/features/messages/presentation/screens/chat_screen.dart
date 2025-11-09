/// Feature: Messages
/// Screen: ChatScreen with Multimedia Support
///
/// Displays conversations with support for:
/// - Text messages
/// - Images (camera + gallery)
/// - Videos (camera + gallery)
/// - Voice recordings
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:escort/services/conversations_service.dart';
import 'package:escort/services/user_session.dart';
import 'package:escort/services/socket_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:path_provider/path_provider.dart';

// Add helper import (relative to this file)
import '../helpers/platform_file_creator.dart';

class ChatScreen extends StatefulWidget {
  final int conversationId;
  final String? title;
  final String? otherParticipantName;
  final String? otherParticipantAvatar;
  
  const ChatScreen({
    super.key,
    required this.conversationId,
    this.title,
    this.otherParticipantName,
    this.otherParticipantAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  List<Map<String, dynamic>> messages = [];
  bool loading = true;
  Timer? _poller;
  bool _sending = false;
  bool _isRecording = false;
  Timer? _typingTimer;
  int? currentUserId;
  String? currentUserType;
  String? otherParticipantName;
  String? otherParticipantAvatar;
  String? _recordingPath;
  Timer? _recordingDurationTimer;
  int _recordingDuration = 0;

  @override
  void initState() {
    super.initState();
    otherParticipantName = widget.otherParticipantName;
    otherParticipantAvatar = widget.otherParticipantAvatar;
    _loadCurrentUser();
    _load();
    _setupWebSocket();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final uidDyn = await UserSession.getUserId();
      final uid = int.tryParse(uidDyn.toString());
      final userType = await UserSession.getUserType();
      
      String normalizedType = _normalizeSenderType(userType ?? 'user');
      
      if (mounted) {
        setState(() {
          currentUserId = uid;
          currentUserType = normalizedType;
        });
      }
    } catch (e) {
      print('[ChatScreen] Error loading current user: $e');
      if (mounted) {
        setState(() {
          currentUserType = 'user';
        });
      }
    }
  }

  void _setupWebSocket() {
    try {
      SocketService.joinConversation(widget.conversationId);

      SocketService.onNewMessage((payload) {
        final convId = int.tryParse((payload['conversation_id'] ?? '').toString());
        if (convId == widget.conversationId) {
          if (mounted) {
            setState(() {
              messages.add(payload);
            });
            _scrollToBottom();
            _markAsRead();
          }
        }
      });

      SocketService.onMessageUpdated((payload) {
        final convId = int.tryParse((payload['conversation_id'] ?? '').toString());
        if (convId == widget.conversationId) {
          if (mounted) {
            setState(() {
              final index = messages.indexWhere((m) => m['id'] == payload['message_id']);
              if (index != -1) {
                messages[index].addAll(payload);
              }
            });
          }
        }
      });

      SocketService.onMessageDeleted((payload) {
        final convId = int.tryParse((payload['conversation_id'] ?? '').toString());
        if (convId == widget.conversationId) {
          if (mounted) {
            setState(() {
              messages.removeWhere((m) => m['id'] == payload['message_id']);
            });
          }
        }
      });
    } catch (e) {
      print('[ChatScreen] Error setting up WebSocket: $e');
    }

    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load());
  }

  Future<void> _load() async {
    try {
      final msgs = await ConversationsService.getMessages(widget.conversationId);
      if (!mounted) return;
      
      if (otherParticipantName == null && msgs.isNotEmpty) {
        for (var msg in msgs) {
          final senderId = int.tryParse((msg['sender_id'] ?? '').toString());
          final rawSenderType = (msg['sender_type'] ?? 'user').toString();
          final senderType = _normalizeSenderType(rawSenderType);
          
          if (senderId != currentUserId || senderType != currentUserType) {
            final sender = msg['sender'] as Map<String, dynamic>?;
            if (sender != null) {
              otherParticipantName = (sender['name'] ?? sender['username'] ?? 'User').toString();
              otherParticipantAvatar = sender['profile_image_url']?.toString();
              break;
            }
          }
        }
      }
      
      setState(() {
        messages = msgs;
        loading = false;
      });
      
      _scrollToBottom();
      await _markAsRead();
      
    } catch (e) {
      print('[ChatScreen] Error loading messages: $e');
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _markAsRead() async {
    try {
      await ConversationsService.markConversationAsRead(widget.conversationId);
    } catch (e) {
      print('[ChatScreen] Error marking as read: $e');
    }
  }

  String _normalizeSenderType(String type) {
    final normalized = type.toLowerCase();
    if (normalized == 'advertiser' || 
        normalized == 'escort' || 
        normalized == 'provider') {
      return 'advertiser';
    }
    return 'user';
  }

  bool _isMessageFromCurrentUser(int? senderId, String rawSenderType) {
    if (currentUserId == null || currentUserType == null) {
      return false;
    }
    
    final senderType = _normalizeSenderType(rawSenderType);
    return senderId == currentUserId && senderType == currentUserType;
  }

  void _onTyping() {
    _typingTimer?.cancel();
    _getAndEmitTyping();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _getAndEmitStopTyping();
    });
  }

  Future<void> _getAndEmitTyping() async {
    try {
      final uidDyn = await UserSession.getUserId();
      final uid = int.tryParse(uidDyn.toString());
      if (uid != null) {
        SocketService.emitTyping(widget.conversationId, uid, currentUserType ?? 'user');
      }
    } catch (e) {
      print('[ChatScreen] Error emitting typing: $e');
    }
  }

  Future<void> _getAndEmitStopTyping() async {
    try {
      final uidDyn = await UserSession.getUserId();
      final uid = int.tryParse(uidDyn.toString());
      if (uid != null) {
        SocketService.emitStopTyping(widget.conversationId, uid);
      }
    } catch (e) {
      print('[ChatScreen] Error emitting stop typing: $e');
    }
  }

  // ========== MULTIMEDIA FUNCTIONS ==========

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (kIsWeb) {
          // For web, read bytes and create a web File via helper
          final bytes = await image.readAsBytes();
          final file = await createPlatformFile(bytes, image.name);
          await _sendMediaMessage(file, 'image');
        } else {
          // For mobile/desktop, use File from path
          final file = createPlatformFileFromPath(image.path);
          await _sendMediaMessage(file, 'image');
        }
      }
    } catch (e) {
      print('[ChatScreen] Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      
      if (video != null) {
        if (kIsWeb) {
          // For web, read bytes and create a web File via helper
          final bytes = await video.readAsBytes();
          final file = await createPlatformFile(bytes, video.name);
          await _sendMediaMessage(file, 'video');
        } else {
          // For mobile/desktop, use File from path
          final file = createPlatformFileFromPath(video.path);
          await _sendMediaMessage(file, 'video');
        }
      }
    } catch (e) {
      print('[ChatScreen] Error picking video: $e');
      _showErrorSnackBar('Failed to pick video');
    }
  }

  // REPLACE the _startRecording() method with this fixed version:

// REPLACE the _startRecording() method with this:

Future<void> _startRecording() async {
  try {
    if (await _audioRecorder.hasPermission()) {
      String path;
      
      try {
        if (kIsWeb) {
          // For web, use a simple path without extension
          path = 'web_audio_${DateTime.now().millisecondsSinceEpoch}';
        } else {
          // Try to get temporary directory for mobile/desktop
          final directory = await getTemporaryDirectory();
          path = '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
      } catch (e) {
        print('[ChatScreen] Warning: Directory failed: $e');
        if (!kIsWeb) {
          try {
            final appDocDir = await getApplicationDocumentsDirectory();
            path = '${appDocDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
          } catch (e2) {
            _showErrorSnackBar('Unable to access file storage');
            return;
          }
        } else {
          _showErrorSnackBar('Web recording not available');
          return;
        }
      }
      
      // Use platform-appropriate encoder
      final RecordConfig config = kIsWeb
          ? const RecordConfig(
              encoder: AudioEncoder.opus,
              bitRate: 128000,
              sampleRate: 44100,
            )
          : const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 128000,
              sampleRate: 44100,
            );
      
      await _audioRecorder.start(config, path: path);
      
      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = 0;
      });
      
      // Start duration timer
      _recordingDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration++;
          });
        }
      });
      
      print('[ChatScreen] Recording started with encoder: ${kIsWeb ? 'opus' : 'aacLc'}');
    } else {
      _showErrorSnackBar('Microphone permission required');
    }
  } catch (e) {
    print('[ChatScreen] Error starting recording: $e');
    _showErrorSnackBar('Failed to start recording: ${e.toString()}');
  }
}

// ALSO ADD this import at the top of your file if not already present:
// import 'package:path_provider/path_provider.dart';
// (it should already be there)

// ADD this additional import for getApplicationDocumentsDirectory:
// Add to imports section:


  Future<void> _stopRecording() async {
  try {
    _recordingDurationTimer?.cancel();
    final path = await _audioRecorder.stop();
    
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
    
    if (path != null && path.isNotEmpty) {
      final file = createPlatformFileFromPath(path);
      await _sendMediaMessage(file, 'audio');
    } else {
      _showErrorSnackBar('Failed to save recording');
    }
  } catch (e) {
    print('[ChatScreen] Error stopping recording: $e');
    _showErrorSnackBar('Failed to stop recording');
    setState(() {
      _isRecording = false;
      _recordingDuration = 0;
    });
  }
}
  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      
      _recordingDurationTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
        _recordingPath = null;
      });
    } catch (e) {
      print('[ChatScreen] Error canceling recording: $e');
    }
  }

  // change the parameter type to dynamic to avoid cross-platform static issues
  Future<void> _sendMediaMessage(dynamic file, String mediaType) async {
    if (currentUserId == null || currentUserType == null) {
      _showErrorSnackBar('User information not loaded');
      return;
    }

    setState(() => _sending = true);

    try {
      await ConversationsService.sendMediaMessage(
        conversationId: widget.conversationId,
        senderId: currentUserId!,
        senderType: currentUserType!,
        file: file,
        mediaType: mediaType,
        content: '', // Optional caption
      );
      
      await _load();
      _scrollToBottom();
    } catch (e) {
      print('[ChatScreen] Error sending media: $e');
      _showErrorSnackBar('Failed to send $mediaType');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.green),
                  title: const Text('Choose Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.red),
                  title: const Text('Record Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.video_library, color: Colors.orange),
                  title: const Text('Choose Video'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickVideo(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ========== TEXT MESSAGE SENDING ==========

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final uidDyn = await UserSession.getUserId();
    final uid = int.tryParse(uidDyn.toString());
    if (uid == null || currentUserType == null) {
      _showErrorSnackBar('Error: Could not identify user');
      return;
    }

    setState(() => _sending = true);
    _controller.clear();

    _typingTimer?.cancel();
    SocketService.emitStopTyping(widget.conversationId, uid);

    try {
      await ConversationsService.sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        senderType: currentUserType!,
        content: text,
      );
      
      await _load();
      _scrollToBottom();
    } catch (e) {
      print('[ChatScreen] Error sending message: $e');
      _showErrorSnackBar('Failed to send message');
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    
    try {
      final dt = DateTime.parse(timestamp).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDate = DateTime(dt.year, dt.month, dt.day);

      if (msgDate == today) {
        final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '${hour}:${dt.minute.toString().padLeft(2, '0')} $period';
      } else {
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _poller?.cancel();
    _typingTimer?.cancel();
    _recordingDurationTimer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    _audioRecorder.dispose();
    try {
      SocketService.leaveConversation(widget.conversationId);
      SocketService.offNewMessage();
      SocketService.offMessageUpdated();
      SocketService.offMessageDeleted();
    } catch (e) {
      print('[ChatScreen] Error in dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final displayTitle = otherParticipantName != null
        ? 'Chatting with $otherParticipantName'
        : (widget.title ?? 'Chat');
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              backgroundImage: otherParticipantAvatar != null &&
                      otherParticipantAvatar!.isNotEmpty
                  ? NetworkImage(otherParticipantAvatar!)
                  : null,
              child: otherParticipantAvatar == null ||
                      otherParticipantAvatar!.isEmpty
                  ? Text(
                      otherParticipantName != null && otherParticipantName!.isNotEmpty
                          ? otherParticipantName![0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayTitle,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: loading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: messages.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No messages yet',
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: messages.length,
                            itemBuilder: (context, i) => _buildMessageBubble(messages[i], colorScheme),
                          ),
                        ),
                ),
                // Recording indicator
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.red.withOpacity(0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Recording: ${_formatDuration(_recordingDuration)}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _cancelRecording,
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: _stopRecording,
                        ),
                      ],
                    ),
                  ),
                // Message input
                _buildMessageInput(colorScheme),
              ],
            ),
    );
  }

  Widget _buildMessageInput(ColorScheme colorScheme) {
    final hasText = _controller.text.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Media button
            IconButton(
              icon: Icon(Icons.attach_file, color: colorScheme.primary),
              onPressed: _sending || _isRecording ? null : _showMediaOptions,
            ),
            // Text input
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (_) {
                  _onTyping();
                  setState(() {}); // Rebuild to update button visibility
                },
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                minLines: 1,
                maxLength: 1000,
                buildCounter: (context,
                        {required currentLength,
                        required isFocused,
                        maxLength}) =>
                    null,
                enabled: !_sending && !_isRecording,
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 4),
            // Voice recording button OR Send button
            if (!hasText && !_sending)
              // Voice recording button (when text is empty)
              IconButton(
                icon: Icon(
                  _isRecording ? Icons.stop : Icons.mic,
                  color: _isRecording ? Colors.red : colorScheme.primary,
                ),
                onPressed: _isRecording ? _stopRecording : _startRecording,
              )
            else
              // Send button (when text exists or sending)
              Container(
                decoration: BoxDecoration(
                  color: _sending
                      ? colorScheme.primary.withOpacity(0.5)
                      : colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _sending
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send_rounded,
                          color: colorScheme.onPrimary,
                          size: 20,
                        ),
                  onPressed: _sending ? null : _send,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> m, ColorScheme colorScheme) {
    final content = (m['content'] ?? '').toString();
    final ts = (m['created_at'] ?? '').toString();
    final messageType = (m['message_type'] ?? 'text').toString();
    final mediaUrl = m['media_url']?.toString();
    final thumbnailUrl = m['thumbnail_url']?.toString();
    final metadata = m['media_metadata'] as Map<String, dynamic>?;
    
    final senderId = int.tryParse((m['sender_id'] ?? '').toString());
    final rawSenderType = (m['sender_type'] ?? 'user').toString();
    
    final sender = m['sender'] as Map<String, dynamic>? ?? {};
    final senderName = (sender['name'] ?? sender['username'] ?? 'Unknown').toString();
    final senderAvatar = sender['profile_image_url']?.toString();
    
    final isMe = _isMessageFromCurrentUser(senderId, rawSenderType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              backgroundImage: senderAvatar != null && senderAvatar.isNotEmpty
                  ? NetworkImage(senderAvatar)
                  : null,
              child: senderAvatar == null || senderAvatar.isEmpty
                  ? Text(
                      senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: EdgeInsets.all(messageType == 'text' ? 12 : 4),
                  decoration: BoxDecoration(
                    color: isMe
                        ? colorScheme.primary
                        : colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: _buildMessageContent(
                    messageType,
                    content,
                    mediaUrl,
                    thumbnailUrl,
                    metadata,
                    isMe,
                    colorScheme,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatMessageTime(ts),
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(
    String messageType,
    String content,
    String? mediaUrl,
    String? thumbnailUrl,
    Map<String, dynamic>? metadata,
    bool isMe,
    ColorScheme colorScheme,
  ) {
    switch (messageType) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  mediaUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      
      case 'video':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (mediaUrl != null)
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: thumbnailUrl != null
                        ? Image.network(thumbnailUrl, height: 200, fit: BoxFit.cover)
                        : Container(
                            height: 200,
                            color: Colors.black26,
                            child: const Icon(Icons.videocam, size: 64, color: Colors.white),
                          ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled, size: 64, color: Colors.white),
                    onPressed: () {
                      // Open video player
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VideoPlayerScreen(videoUrl: mediaUrl),
                        ),
                      );
                    },
                  ),
                ],
              ),
            if (content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                  color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      
      case 'audio':
        return AudioMessageWidget(
          audioUrl: mediaUrl ?? '',
          duration: metadata?['duration']?.toDouble() ?? 0.0,
          isMe: isMe,
          colorScheme: colorScheme,
        );
      
      case 'text':
      default:
        return Text(
          content,
          style: TextStyle(
            color: isMe ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontSize: 15,
            height: 1.4,
          ),
        );
    }
  }
}

// ========== VIDEO PLAYER SCREEN ==========
class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: _isInitialized
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

// ========== AUDIO MESSAGE WIDGET ==========
class AudioMessageWidget extends StatefulWidget {
  final String audioUrl;
  final double duration;
  final bool isMe;
  final ColorScheme colorScheme;

  const AudioMessageWidget({
    super.key,
    required this.audioUrl,
    required this.duration,
    required this.isMe,
    required this.colorScheme,
  });

  @override
  State<AudioMessageWidget> createState() => _AudioMessageWidgetState();
}

class _AudioMessageWidgetState extends State<AudioMessageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });
  }

  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play(UrlSource(widget.audioUrl));
      }
    } catch (e) {
      print('[AudioMessageWidget] Error toggling playback: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.isMe ? widget.colorScheme.onPrimary : widget.colorScheme.primary,
            ),
            onPressed: _togglePlayback,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                    activeTrackColor: widget.isMe
                        ? widget.colorScheme.onPrimary
                        : widget.colorScheme.primary,
                    inactiveTrackColor: widget.isMe
                        ? widget.colorScheme.onPrimary.withOpacity(0.3)
                        : widget.colorScheme.primary.withOpacity(0.3),
                    thumbColor: widget.isMe
                        ? widget.colorScheme.onPrimary
                        : widget.colorScheme.primary,
                  ),
                  child: Slider(
                    value: _currentPosition.inSeconds.toDouble(),
                    max: _totalDuration.inSeconds.toDouble() > 0
                        ? _totalDuration.inSeconds.toDouble()
                        : 1,
                    onChanged: (value) async {
                      await _audioPlayer.seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Text(
                  '${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}',
                  style: TextStyle(
                    color: widget.isMe
                        ? widget.colorScheme.onPrimary.withOpacity(0.8)
                        : widget.colorScheme.onSurfaceVariant.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}