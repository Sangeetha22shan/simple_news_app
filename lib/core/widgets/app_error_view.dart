import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool compact;

  const AppErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: compact ? 28 : 40,
            color: colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          TextButton(
            onPressed: onRetry,
            child: const Text(AppConstants.retryLabel),
          ),
        ],
      ),
    );
  }
}
