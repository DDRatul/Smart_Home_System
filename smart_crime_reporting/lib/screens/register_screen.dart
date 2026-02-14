import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _auth = AuthService();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _err;
  bool _obscure = true;

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      await _auth.register(_email.text.trim(), _pass.text);
      if (mounted) Navigator.pop(context);
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
          const Positioned(top: -80, left: -60, child: _Bubble(size: 220, opacity: 0.16)),
          const Positioned(bottom: -90, right: -70, child: _Bubble(size: 260, opacity: 0.12)),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.22,
            right: -40,
            child: const _Bubble(size: 140, opacity: 0.10),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Back button row
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

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
                            child: const Icon(Icons.person_add_alt_1_outlined, size: 34, color: Colors.white),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            "Join Smart Crime Reporting",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Create your account to submit and track reports.",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white.withOpacity(0.82)),
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Glass card form
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
                                hint: "Minimum 6 characters",
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
                                  final s = (v ?? "");
                                  if (s.isEmpty) return "Password is required";
                                  if (s.length < 6) return "Minimum 6 characters";
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
                                  onPressed: _loading ? null : _register,
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
                                          "Create account",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              TextButton(
                                onPressed: _loading ? null : () => Navigator.pop(context),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white.withOpacity(0.92),
                                ),
                                child: const Text("Already have an account? Login"),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      Text(
                        "By creating an account, you agree to Terms & Privacy.",
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