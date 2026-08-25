import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/finance_service.dart';
import '../services/voice_assistant_service.dart';
import '../widgets/glass_container.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({super.key});

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with SingleTickerProviderStateMixin {
  late VoiceAssistantService _voiceAssistantService;
  late AnimationController _blobController;

  @override
  void initState() {
    super.initState();
    final financeService = Provider.of<FinanceService>(context, listen: false);
    _voiceAssistantService = VoiceAssistantService(financeService);
    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _blobController.dispose();
    // Ensure any active listening is stopped when the screen is disposed
    _voiceAssistantService.stopListening();
    _voiceAssistantService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final blobSize = size.width * 0.65;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF050816) : const Color(0xFFF5F7FF),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDark
                    ? const [Color(0xFF050816), Color(0xFF020617)]
                    : const [Color(0xFF4F46E5), Color(0xFF111827)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ListenableBuilder(
              listenable: _voiceAssistantService,
              builder: (context, _) {
                final isListening = _voiceAssistantService.isListening;
                final isProcessing = _voiceAssistantService.isProcessing;
                final recognizedText = _voiceAssistantService.recognizedText;
                final status = _voiceAssistantService.statusMessage;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildExampleChip('Add expense 500 food'),
                          _buildExampleChip('Add income 2000 salary'),
                          _buildExampleChip('Set goal 10000 laptop'),
                          _buildExampleChip('Read my last 5 transactions'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Hi there,',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      style: GoogleFonts.orbitron(
                        fontSize: isListening ? 26 : 24,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 3.0,
                        color: Colors.white,
                        shadows:
                            isListening
                                ? [
                                  const Shadow(
                                    color: Color(0xFF818CF8),
                                    blurRadius: 16,
                                    offset: Offset(0, 0),
                                  ),
                                ]
                                : [],
                      ),
                      child: const Text('SAY SOMETHING'),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Center(
                        child: _buildAnimatedBlob(
                          blobSize: blobSize,
                          isListening: isListening,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: Padding(
                        key: ValueKey<String>(
                          recognizedText.isEmpty
                              ? 'placeholder'
                              : recognizedText,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          recognizedText.isEmpty
                              ? 'Say things like "Add expense 500 food" or "Set goal 10000 laptop".'
                              : recognizedText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white.withOpacity(0.92),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: status.isEmpty ? 0.0 : 1.0,
                      child: Text(
                        status,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.85),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBottomIconButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 32),
                        _buildMicButton(
                          isListening: isListening,
                          isProcessing: isProcessing,
                        ),
                        const SizedBox(width: 32),
                        _buildBottomIconButton(
                          icon: Icons.close_rounded,
                          onTap: () async {
                            await _voiceAssistantService.stopListening();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBlob({
    required double blobSize,
    required bool isListening,
  }) {
    final activity = isListening ? 1.0 : 0.0;
    final baseOpacity = 0.55 + 0.45 * activity;

    return AnimatedBuilder(
      animation: _blobController,
      builder: (context, child) {
        final t = _blobController.value;
        final pulse = 1.0 + activity * 0.22 * math.sin(t * 2 * math.pi);
        final rotation = activity * t * 2 * math.pi;
        final innerPulse = 1.0 + activity * 0.20 * math.sin(t * 4 * math.pi);

        return SizedBox(
          width: blobSize,
          height: blobSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: rotation,
                child: Container(
                  width: blobSize,
                  height: blobSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF9F7AEA).withOpacity(baseOpacity * 0.8),
                        const Color(0xFF4C1D95).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: -rotation * 1.1,
                child: Container(
                  width: blobSize * 0.85 * pulse,
                  height: blobSize * 0.85 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF60A5FA).withOpacity(baseOpacity * 0.9),
                        const Color(0xFF1E3A8A).withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.rotate(
                angle: rotation * 0.8,
                child: Container(
                  width: blobSize * 0.6,
                  height: blobSize * 0.6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFFA5D8), Color(0xFF818CF8)],
                    ),
                  ),
                ),
              ),
              Container(
                width: blobSize * 0.22 * innerPulse,
                height: blobSize * 0.22 * innerPulse,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
              Container(
                width: blobSize * 0.22 * innerPulse,
                height: blobSize * 0.22 * innerPulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMicButton({
    required bool isListening,
    required bool isProcessing,
  }) {
    const baseColor = Color(0xFF6366F1);

    return GestureDetector(
      onTap: () {
        if (isProcessing) {
          return;
        }
        if (isListening) {
          _voiceAssistantService.stopListening();
        } else {
          _voiceAssistantService.startListening();
        }
      },
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: isListening ? 1.0 : 0.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) {
          final outerSize = 120 + (value * 18);
          final innerGlowOpacity = 0.35 + (value * 0.25);
          final rippleScale1 = 1.2 + value * 0.3;
          final rippleOpacity1 = 0.35 * value;
          final rippleScale2 = 1.4 + value * 0.4;
          final rippleOpacity2 = 0.25 * value;

          return SizedBox(
            width: outerSize,
            height: outerSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isListening)
                  Container(
                    width: outerSize * rippleScale2,
                    height: outerSize * rippleScale2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(rippleOpacity2),
                        width: 1.0,
                      ),
                    ),
                  ),
                if (isListening)
                  Container(
                    width: outerSize * rippleScale1,
                    height: outerSize * rippleScale1,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(rippleOpacity1),
                        width: 1.2,
                      ),
                    ),
                  ),
                Container(
                  width: outerSize,
                  height: outerSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        baseColor.withOpacity(innerGlowOpacity),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                GlassContainer(
                  borderRadius: outerSize / 2,
                  blur: 20,
                  opacity: 0.22,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ],
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        isProcessing
                            ? Icons.hourglass_top_rounded
                            : isListening
                            ? Icons.mic_rounded
                            : Icons.mic_none_rounded,
                        size: 34,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomIconButton({required IconData icon, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 22,
        blur: 16,
        opacity: 0.18,
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 22, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }

  Widget _buildExampleChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GlassContainer(
        borderRadius: 22,
        blur: 18,
        opacity: 0.16,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.close_rounded,
              size: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ],
        ),
      ),
    );
  }
}
