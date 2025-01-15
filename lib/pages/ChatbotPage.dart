import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _chatHistory = [];
  String apiKey = ""; // Add your actual API key here
  final ScrollController _scrollController = ScrollController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechInitialized = false;



  @override
  void initState() {
    super.initState();
    _fetchApiKey();
    _initSpeech();
  }
  Future<void> _initSpeech() async {
    try {
      _speechInitialized = await _speech.initialize(
        onError: (error) => print('Speech to text error: $error'),
        onStatus: (status) {
          print('Speech to text status: $status');
          if (status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
      );
      setState(() {});
    } catch (e) {
      print('Speech initialization error: $e');
      _speechInitialized = false;
      setState(() {});
    }
  }

  Future<void> _toggleListening() async {
    if (!_speechInitialized) {
      await _initSpeech();
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      if (_speechInitialized) {
        setState(() => _isListening = true);
        try {
          await _speech.listen(
            onResult: (result) {
              setState(() {
                _messageController.text = result.recognizedWords;
                if (result.finalResult) {
                  _isListening = false;
                  if (_messageController.text.isNotEmpty) {
                    _sendMessage(_messageController.text);
                    _messageController.clear();
                  }
                }
              });
            },
          );
        } catch (e) {
          print('Error starting speech recognition: $e');
          setState(() => _isListening = false);
        }
      } else {
        print('Speech recognition not initialized');
        // Optionally show a snackbar or alert to the user
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition not available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _fetchApiKey() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.fetchAndActivate();
      final fetchedApiKey = remoteConfig.getString('gemini');
      if (fetchedApiKey.isNotEmpty) {
        setState(() {
          apiKey = fetchedApiKey;
        });
      } else {
        print("API key not available in Remote Config");
      }
    } catch (e) {
      print("Error fetching API key: $e");
    }
  }

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({"role": "user", "content": message});
      _chatHistory.add({"role": "bot", "content": "typing..."});
    });

    if (apiKey.isEmpty) {
      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({
          "role": "bot",
          "content": "API key is not available. Please try again later."
        });
      });
      return;
    }

    // Fetch user details from Firebase
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() {
          _chatHistory.removeLast();
          _chatHistory.add({
            "role": "bot",
            "content": "Please login to continue."
          });
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!userDoc.exists) {
        setState(() {
          _chatHistory.removeLast();
          _chatHistory.add({
            "role": "bot",
            "content": "User profile not found."
          });
        });
        return;
      }

      final userData = userDoc.data()!;

      // Build conversation history for context
      List<Map<String, String>> conversationHistory = _chatHistory
          .where((msg) => msg["content"] != "typing...")
          .take(_chatHistory.length - 2) // Exclude the current message and typing indicator
          .toList();

      final url = Uri.parse(
          "https://generativelanguage.googleapis.com/v1beta/tunedModels/medicalchatbotvitalia-3lhnnicj69h6:generateContent?key=$apiKey");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
User Profile:
Name: ${userData['fullName'] ?? 'Not provided'}
Gender: ${userData['gender'] ?? 'Not provided'}
Age/DOB: ${userData['dob'] ?? 'Not provided'}
Blood Group: ${userData['bloodGroup'] ?? 'Not provided'}
Height: ${userData['height'] ?? 'Not provided'} cm
Weight: ${userData['weight'] ?? 'Not provided'} kg
Blood Pressure: ${userData['bloodPressure'] ?? 'Not provided'} mmHg
Pulse Rate: ${userData['pulseRate'] ?? 'Not provided'} bpm
Medical Conditions: ${(userData['conditions'] as List?)?.join(', ') ?? 'None'}
Current Medications: ${userData['medications'] ?? 'None'}
Allergies: ${(userData['allergies'] as List?)?.join(', ') ?? 'None'}

Previous Conversation:
${conversationHistory.map((msg) => "${msg['role'] == 'user' ? 'User' : 'Assistant'}: ${msg['content']}").join('\n')}

Current User Message: $message"""
                }
              ]
            }
          ],

          "generationConfig": {
            "temperature": 0.7,
            "topK": 40,
            "topP": 0.95,
            "maxOutputTokens": 1024,
          }
        }),
      );

      setState(() {
        _chatHistory.removeLast(); // Remove typing indicator
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["candidates"] != null && data["candidates"].isNotEmpty) {
          final reply = data["candidates"][0]["content"]["parts"][0]["text"] ??
              "No response from Gemini";
          setState(() {
            _chatHistory.add({"role": "bot", "content": reply});
          });
        } else {
          setState(() {
            _chatHistory.add({
              "role": "bot",
              "content": "Sorry, I couldn't process that response."
            });
          });
        }
      } else {
        print("API Error: ${response.statusCode} - ${response.body}");
        setState(() {
          _chatHistory.add({
            "role": "bot",
            "content": "Sorry, I encountered an error. Please try again."
          });
        });
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        _chatHistory.removeLast();
        _chatHistory.add({
          "role": "bot",
          "content": "An error occurred. Please try again later."
        });
      });
    }

    _scrollToBottom();
  }
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildFormattedText(String text) {
    List<InlineSpan> children = [];
    final regex = RegExp(r"(\*\*[^*]+\*\*)|([^*]+)");
    final matches = regex.allMatches(text);

    for (var match in matches) {
      if (match.group(0)!.startsWith("**")) {
        children.add(TextSpan(
          text: match.group(0)!.substring(2, match.group(0)!.length - 2),
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ));
      } else {
        children.add(TextSpan(
          text: match.group(0),
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.normal,
            color: Colors.white,
            fontSize: 15,
          ),
        ));
      }
    }

    return RichText(
      text: TextSpan(children: children),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.blue.shade100,
            ],
          ),
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back,
                            color: Colors.blue.shade700),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Chat with VitalAI",
                            style: GoogleFonts.nunito(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  final isUser = chat["role"] == "user";

                  if (chat["content"] == "typing...") {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/icons/chatbot1.png',
                                    fit: BoxFit.cover,
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade400,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: const [
                                    DotWidget(),
                                    DotWidget(delay: Duration(milliseconds: 200)),
                                    DotWidget(delay: Duration(milliseconds: 400)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isUser)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white,
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/icons/chatbot1.png',
                                  fit: BoxFit.cover,
                                  width: 40,
                                  height: 40,
                                ),
                              ),
                            ),
                          ),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Colors.blue.shade600
                                  : Colors.blue.shade400,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isUser
                                    ? const Radius.circular(20)
                                    : const Radius.circular(5),
                                bottomRight: isUser
                                    ? const Radius.circular(5)
                                    : const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildFormattedText(chat["content"] ?? ""),
                          ),
                        ),
                        if (isUser)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: _toggleListening,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText:_isListening
                            ? "Listening..."
                            : "Type your message...",
                        hintStyle: GoogleFonts.nunito(
                          color: Colors.grey.shade600,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide(
                            color: Colors.blue.shade400,
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: () {
                          String message = _messageController.text;
                          _messageController.clear();
                          _sendMessage(message);
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(12),
                          child: Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DotWidget extends StatefulWidget {
  final Duration delay;
  const DotWidget({Key? key, this.delay = const Duration(milliseconds: 0)})
      : super(key: key);

  @override
  _DotWidgetState createState() => _DotWidgetState();
}

class _DotWidgetState extends State<DotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(
        Tween(begin: 0.2, end: 1.0).chain(
          CurveTween(curve: Interval(0, 1.0, curve: Curves.easeInOut)),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
