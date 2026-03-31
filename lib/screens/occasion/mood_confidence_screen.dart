import 'package:flutter/material.dart';

class MoodConfidenceScreen extends StatefulWidget {
  const MoodConfidenceScreen({super.key});

  @override
  State<MoodConfidenceScreen> createState() => _MoodConfidenceScreenState();
}

class _MoodConfidenceScreenState extends State<MoodConfidenceScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSubmit() {
    setState(() => _submitted = true);
    FocusScope.of(context).unfocus();
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        Navigator.pushNamed(context, '/outfit-recommendation');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(title: const Text('Tune Your Look')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Any other specifications?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _onSubmit(),
                decoration: InputDecoration(
                  hintText: 'e.g. prefer bright colors, no prints, formal',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE2DED5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: Color(0xFFE2DED5)),
                  ),
                ),
                minLines: 1,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _submitted ? null : _onSubmit,
                  child: Text(_submitted ? 'Styling you...' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
