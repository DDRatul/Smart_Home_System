import 'package:flutter/material.dart';
import '../auth_gate.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  void _go(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          const Positioned(top: -80, left: -60, child: _Bubble(size: 220, opacity: 0.16)),
          const Positioned(bottom: -90, right: -70, child: _Bubble(size: 260, opacity: 0.12)),

          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: Colors.white.withOpacity(0.22)),
                        ),
                        child: const Icon(Icons.shield_outlined, color: Colors.white, size: 42),
                      ),
                      const SizedBox(height: 18),

                      // ✅ title tap -> AuthGate
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _go(context),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          child: Text(
                            "Smart Crime Reporting",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      Text(
                        "Report incidents, attach evidence, and track status securely.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),

                      const SizedBox(height: 26),

                      // ✅ start button -> AuthGate
                      SizedBox(
                        height: 54,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _go(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F172A),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text(
                            "Start",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),
                      Text(
                        "Tap the title or press Start to continue",
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
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