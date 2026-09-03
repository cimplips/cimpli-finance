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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background => _isDark
      ? const Color(0xFF2C2F34)
      : const Color(0xFFF7F8FC);

  Color get _surface => _isDark
      ? const Color(0xFF36393F)
      : const Color(0xFFFFFFFF);

  Color get _surfaceSoft => _isDark
      ? const Color(0xFF40434A)
      : const Color(0xFFF1F4FA);

  Color get _border => _isDark
      ? const Color(0xFF50535A)
      : const Color(0xFFE1E6EF);

  Color get _primary => _isDark
      ? const Color(0xFF9CB3F4)
      : const Color(0xFF6F8FEA);

  Color get _primarySoft => _isDark
      ? const Color(0xFF46506A)
      : const Color(0xFFE8EEFF);

  Color get _text => _isDark
      ? const Color(0xFFF1F3F6)
      : const Color(0xFF202735);

  Color get _textSecondary => _isDark
      ? const Color(0xFFB8BDC6)
      : const Color(0xFF687386);

  Color get _error => _isDark
      ? const Color(0xFFE39A9A)
      : const Color(0xFFD87979);

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
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _border),
                  boxShadow: _isDark
                      ? null
                      : const [
                          BoxShadow(
                            color: Color(0x0B000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: _primarySoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_rounded,
                        size: 42,
                        color: _primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Cimpli Finance Terkunci',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _text,
                        fontSize: 24,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Gunakan sidik jari atau kunci perangkat '
                      'untuk membuka aplikasi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surfaceSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: _primarySoft,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(
                              Icons.verified_user_outlined,
                              color: _primary,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Data keuangan Anda tetap terlindungi.',
                              style: TextStyle(
                                color: _text,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            _authenticating ? null : _authenticate,
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: _isDark
                              ? const Color(0xFF30343A)
                              : Colors.white,
                          disabledBackgroundColor:
                              _primary.withValues(alpha: 0.45),
                          disabledForegroundColor: _isDark
                              ? const Color(0xFF30343A)
                                  .withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.8),
                          minimumSize: const Size.fromHeight(54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          Icons.fingerprint_rounded,
                          size: 23,
                        ),
                        label: Text(
                          _authenticating
                              ? 'Memeriksa...'
                              : 'Buka dengan Sidik Jari',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: _error.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _error.withValues(alpha: 0.20),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: _error,
                              size: 19,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _message!,
                                style: TextStyle(
                                  color: _error,
                                  fontSize: 13,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Text(
                      'Keamanan aplikasi',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
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
