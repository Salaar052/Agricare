import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/auth_service.dart';

class AdminChangePasswordScreen extends StatefulWidget {
  const AdminChangePasswordScreen({super.key});

  @override
  State<AdminChangePasswordScreen> createState() =>
      _AdminChangePasswordScreenState();
}

class _AdminChangePasswordScreenState extends State<AdminChangePasswordScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _authService.changeAdminPassword(
        currentPassword: _currentPasswordController.text.trim(),
        newPassword: _newPasswordController.text.trim(),
      );
      if (!mounted) return;
      Get.back();
    } catch (_) {
      // Snackbar shown by AuthService.
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    required bool hidden,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(hidden ? Icons.visibility_off : Icons.visibility),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleColor = const Color(0xFF1F3D22);
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F2),
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3E6D25), Color(0xFF5D8F3F)],
            ),
          ),
        ),
        title: const Text('Change Password'),
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFD2E5CC)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3E6D25).withOpacity(0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4E5),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.lock_reset_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Secure Your Account',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _hideCurrent,
                      decoration: _decoration(
                        label: 'Current Password',
                        icon: Icons.lock_outline_rounded,
                        hidden: _hideCurrent,
                        onToggle: () => setState(() => _hideCurrent = !_hideCurrent),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _hideNew,
                      decoration: _decoration(
                        label: 'New Password',
                        icon: Icons.lock_person_rounded,
                        hidden: _hideNew,
                        onToggle: () => setState(() => _hideNew = !_hideNew),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim().length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _hideConfirm,
                      decoration: _decoration(
                        label: 'Confirm New Password',
                        icon: Icons.verified_user_outlined,
                        hidden: _hideConfirm,
                        onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (v.trim() != _newPasswordController.text.trim()) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _submit,
                        icon: const Icon(Icons.check_circle_outline),
                        label: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Update Password'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A7C2C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
