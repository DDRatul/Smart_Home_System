import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  String? _err;

  bool _obscure = true; // 👈 add
  final _formKey = GlobalKey<FormState>(); // 👈 add

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      await _auth.login(_email.text.trim(), _pass.text);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A),
                  Color(0xFF1D4ED8),
                  Color(0xFF9333EA),
                ],
              ),
            ),
          ),

          // Decorative bubbles
          Positioned(top: -80, left: -60, child: _Bubble(size: 220, opacity: 0.16)),
          Positioned(bottom: -90, right: -70, child: _Bubble(size: 260, opacity: 0.12)),
          Positioned(top: MediaQuery.of(context).size.height * 0.22, right: -40, child: _Bubble(size: 140, opacity: 0.10)),

          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.22)),
                            ),
                            child: const Icon(Icons.shield_outlined, size: 34, color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Smart Crime Reporting",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Sign in to continue",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.82)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Emergency notice (pretty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "If this is an emergency, contact local emergency services.",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Glass card
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.22)),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 14),
                              color: Colors.black.withOpacity(0.25),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              _NiceField(
                                controller: _email,
                                label: "Email",
                                hint: "you@example.com",
                                icon: Icons.mail_outline,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  final s = (v ?? "").trim();
                                  if (s.isEmpty) return "Email is required";
                                  if (!s.contains("@")) return "Enter a valid email";
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              _NiceField(
                                controller: _pass,
                                label: "Password",
                                hint: "••••••••",
                                icon: Icons.lock_outline,
                                obscureText: _obscure,
                                suffix: IconButton(
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  icon: Icon(
                                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                                validator: (v) {
                                  if ((v ?? "").isEmpty) return "Password is required";
                                  if ((v ?? "").length < 6) return "Minimum 6 characters";
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              if (_err != null)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: Colors.red.withOpacity(0.35)),
                                  ),
                                  child: Text(
                                    _err!,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                  ),
                                ),

                              const SizedBox(height: 14),

                              SizedBox(
                                height: 52,
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF0F172A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Text(
                                          "Login",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.22))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text("or", style: TextStyle(color: Colors.white.withOpacity(0.75))),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withOpacity(0.22))),
                                ],
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                height: 52,
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withOpacity(0.45)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "Create an account",
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "By continuing, you agree to Terms & Privacy.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NiceField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _NiceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.85),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),
            prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.85)),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white.withOpacity(0.10),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.16)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.45)),
            ),
            errorStyle: TextStyle(color: Colors.white.withOpacity(0.9)),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double opacity;
  const _Bubble({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}