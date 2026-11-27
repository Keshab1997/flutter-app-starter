import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Replaces Flutter's default grey/red release error box with a clean Material 3
/// fallback card so unexpected widget build errors degrade gracefully.
void installGlobalErrorWidget() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return AppErrorView(details: details);
  };
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF141218),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Color(0xFFF2B8B5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kDebugMode
                        ? details.exceptionAsString()
                        : 'Please restart the app. If this continues, check for an update.',
                    textAlign: TextAlign.center,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFCAC4D0),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
