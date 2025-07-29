import 'package:flutter/material.dart';
import 'package:brightacts_frontend_app/models/tech_system.dart'; // Import TechSystem from its new central location

class CodeDisplayPage extends StatelessWidget {
  final String title;
  final TechSystem system; // Now correctly using TechSystem from models/tech_system.dart

  const CodeDisplayPage({super.key, required this.title, required this.system});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: RichText(
                text: _PythonSyntaxHighlighter.highlight(system.code),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Simple Python Syntax Highlighter ---

class _PythonSyntaxHighlighter {
  static TextSpan highlight(String code) {
    // Definitive fix for the RegExp pattern:
    // Using a standard triple-quote string ('''...''') and manually escaping all backslashes (\\).
    // This approach often bypasses subtle parsing issues encountered with raw string literals (r'...')
    // for complex or very long regex patterns.
    final RegExp regex = RegExp(
      '''("""[\\s\\S]*?"""|\\'\\'\\'[\\s\\S]*?\\'\\'\\'|"[^"\\n]*"|'[^'\\n]*'|''' + // Strings (multi-line and single-line)
      '''\\b\\d+\\b|''' + // Numbers
      '''#.*|''' + // Comments
      '''@\\w+|''' + // Decorators
      '''\\b(?:def|class|return|if|else|elif|for|while|import|from|as|try|except|with|lambda|pass|break|continue|and|or|not|in|is|None|True|False)\\b''' // Python Keywords
    , multiLine: true);

    final List<TextSpan> spans = [];
    int currentIndex = 0;

    final matches = regex.allMatches(code);
    for (final match in matches) {
      if (match.start > currentIndex) {
        spans.add(TextSpan(
          text: code.substring(currentIndex, match.start),
          style: const TextStyle(color: Colors.black), // Default text color
        ));
      }

      final String matchText = match.group(0)!;
      TextStyle style;

      if (matchText.startsWith('"""') || matchText.startsWith("'''") || matchText.startsWith('"') || matchText.startsWith("'")) {
        style = const TextStyle(color: Colors.green); // Strings
      } else if (matchText.startsWith('#')) {
        style = const TextStyle(color: Colors.grey); // Comments
      } else if (matchText.startsWith('@')) {
        style = const TextStyle(color: Colors.deepPurple); // Decorators
      } else if (RegExp(r'^\d+$').hasMatch(matchText)) {
        style = const TextStyle(color: Colors.orange); // Numbers
      } else {
        // Keywords (def, class, return, etc.)
        style = const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold);
      }

      spans.add(TextSpan(text: matchText, style: style));
      currentIndex = match.end;
    }

    if (currentIndex < code.length) {
      spans.add(TextSpan(
        text: code.substring(currentIndex),
        style: const TextStyle(color: Colors.black), // Remaining default text
      ));
    }

    return TextSpan(children: spans);
  }
}

