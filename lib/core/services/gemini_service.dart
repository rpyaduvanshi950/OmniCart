import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_strings.dart';

class GeminiService {
  static GeminiService? _instance;
  late final GenerativeModel _model;
  late final ChatSession _chat;

  GeminiService._() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    _model = GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
      systemInstruction: Content.system(AppStrings.geminiSystemPrompt),
    );
    _chat = _model.startChat();
  }

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  Future<String> sendMessage(String message) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      return 'Gemini API key is missing. Add GEMINI_API_KEY=<your-key> to your .env file.';
    }
    try {
      // Append reminder on every real user turn (not the memory priming message)
      final augmented = message.startsWith('__MEMORY_CONTEXT__')
          ? message
          : '$message\n\n[REMINDER: You MUST append a <products>[{"name":"...","category":"...","query":"1-2 words","maxPriceInr":0}]</products> block if any products are mentioned. Set maxPriceInr to the user\'s budget in ₹ if they mentioned one, else 0. Valid categories: laptops,smartphones,tablets,mobile-accessories,mens-watches,womens-watches,mens-shoes,womens-shoes,mens-shirts,tops,womens-dresses,sunglasses,beauty,skin-care,fragrances,groceries,kitchen-accessories,furniture,home-decoration,sports-accessories,motorcycle,vehicle,womens-bags,womens-jewellery]';
      final response = await _chat.sendMessage(Content.text(augmented));
      return response.text ?? 'Sorry, I could not understand that.';
    } catch (e) {
      return 'AI error: ${e.toString()}';
    }
  }

  Future<String> generateProductDescription(String productName, String category) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'Write a compelling 2-sentence product description for "$productName" in the $category category. Be concise and highlight key benefits.',
        ),
      ]);
      return response.text ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<String> summarizeReviews(List<String> reviews) async {
    if (reviews.isEmpty) return 'No reviews yet.';
    try {
      final reviewText = reviews.take(20).join('\n---\n');
      final response = await _model.generateContent([
        Content.text(
          'Summarize these product reviews in 2-3 sentences, highlighting pros and cons:\n$reviewText',
        ),
      ]);
      return response.text ?? 'Could not summarize reviews.';
    } catch (_) {
      return 'Could not summarize reviews.';
    }
  }

  Future<String> compareProducts(String product1, String product2) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'Compare "$product1" vs "$product2" for an Indian consumer. Include: specs, price range (₹), pros/cons, and a final recommendation. Format with clear sections.',
        ),
      ]);
      return response.text ?? 'Could not compare products.';
    } catch (_) {
      return 'Could not compare products.';
    }
  }

  Future<List<String>> generateGroceryList({
    required int familySize,
    required int weeks,
  }) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'Generate a grocery list for a family of $familySize for $weeks week(s) in India. '
          'Include vegetables, dairy, staples, snacks, and household items. '
          'Return ONLY a JSON array of product names, no explanation. Example: ["Rice 5kg", "Milk 2L"]',
        ),
      ]);
      final text = response.text ?? '[]';
      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      // Simple parse: extract items between quotes
      final regex = RegExp(r'"([^"]+)"');
      return regex.allMatches(cleaned).map((m) => m.group(1)!).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> suggestGifts({
    required String interests,
    required int budget,
  }) async {
    try {
      final response = await _model.generateContent([
        Content.text(
          'Suggest 5 specific gift products for someone who likes "$interests" with a budget of ₹$budget in India. '
          'Return ONLY a JSON array of product names. Example: ["Cricket bat", "Sports shoes"]',
        ),
      ]);
      final text = response.text ?? '[]';
      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final regex = RegExp(r'"([^"]+)"');
      return regex.allMatches(cleaned).map((m) => m.group(1)!).toList();
    } catch (_) {
      return [];
    }
  }

  void resetChat() {
    _instance = null;
  }
}
