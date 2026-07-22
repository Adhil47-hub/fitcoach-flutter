import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiApiKey {
  static String get value {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim() ?? '';
    if (apiKey.isEmpty) {
      throw StateError(
        'GEMINI_API_KEY is missing. Add it to assets/.env and restart the app.',
      );
    }
    return apiKey;
  }
}
