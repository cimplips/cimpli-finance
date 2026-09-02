import 'package:flutter/material.dart';

import '../services/app_lock_service.dart';

class AppLockPage extends StatefulWidget {
  const AppLockPage({
    super.key,
    required this.onUnlocked,
  });

  final VoidCallback onUnlocked;

  @override
  State<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends State<AppLockPage> {
  final AppLockService _lockService = AppLockService();

  bool _authenticating = false;
  String? _message;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    if (_authenticating) {
      return;
    }

    setState(() {
      _authenticating = true;
      _message = null;
    });

    final success = await _lockService.authenticate();

    if (!mounted) {
      return;
    }

    setState(() {
      _authenticating = false;
    });

    if (success) {
      widget.onUnlocked();
      return;
    }

    setState(() {
      _message =
          'Autentikasi belum berhasil. Silakan coba lagi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: Theme.of(context)
                        .colorScheme
                        .primary,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Cimpli Finance Terkunci',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Gunakan sidik jari atau kunci perangkat '
                  'untuk membuka aplikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed:
                      _authenticating ? null : _authenticate,
                  icon: const Icon(
                    Icons.fingerprint_rounded,
                  ),
                  label: Text(
                    _authenticating
                        ? 'Memeriksa...'
                        : 'Buka dengan Sidik Jari',
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .error,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
