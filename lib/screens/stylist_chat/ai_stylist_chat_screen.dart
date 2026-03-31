import 'package:flutter/material.dart';
import '../../services/mistral_service.dart';

class AiStylistChatScreen extends StatefulWidget {
  const AiStylistChatScreen({super.key});

  @override
  State<AiStylistChatScreen> createState() => _AiStylistChatScreenState();
}

class _AiStylistChatScreenState extends State<AiStylistChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _messages = [
    'Hello! I\'m your FYT stylist. How can I help you today?',
  ];
  bool _isTyping = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final userMessage = _controller.text.trim();
    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isTyping = true;
    });
    
    try {
      // Try to get AI response from Mistral
      final aiResponse = await MistralService.getStylingAdvice(
        userMessage,
        userBodyType: 'Rectangle', // Could get from user profile
        wardrobeContext: [], // Could get from user's wardrobe
      );
      
      if (mounted) {
        setState(() {
          _messages.add(aiResponse);
          _isTyping = false;
        });
      }
    } catch (e) {
      // Fallback to rule-based responses if API fails
      if (mounted) {
        setState(() {
          _messages.add(_getFallbackResponse(userMessage));
          _isTyping = false;
        });
      }
    }
  }

  String _getFallbackResponse(String userMessage) {
    final msg = userMessage.toLowerCase();
    
    if (msg.contains('color') || msg.contains('colour')) {
      return "Great color question! Some classic pairings: Navy + White, Black + Camel, Olive + Cream. For bold looks try Cobalt Blue + Mustard. Neutrals like beige, grey, and white pair with almost anything!";
    } else if (msg.contains('formal') || msg.contains('office') || msg.contains('work')) {
      return "For formal/office wear: stick to tailored fits, solid colors or subtle patterns. A well-fitted blazer elevates any outfit. Classic choices: navy suit, white shirt, or a pencil skirt with a blouse.";
    } else if (msg.contains('casual') || msg.contains('weekend')) {
      return "For casual style: comfort meets style! Try well-fitted jeans with a clean tee, or a flowy sundress. Layer with a denim jacket. White sneakers are universally versatile!";
    } else if (msg.contains('body') || msg.contains('shape') || msg.contains('figure')) {
      return "Dress for YOUR body! Pear shape: A-line skirts, wide necklines. Apple shape: empire waist, wrap dresses. Hourglass: fitted waist styles. Rectangle: add curves with ruffles or belts. All bodies are beautiful - wear what makes you confident!";
    } else if (msg.contains('party') || msg.contains('night out') || msg.contains('club')) {
      return "For a party look: go bold! A fitted dress, or high-waist pants with a crop top. Add statement jewelry. Metallic fabrics or sequins work great for evening events. Don't forget a clutch!";
    } else if (msg.contains('wedding') || msg.contains('festive') || msg.contains('traditional')) {
      return "For weddings/festive occasions: sarees, lehengas, or anarkalis are stunning traditional choices. For Western: a midi dress in jewel tones (emerald, burgundy, royal blue) is elegant. Avoid white at weddings!";
    } else if (msg.contains('summer') || msg.contains('hot') || msg.contains('heat')) {
      return "Summer styling: Choose breathable fabrics like cotton, linen, chambray. Light colors reflect heat. Flowy silhouettes keep you cool. Maxi dresses, linen pants, and cotton shorts are summer staples!";
    } else if (msg.contains('winter') || msg.contains('cold')) {
      return "Winter layering: Start with a base layer, add a knit sweater or turtleneck, top with a coat. Earthy tones and jewel colors work beautifully. Don't forget scarves and boots to complete the look!";
    } else if (msg.contains('accessory') || msg.contains('accessories') || msg.contains('jewel')) {
      return "Accessory tips: Less is more for formal. For casual, stack bracelets or layer necklaces. Match metal tones (gold or silver, not both). A statement bag or bold earrings can transform a simple outfit!";
    } else if (msg.contains('shoe') || msg.contains('shoes') || msg.contains('footwear')) {
      return "Shoe styling: White sneakers go with almost everything casual. Block heels are comfortable and stylish. Ankle boots elevate any outfit. For formal: pointed pumps or Oxford shoes are classic choices.";
    } else {
      return "As your AI stylist, I suggest building a capsule wardrobe with versatile basics: a white shirt, well-fitting jeans, a blazer, a little black dress, and comfortable flats. From these, you can create 20+ outfits! What specific style challenge can I help you with?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EA),
      appBar: AppBar(title: const Text('AI Stylist')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  // Show typing indicator
                  if (_isTyping && index == _messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF777777)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'AI is typing...',
                              style: TextStyle(
                                color: Color(0xFF777777),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  final isUser = index % 2 == 1;
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? const Color(0xFFD8D4F2) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        _messages[index],
                        style: TextStyle(
                          color: isUser ? const Color(0xFF333333) : const Color(0xFF777777),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE2DED5)),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask your stylist...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send_rounded),
                    color: const Color(0xFFD8D4F2),
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
