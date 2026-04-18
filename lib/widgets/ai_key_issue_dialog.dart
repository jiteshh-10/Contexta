import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/ai_request_error.dart';
import 'contexta_dialog.dart';
import 'primary_button.dart';
import 'secondary_button.dart';

Future<void> showAiCredentialIssueDialog({
  required BuildContext context,
  required AiRequestError error,
  required VoidCallback onOpenSettings,
  String? providerName,
}) async {
  if (!error.shouldShowCredentialPopup) {
    return;
  }

  var resolvedProvider = providerName?.trim() ?? '';
  if (resolvedProvider.isEmpty) {
    try {
      resolvedProvider = await ApiConfig.getActiveProviderName();
    } catch (_) {
      resolvedProvider = 'LLM';
    }
  }

  if (!context.mounted) {
    return;
  }

  await showContextaDialog<void>(
    context: context,
    title: error.popupTitle(resolvedProvider),
    content: Text(
      error.popupBody(resolvedProvider),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      textAlign: TextAlign.center,
    ),
    actions: [
      SecondaryButton(
        label: 'Not now',
        onPressed: () => Navigator.of(context).pop(),
      ),
      PrimaryButton(
        label: 'Open AI Settings',
        onPressed: () {
          Navigator.of(context).pop();
          onOpenSettings();
        },
      ),
    ],
  );
}
