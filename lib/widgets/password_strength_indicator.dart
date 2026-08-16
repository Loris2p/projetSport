import 'package:flutter/material.dart';
import '../utils/security_utils.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = SecurityUtils.evaluatePasswordStrength(password);

    Color getStatusColor() {
      if (strength.score < 0.35) return const Color(0xffef4444); // Rouge
      if (strength.score < 0.65) return const Color(0xfff59e0b); // Ambre / Orange
      if (strength.score < 0.9) return const Color(0xff3b82f6); // Bleu
      return const Color(0xff10b981); // Vert émeraude
    }

    final color = getStatusColor();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barre de progression segmentée
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strength.score,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                strength.label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Liste des critères
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              _buildCriterion("8+ car.", strength.hasMinLength),
              _buildCriterion("Maj & Min", strength.hasUppercase && strength.hasLowercase),
              _buildCriterion("Chiffre (0-9)", strength.hasDigit),
              _buildCriterion("Symbole (@#\$)", strength.hasSpecialChar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriterion(String label, bool isMet) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: isMet ? const Color(0xff10b981) : Colors.white38,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isMet ? Colors.white : Colors.white54,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
