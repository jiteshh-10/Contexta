import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Securely stores user-provided active LLM provider and API key.
class LlmCredentialsService {
  static final LlmCredentialsService _instance =
      LlmCredentialsService._internal();
  factory LlmCredentialsService() => _instance;
  LlmCredentialsService._internal();

  static const String _providerNameKey = 'contexta_llm_provider_name';
  static const String _apiKeyStorageKey = 'contexta_llm_api_key';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError(
        'LlmCredentialsService not initialized. Call initialize() first.',
      );
    }
    return _prefs!;
  }

  Future<void> saveProviderName(String providerName) async {
    final trimmed = providerName.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Provider name cannot be empty.');
    }

    await initialize();
    await _preferences.setString(_providerNameKey, trimmed);
  }

  Future<String?> getProviderName() async {
    await initialize();
    final value = _preferences.getString(_providerNameKey);
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> saveApiKey(String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('API key cannot be empty.');
    }

    await _secureStorage.write(key: _apiKeyStorageKey, value: trimmed);
  }

  Future<String?> getApiKey() async {
    final key = await _secureStorage.read(key: _apiKeyStorageKey);
    if (key == null) {
      return null;
    }

    final trimmed = key.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }

  Future<void> clearApiKey() async {
    await _secureStorage.delete(key: _apiKeyStorageKey);
  }

  Future<void> saveCredentials({
    required String providerName,
    required String apiKey,
  }) async {
    await saveProviderName(providerName);
    await saveApiKey(apiKey);
  }
}
