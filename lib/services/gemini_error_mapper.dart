import 'dart:convert';
import '../models/ai_request_error.dart';

/// Converts LLM API failures to standardized, user-friendly errors.
class LlmErrorMapper {
  LlmErrorMapper._();

  static AiRequestError fromHttpResponse({
    required String providerName,
    required int statusCode,
    required String responseBody,
  }) {
    final message = _extractErrorMessage(responseBody);
    final normalized = message.toLowerCase();
    final providerLabel = providerName.trim().isEmpty ? 'LLM' : providerName;

    if (normalized.contains('expired')) {
      return AiRequestError(
        type: AiRequestErrorType.keyExpired,
        message:
            'API key expired. Update your $providerLabel API key in settings.',
      );
    }

    if (normalized.contains('api key not valid') ||
        normalized.contains('invalid api key') ||
        normalized.contains('authentication failed') ||
        normalized.contains('invalid x-api-key') ||
        normalized.contains('invalid_api_key') ||
        normalized.contains('permission denied') ||
        normalized.contains('unauthorized')) {
      return AiRequestError(
        type: AiRequestErrorType.keyInvalid,
        message: 'Invalid API key. Please check your $providerLabel API key.',
      );
    }

    if (statusCode == 401 || statusCode == 403) {
      return AiRequestError(
        type: AiRequestErrorType.keyInvalid,
        message:
            '$providerLabel rejected this API key. Please update it in settings.',
      );
    }

    if (statusCode == 429 ||
        normalized.contains('quota') ||
        normalized.contains('rate limit') ||
        normalized.contains('insufficient credits') ||
        normalized.contains('resource exhausted') ||
        normalized.contains('billing')) {
      return AiRequestError(
        type: AiRequestErrorType.quotaExceeded,
        message:
            '$providerLabel quota reached. Try again later or update your key.',
      );
    }

    if (statusCode >= 500) {
      return AiRequestError(
        type: AiRequestErrorType.serviceUnavailable,
        message:
            '$providerLabel service is temporarily unavailable. Try again later.',
      );
    }

    if (statusCode == 400 &&
        (normalized.contains('api key') || normalized.contains('credential'))) {
      return AiRequestError(
        type: AiRequestErrorType.keyInvalid,
        message:
            '$providerLabel API credentials are invalid. Please update your key.',
      );
    }

    return AiRequestError(
      type: AiRequestErrorType.unknown,
      message:
          message.isEmpty
              ? 'Unable to complete the AI request. Please try again.'
              : message,
    );
  }

  static AiRequestError timeout() {
    return const AiRequestError(
      type: AiRequestErrorType.timeout,
      message: 'Request timed out. Please check your connection and try again.',
    );
  }

  static AiRequestError network(String? details) {
    final suffix = (details == null || details.isEmpty) ? '' : ': $details';
    return AiRequestError(
      type: AiRequestErrorType.network,
      message: 'Network error$suffix',
    );
  }

  static AiRequestError malformedResponse() {
    return const AiRequestError(
      type: AiRequestErrorType.malformedResponse,
      message: 'Failed to parse AI response. Please try again.',
    );
  }

  static AiRequestError unknown() {
    return const AiRequestError(
      type: AiRequestErrorType.unknown,
      message: 'An unexpected error occurred. Please try again.',
    );
  }

  static String _extractErrorMessage(String responseBody) {
    if (responseBody.isEmpty) {
      return '';
    }

    try {
      final data = jsonDecode(responseBody);
      if (data is Map<String, dynamic>) {
        final error = data['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
      }
    } catch (_) {
      // Fall back to raw body for non-JSON responses.
    }

    return responseBody.trim();
  }
}
