import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchApiKey();
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
        _chatHistory.removeLast(); // Remove the typing indicator
        _chatHistory.add({
          "role": "bot",
          "content": "API key is not available. Please try again later."
        });
      });
      return;
    }

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/tunedModels/medicalchatbotvitalia-3lhnnicj69h6:generateContent?key=$apiKey");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": message}
              ]
            }
          ]
        }),
      );

      setState(() {
        _chatHistory.removeLast(); // Remove the typing indicator
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["candidates"] != null && data["candidates"].isNotEmpty) {
          var reply =
              data["candidates"][0]["content"]["parts"][0]["text"] ??
                  "No response from Gemini";
          reply = reply.length > 150 ? "${reply.substring(0, 150)}..." : reply;

          setState(() {
            _chatHistory.add({"role": "bot", "content": reply});
          });
        } else {
          setState(() {
            _chatHistory.add({
              "role": "bot",
              "content": "No valid response returned from Gemini."
            });
          });
        }
      } else {
        setState(() {
          _chatHistory.add({
            "role": "bot",
            "content": "Error ${response.statusCode}: ${response.body}",
          });
        });
      }
    } catch (e) {
      setState(() {
        _chatHistory.removeLast(); // Remove the typing indicator
        _chatHistory.add({"role": "bot", "content": "Error: $e"});
      });
    }
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
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
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
