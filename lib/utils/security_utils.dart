class PasswordStrengthResult {
  final double score; // 0.0 à 1.0
  final String label;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordStrengthResult({
    required this.score,
    required this.label,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  bool get isStrongEnough => hasMinLength && hasUppercase && hasLowercase && (hasDigit || hasSpecialChar);
}

class SecurityUtils {
  /// Validation du format d'email (RFC 5322 compatible regex)
  static bool isValidEmail(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9-]+\.[a-zA-Z]+",
    );
    return emailRegex.hasMatch(email.trim());
  }

  /// Validation des règles de complexité du mot de passe
  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return "Le mot de passe est obligatoire.";
    }
    if (password.length < 8) {
      return "Le mot de passe doit contenir au moins 8 caractères.";
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return "Le mot de passe doit contenir au moins une lettre majuscule.";
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return "Le mot de passe doit contenir au moins une lettre minuscule.";
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return "Le mot de passe doit contenir au moins un chiffre.";
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'))) {
      return "Le mot de passe doit contenir au moins un caractère spécial.";
    }
    return null;
  }

  /// Calcul du score et des critères de force d'un mot de passe
  static PasswordStrengthResult evaluatePasswordStrength(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0.0,
        label: "Trop court",
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasDigit: false,
        hasSpecialChar: false,
      );
    }

    final hasMinLength = password.length >= 8;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/]'));

    int criteriaMet = 0;
    if (hasMinLength) criteriaMet++;
    if (hasUppercase) criteriaMet++;
    if (hasLowercase) criteriaMet++;
    if (hasDigit) criteriaMet++;
    if (hasSpecialChar) criteriaMet++;
    if (password.length >= 12) criteriaMet++;

    double score = (criteriaMet / 6.0).clamp(0.0, 1.0);
    String label;

    if (score < 0.35) {
      label = "Faible";
    } else if (score < 0.65) {
      label = "Moyen";
    } else if (score < 0.9) {
      label = "Bon";
    } else {
      label = "Excellent";
    }

    return PasswordStrengthResult(
      score: score,
      label: label,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasDigit: hasDigit,
      hasSpecialChar: hasSpecialChar,
    );
  }

  /// Nettoyage basique des entrées utilisateur
  static String sanitizeInput(String input) {
    return input.trim();
  }
}
