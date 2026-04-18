import 'package:flutter/material.dart';
import '../models/llm_provider.dart';
import '../services/llm_credentials_service.dart';
import '../theme/app_theme.dart';
import '../widgets/contexta_dialog.dart';
import '../widgets/contexta_snackbar.dart';
import '../widgets/primary_button.dart';
import '../widgets/secondary_button.dart';

/// Screen for managing user-owned LLM provider and API key.
class AiSettingsScreen extends StatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  State<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends State<AiSettingsScreen> {
  final LlmCredentialsService _credentialsService = LlmCredentialsService();
  final TextEditingController _providerNameController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isClearing = false;
  bool _obscureKey = true;
  bool _hasStoredKey = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _providerNameController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    await _credentialsService.initialize();
    final providerName = await _credentialsService.getProviderName();
    final existingKey = await _credentialsService.getApiKey();

    if (!mounted) return;

    setState(() {
      _providerNameController.text = providerName ?? '';
      _apiKeyController.text = existingKey ?? '';
      _hasStoredKey = existingKey != null && existingKey.isNotEmpty;
      _isLoading = false;
    });
  }

  Future<void> _saveApiKey() async {
    final providerName = _providerNameController.text.trim();
    final key = _apiKeyController.text.trim();

    if (providerName.isEmpty) {
      ContextaSnackbar.showWarning(
        context,
        'Enter a provider name to continue.',
      );
      return;
    }

    if (key.isEmpty) {
      ContextaSnackbar.showWarning(context, 'Enter an API key to continue.');
      return;
    }

    try {
      LlmProviderRegistry.resolve(providerName);
    } on UnsupportedLlmProviderException {
      ContextaSnackbar.showWarning(
        context,
        'Use a supported provider name or enter a full API base URL/domain for an OpenAI-compatible provider.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _credentialsService.saveCredentials(
        providerName: providerName,
        apiKey: key,
      );

      if (!mounted) return;

      setState(() {
        _hasStoredKey = true;
      });
      ContextaSnackbar.showSuccess(context, 'API key saved securely.');
    } catch (_) {
      if (mounted) {
        ContextaSnackbar.showError(
          context,
          'Unable to save API key. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _clearApiKey() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'Remove API key?',
      message:
          'This removes the saved key from this device. AI features will stop until a new key is added.',
      confirmLabel: 'Remove',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (!confirmed) {
      return;
    }

    setState(() => _isClearing = true);

    try {
      await _credentialsService.clearApiKey();

      if (!mounted) return;

      setState(() {
        _apiKeyController.clear();
        _hasStoredKey = false;
      });
      ContextaSnackbar.show(context, 'API key removed.');
    } catch (_) {
      if (mounted) {
        ContextaSnackbar.showError(
          context,
          'Unable to remove API key. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final providerName = _providerNameController.text.trim();
    final hasProviderName = providerName.isNotEmpty;
    final resolvedProfile =
        hasProviderName ? _tryResolveProviderProfile(providerName) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'AI provider & key',
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'Georgia',
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProviderCard(
                      theme,
                      colorScheme,
                      isDark,
                      resolvedProfile,
                    ),
                    const SizedBox(height: 20),
                    _buildApiKeyCard(theme, colorScheme, isDark),
                    const SizedBox(height: 16),
                    _buildHelpText(theme, colorScheme, resolvedProfile),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: _isSaving ? 'Saving…' : 'Save API key',
                      onPressed: _isSaving ? () {} : _saveApiKey,
                      disabled: _isSaving,
                      loading: _isSaving,
                      fullWidth: true,
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: _isClearing ? 'Removing…' : 'Remove saved API key',
                      onPressed:
                          (!_hasStoredKey || _isClearing)
                              ? () {}
                              : _clearApiKey,
                      disabled: !_hasStoredKey || _isClearing,
                      fullWidth: true,
                      destructive: true,
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildProviderCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
    LlmProviderProfile? profile,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppTheme.darkPaperElevated
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Provider',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _providerNameController,
            onChanged: (_) => setState(() {}),
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            decoration: const InputDecoration(
              hintText:
                  'e.g. Gemini, Perplexity, OpenAI, Anthropic, or https://your-provider.com',
            ),
          ),
          if (profile != null) ...[
            const SizedBox(height: 10),
            Text(
              'Detected model: ${profile.model}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiKeyCard(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? AppTheme.darkPaperElevated
                : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'API key',
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.65),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Paste your API key for this provider',
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscureKey = !_obscureKey);
                },
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpText(
    ThemeData theme,
    ColorScheme colorScheme,
    LlmProviderProfile? profile,
  ) {
    final providerLabel = profile?.displayName ?? 'your chosen provider';

    return Text(
      'Your key is stored securely on this device.\n'
      'Contexta is open source, so each user should bring their own key and credits.\n\n'
      'Provider name must match a supported vendor, or be a full API base URL/domain for an OpenAI-compatible provider.\n'
      'Current routing target: $providerLabel\n'
      'If you see an expired, invalid, or quota popup, update provider name or key here.',
      style: theme.textTheme.bodySmall?.copyWith(
        fontFamily: 'Inter',
        height: 1.5,
        color: colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }

  LlmProviderProfile? _tryResolveProviderProfile(String providerName) {
    try {
      return LlmProviderRegistry.resolve(providerName);
    } on UnsupportedLlmProviderException {
      return null;
    }
  }
}
