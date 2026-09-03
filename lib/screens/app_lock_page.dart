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
      _message = 'Autentikasi belum berhasil. Silakan coba lagi.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.primary.withValues(alpha: isDark ? 0.10 : 0.055),
              theme.scaffoldBackgroundColor,
            ],
            stops: const [0, 0.42],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(
                          alpha: isDark ? 0.08 : 0.055,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scheme.primary.withValues(
                            alpha: isDark ? 0.24 : 0.13,
                          ),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.22),
                              blurRadius: 24,
                              offset: const Offset(0, 9),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 43,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Cimpli Finance Terkunci',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 25,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Lindungi data keuangan Anda dengan autentikasi perangkat.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(
                            alpha: isDark ? 0.72 : 0.85,
                          ),
                        ),
                        boxShadow: [
                          if (!isDark)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.055),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: scheme.primary.withValues(
                                    alpha: isDark ? 0.12 : 0.075,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.fingerprint_rounded,
                                  size: 21,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Autentikasi perangkat',
                                      style: TextStyle(
                                        color: scheme.onSurface,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Gunakan metode keamanan yang tersedia di perangkat.',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                        fontSize: 10,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton.icon(
                              onPressed: _authenticating ? null : _authenticate,
                              icon: _authenticating
                                  ? SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: scheme.onPrimary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.fingerprint_rounded,
                                      size: 22,
                                    ),
                              label: Text(
                                _authenticating
                                    ? 'Memeriksa...'
                                    : 'Buka dengan Sidik Jari',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                          if (_message != null) ...[
                            const SizedBox(height: 13),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(11),
                              decoration: BoxDecoration(
                                color: scheme.error.withValues(
                                  alpha: isDark ? 0.12 : 0.065,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: scheme.error.withValues(
                                    alpha: isDark ? 0.25 : 0.14,
                                  ),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 17,
                                    color: scheme.error,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _message!,
                                      style: TextStyle(
                                        color: scheme.error,
                                        fontSize: 10.5,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Data tetap terlindungi di perangkat Anda',
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
