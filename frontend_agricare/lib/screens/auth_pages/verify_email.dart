import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

import '../../api/auth_service.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  final AuthController _authController = Get.find<AuthController>();

  bool _sending = false;
  Timer? _pollTimer;
  bool _checking = false;

  String get _email {
    final args = Get.arguments;
    if (args is Map && args['email'] is String) {
      return (args['email'] as String).trim();
    }
    return '';
  }

  Future<void> _resend() async {
    if (_email.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _authService.resendVerificationEmail(email: _email);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    // Initial quick check, then periodic.
    _checkVerification();
    _pollTimer?.cancel();
        _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkVerification();
    });
  }

  Future<void> _checkVerification() async {
    if (_checking) return;
    if (_authController.token.value.isEmpty) return;

    _checking = true;
    try {
      await _authService.checkAuth();

      if (_authController.isEmailVerified.value) {
        _pollTimer?.cancel();
        if (!mounted) return;
        if (_authController.needsLocationSetup) {
          Get.offAllNamed(AppRoutes.locationSetup, arguments: {'next': AppRoutes.dashboard});
        } else {
          Get.offAllNamed(AppRoutes.dashboard);
        }
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check your inbox',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(
                'We sent a verification link to your email. Open it to verify your AgriCare account.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              if (_email.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _sending || _email.isEmpty ? null : _resend,
                  child: _sending
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Resend Verification Email'),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Get.offAllNamed(AppRoutes.login),
                  child: const Text('Back to Login'),
                ),
              ),

              const Spacer(),

              Text(
                'Tip: If you don’t see the email, check Spam/Junk folder.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
