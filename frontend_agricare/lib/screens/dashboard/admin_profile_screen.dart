import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/auth_service.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import 'admin_change_password_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final AuthController _authController = Get.find<AuthController>();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isEditing = false;
  bool _isSaving = false;

  late final AnimationController _entry;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _authController.username.value);
    _emailController = TextEditingController(text: _authController.email.value);

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _fade = CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entry, curve: Curves.easeOutCubic));
    _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _authService.updateAdminProfile(
        name: _nameController.text,
        email: _emailController.text,
      );
      if (!mounted) return;
      setState(() => _isEditing = false);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        title: const Text('Admin Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Get.offAllNamed(AppRoutes.login);
            },
          ),
        ],
      ),
      body: Obx(
        () => FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
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
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF4E5),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.admin_panel_settings_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome, ${_authController.username.value}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: titleColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _authController.email.value,
                                  style: TextStyle(
                                    color: titleColor.withOpacity(0.7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD2E5CC)),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              if (value.trim().length < 3) {
                                return 'Name must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            enabled: _isEditing,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value.trim())) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          if (!_isEditing)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => setState(() => _isEditing = true),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Profile'),
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
                          if (_isEditing)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _isSaving
                                        ? null
                                        : () {
                                            setState(() {
                                              _isEditing = false;
                                              _nameController.text =
                                                  _authController.username.value;
                                              _emailController.text =
                                                  _authController.email.value;
                                            });
                                          },
                                    icon: const Icon(Icons.close),
                                    label: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _isSaving ? null : _saveProfile,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.check_circle_outline),
                                    label: Text(_isSaving ? 'Saving...' : 'Save'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4A7C2C),
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD2E5CC)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF4E5),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(Icons.lock_reset_rounded),
                        ),
                        title: const Text(
                          'Change Password',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: const Text('Open dedicated secure password page'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Get.to(
                            () => const AdminChangePasswordScreen(),
                            transition: Transition.rightToLeftWithFade,
                            duration: const Duration(milliseconds: 340),
                          );
                        },
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
