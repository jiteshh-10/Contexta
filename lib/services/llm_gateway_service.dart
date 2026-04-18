import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../config/master_prompt_config.dart';
import '../models/ai_request_error.dart';
import '../models/llm_provider.dart';
import 'gemini_error_mapper.dart';
import 'llm_output_sanitizer.dart';

class LlmGatewayResult {
  final bool success;
  final String providerName;
  final String? text;
  final AiRequestError? error;

  const LlmGatewayResult._({
    required this.success,
    required this.providerName,
    this.text,
    this.error,
  });

  factory LlmGatewayResult.success({
    required String providerName,
    required String text,
  }) {
    return LlmGatewayResult._(
      success: true,
      providerName: providerName,
      text: text,
    );
  }

  factory LlmGatewayResult.failure({
    required String providerName,
    required AiRequestError error,
  }) {
    return LlmGatewayResult._(
      success: false,
      providerName: providerName,
      error: error,
    );
  }
}

/// Provider-agnostic text generation gateway used across AI features.
class LlmGatewayService {
  static final LlmGatewayService _instance = LlmGatewayService._internal();
  factory LlmGatewayService() => _instance;
  LlmGatewayService._internal();

  final http.Client _client = http.Client();

  Future<LlmGatewayResult> generateText({
    required String taskSystemPrompt,
    required String userPrompt,
    required int maxOutputTokens,
    required double temperature,
  }) async {
    const fallbackProvider = 'LLM';

    try {
      final providerName = await ApiConfig.getActiveProviderName();
      final apiKey = await ApiConfig.getActiveApiKey();
      final profile = LlmProviderRegistry.resolve(providerName);
      final mergedSystemPrompt = MasterPromptConfig.applyToTask(
        taskSystemPrompt,
      );

      late http.Response response;
      if (profile.transport == LlmTransport.gemini) {
        response = await _requestGemini(
          profile: profile,
          apiKey: apiKey,
          mergedSystemPrompt: mergedSystemPrompt,
          userPrompt: userPrompt,
          maxOutputTokens: maxOutputTokens,
          temperature: temperature,
        );
      } else if (profile.transport == LlmTransport.anthropic) {
        response = await _requestAnthropic(
          profile: profile,
          apiKey: apiKey,
          mergedSystemPrompt: mergedSystemPrompt,
          userPrompt: userPrompt,
          maxOutputTokens: maxOutputTokens,
          temperature: temperature,
        );
      } else {
        response = await _requestOpenAiCompatible(
          profile: profile,
          apiKey: apiKey,
          mergedSystemPrompt: mergedSystemPrompt,
          userPrompt: userPrompt,
          maxOutputTokens: maxOutputTokens,
          temperature: temperature,
        );
      }

      if (response.statusCode != 200) {
        final mappedError = LlmErrorMapper.fromHttpResponse(
          providerName: profile.displayName,
          statusCode: response.statusCode,
          responseBody: response.body,
        );
        return LlmGatewayResult.failure(
          providerName: profile.displayName,
          error: mappedError,
        );
      }

      final content = _extractTextFromResponse(
        transport: profile.transport,
        responseBody: response.body,
      );

      if (content == null || content.trim().isEmpty) {
        return LlmGatewayResult.failure(
          providerName: profile.displayName,
          error: const AiRequestError(
            type: AiRequestErrorType.malformedResponse,
            message: 'Received an empty response from the configured provider.',
          ),
        );
      }

      final normalized = LlmOutputSanitizer.normalizePlainText(content);
      return LlmGatewayResult.success(
        providerName: profile.displayName,
        text: normalized,
      );
    } on TimeoutException {
      final error = LlmErrorMapper.timeout();
      return LlmGatewayResult.failure(
        providerName: fallbackProvider,
        error: error,
      );
    } on http.ClientException catch (e) {
      final error = LlmErrorMapper.network(e.message);
      return LlmGatewayResult.failure(
        providerName: fallbackProvider,
        error: error,
      );
    } on FormatException {
      final error = LlmErrorMapper.malformedResponse();
      return LlmGatewayResult.failure(
        providerName: fallbackProvider,
        error: error,
      );
    } on ApiKeyNotConfiguredException catch (e) {
      return LlmGatewayResult.failure(
        providerName: fallbackProvider,
        error: AiRequestError(
          type: AiRequestErrorType.keyMissing,
          message: e.message,
        ),
      );
    } on UnsupportedLlmProviderException catch (e) {
      return LlmGatewayResult.failure(
        providerName: fallbackProvider,
        error: AiRequestError(
          type: AiRequestErrorType.unknown,
          message: e.toString(),
        ),
      );
    } catch (_) {
      final error = LlmErrorMapper.unknown();
      return LlmGatewayResult.failure(
        providerName: fallbackProvider,
        error: error,
      );
    }
  }

  Future<http.Response> _requestGemini({
    required LlmProviderProfile profile,
    required String apiKey,
    required String mergedSystemPrompt,
    required String userPrompt,
    required int maxOutputTokens,
    required double temperature,
  }) {
    final url = Uri.parse(
      '${profile.baseUrl}${profile.endpoint}',
    ).replace(queryParameters: {'key': apiKey});

    final requestBody = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': mergedSystemPrompt},
        ],
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': userPrompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': temperature,
        'maxOutputTokens': maxOutputTokens,
      },
    });

    return _client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        )
        .timeout(ApiConfig.requestTimeout);
  }

  Future<http.Response> _requestOpenAiCompatible({
    required LlmProviderProfile profile,
    required String apiKey,
    required String mergedSystemPrompt,
    required String userPrompt,
    required int maxOutputTokens,
    required double temperature,
  }) {
    final url = Uri.parse('${profile.baseUrl}${profile.endpoint}');

    final requestBody = jsonEncode({
      'model': profile.model,
      'messages': [
        {'role': 'system', 'content': mergedSystemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': maxOutputTokens,
      'temperature': temperature,
    });

    return _client
        .post(
          url,
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
          body: requestBody,
        )
        .timeout(ApiConfig.requestTimeout);
  }

  Future<http.Response> _requestAnthropic({
    required LlmProviderProfile profile,
    required String apiKey,
    required String mergedSystemPrompt,
    required String userPrompt,
    required int maxOutputTokens,
    required double temperature,
  }) {
    final url = Uri.parse('${profile.baseUrl}${profile.endpoint}');

    final requestBody = jsonEncode({
      'model': profile.model,
      'max_tokens': maxOutputTokens,
      'temperature': temperature,
      'system': mergedSystemPrompt,
      'messages': [
        {'role': 'user', 'content': userPrompt},
      ],
    });

    return _client
        .post(
          url,
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
            'Content-Type': 'application/json',
          },
          body: requestBody,
        )
        .timeout(ApiConfig.requestTimeout);
  }

  String? _extractTextFromResponse({
    required LlmTransport transport,
    required String responseBody,
  }) {
    final data = jsonDecode(responseBody);

    if (transport == LlmTransport.gemini) {
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final candidates = data['candidates'];
      if (candidates is! List || candidates.isEmpty) {
        return null;
      }

      final firstCandidate = candidates.first;
      if (firstCandidate is! Map) {
        return null;
      }

      final content = firstCandidate['content'];
      if (content is! Map) {
        return null;
      }

      final parts = content['parts'];
      if (parts is! List || parts.isEmpty) {
        return null;
      }

      final textParts = <String>[];
      for (final part in parts) {
        if (part is Map && part['text'] is String) {
          final text = (part['text'] as String).trim();
          if (text.isNotEmpty) {
            textParts.add(text);
          }
        }
      }

      return textParts.isEmpty ? null : textParts.join('\n');
    }

    if (transport == LlmTransport.anthropic) {
      if (data is! Map<String, dynamic>) {
        return null;
      }

      final content = data['content'];
      if (content is! List || content.isEmpty) {
        return null;
      }

      final textParts = <String>[];
      for (final part in content) {
        if (part is Map && part['text'] is String) {
          final text = (part['text'] as String).trim();
          if (text.isNotEmpty) {
            textParts.add(text);
          }
        }
      }

      return textParts.isEmpty ? null : textParts.join('\n');
    }

    if (data is! Map<String, dynamic>) {
      return null;
    }

    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      return null;
    }

    final firstChoice = choices.first;
    if (firstChoice is! Map) {
      return null;
    }

    final message = firstChoice['message'];
    if (message is! Map) {
      return null;
    }

    final content = message['content'];
    if (content is String) {
      return content.trim();
    }

    if (content is List) {
      final textParts = <String>[];
      for (final part in content) {
        if (part is Map && part['text'] is String) {
          final text = (part['text'] as String).trim();
          if (text.isNotEmpty) {
            textParts.add(text);
          }
        }
      }
      return textParts.isEmpty ? null : textParts.join('\n');
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
