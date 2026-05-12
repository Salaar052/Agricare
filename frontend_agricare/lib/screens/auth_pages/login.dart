import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../api/auth_service.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final AuthController _authController = Get.find<AuthController>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _loading = true);

    try {
      await _authService.login(email: email, password: password);

      if (!mounted) return;

      // First-time location setup (live permission OR manual search)
      if (_authController.needsLocationSetup) {
        final next =
            _authController.isAdmin.value ? AppRoutes.adminDashboard : AppRoutes.dashboard;
        Get.offAllNamed(AppRoutes.locationSetup, arguments: {'next': next});
      } else {
        if (_authController.isAdmin.value) {
          Get.offAllNamed(AppRoutes.adminDashboard);
        } else {
          Get.offAllNamed(AppRoutes.dashboard);
        }
      }
    } catch (e) {
      if (e is EmailNotVerifiedException) {
        Get.toNamed(AppRoutes.verifyEmail, arguments: {'email': e.email});
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome Back", style: theme.textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                "Login to continue using Agri-Care",
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // EMAIL
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: Validators.email(),
                      ),

                      const SizedBox(height: 16),

                      // PASSWORD
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        validator: Validators.loginPassword(minLength: 6),
                      ),

                      const SizedBox(height: 26),

                      // LOGIN BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Login"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: TextButton(
                  onPressed: () => Get.offNamed(AppRoutes.signup),
                  child: Text(
                    "Don't have an account? Sign Up",
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
