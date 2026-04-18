/// Categorized AI request errors used for user messaging and UI actions.
enum AiRequestErrorType {
  none,
  keyMissing,
  keyInvalid,
  keyExpired,
  quotaExceeded,
  rateLimited,
  offline,
  timeout,
  network,
  serviceUnavailable,
  malformedResponse,
  unknown,
}

class AiRequestError {
  final AiRequestErrorType type;
  final String message;

  const AiRequestError({required this.type, required this.message});

  bool get shouldShowCredentialPopup {
    return type == AiRequestErrorType.keyMissing ||
        type == AiRequestErrorType.keyInvalid ||
        type == AiRequestErrorType.keyExpired ||
        type == AiRequestErrorType.quotaExceeded;
  }

  String popupTitle(String providerLabel) {
    switch (type) {
      case AiRequestErrorType.keyMissing:
        return '$providerLabel key required';
      case AiRequestErrorType.keyInvalid:
        return 'Invalid $providerLabel key';
      case AiRequestErrorType.keyExpired:
        return '$providerLabel key expired';
      case AiRequestErrorType.quotaExceeded:
        return '$providerLabel quota reached';
      case AiRequestErrorType.none:
      case AiRequestErrorType.rateLimited:
      case AiRequestErrorType.offline:
      case AiRequestErrorType.timeout:
      case AiRequestErrorType.network:
      case AiRequestErrorType.serviceUnavailable:
      case AiRequestErrorType.malformedResponse:
      case AiRequestErrorType.unknown:
        return 'AI request issue';
    }
  }

  String popupBody(String providerLabel) {
    switch (type) {
      case AiRequestErrorType.keyMissing:
        return 'Add your own $providerLabel API key in Settings so your requests run with your account and credits.';
      case AiRequestErrorType.keyInvalid:
        return 'The saved $providerLabel API key was rejected. Update it in Settings and try again.';
      case AiRequestErrorType.keyExpired:
        return 'The saved $providerLabel API key appears expired or revoked. Replace it in Settings to continue.';
      case AiRequestErrorType.quotaExceeded:
        return 'This key has no remaining quota right now. You can wait, increase quota, or switch to another key in Settings.';
      case AiRequestErrorType.none:
      case AiRequestErrorType.rateLimited:
      case AiRequestErrorType.offline:
      case AiRequestErrorType.timeout:
      case AiRequestErrorType.network:
      case AiRequestErrorType.serviceUnavailable:
      case AiRequestErrorType.malformedResponse:
      case AiRequestErrorType.unknown:
        return message;
    }
  }
}
