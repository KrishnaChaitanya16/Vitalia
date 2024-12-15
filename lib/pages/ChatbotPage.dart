import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, String>> _chatHistory = [];
  final String apiKey = "AIzaSyDAeziBDdB9NcfUXNo5f_rTINVB6-CyoHE"; // Replace with your actual API key

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _chatHistory.add({"role": "user", "content": message});
    });

    final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$apiKey");

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
        _chatHistory.add({"role": "bot", "content": "Error: $e"});
      });
    }
  }

  Widget _buildFormattedText(String text) {
    List<InlineSpan> children = [];
    final regex = RegExp(r"(\*\*[^*]+\*\*)|([^*]+)");
    final matches = regex.allMatches(text);

    for (var match in matches) {
      if (match.group(0)!.startsWith("**")) {
        children.add(TextSpan(
          text: match.group(0)!.substring(2, match.group(0)!.length - 2),
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Colors.white),
        ));
      } else {
        children.add(TextSpan(
          text: match.group(0),
          style: const TextStyle(
              fontWeight: FontWeight.normal, color: Colors.white),
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
        decoration: const BoxDecoration(
          color: Color(0xFFE3F2FD), // Set the entire background to a light blue color
        ),
        child: Column(
          children: [
            AppBar(
              title: Text(
                "Chat with VitalAI",
                style: GoogleFonts.nunito(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.white,
              elevation: 4.0, // Adds shadow below the AppBar
              centerTitle: true,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  final isUser = chat["role"] == "user";
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: Row(
                      mainAxisAlignment: isUser
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                        // Replace with your custom bot avatar
                          CircleAvatar(
                            backgroundColor: Colors.greenAccent.shade200
                            ,
                            child: Image.asset('assets/icons/android.png',fit: BoxFit.contain,), // Custom bot icon
                          ),
                        if (!isUser) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF79A5EC).withOpacity(1)
                                  : Colors.blueAccent.withOpacity(0.9),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(20),
                                topRight: const Radius.circular(20),
                                bottomLeft: isUser
                                    ? const Radius.circular(20)
                                    : Radius.zero,
                                bottomRight: isUser
                                    ? Radius.zero
                                    : const Radius.circular(20),
                              ),
                            ),
                            child: _buildFormattedText(chat["content"] ?? ""),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser)
                        // Replace with your custom user avatar
                          CircleAvatar(
                            backgroundColor: Colors.lightBlueAccent.shade200,
                            child: Icon(Icons.person,), // Custom user icon
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: "Type your message...",
                        hintStyle: GoogleFonts.nunito(),
                        filled: true,
                        fillColor: Colors.grey[300], // Slightly darker input field
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: GoogleFonts.nunito(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: () {
                        String message = _messageController.text;
                        _messageController.clear();
                        _sendMessage(message);
                      },
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
