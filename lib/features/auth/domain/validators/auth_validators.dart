abstract final class AuthValidators {
  static final _emailPattern = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );

  static String? name(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Атыңызды енгізіңіз';
    if (text.length < 2) return 'Кемінде 2 таңба енгізіңіз';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email енгізіңіз';
    if (!_emailPattern.hasMatch(text)) return 'Дұрыс email енгізіңіз';
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'Құпиясөзді енгізіңіз';
    if (text.length < 8) return 'Кемінде 8 таңба болуы керек';
    if (!RegExp(r'[A-Za-zА-Яа-яӘәҒғҚқҢңӨөҰұҮүІі]').hasMatch(text) ||
        !RegExp(r'\d').hasMatch(text)) {
      return 'Құпиясөзде әріп пен сан болуы керек';
    }
    return null;
  }

  static String? confirmation(String? value, String password) {
    if ((value ?? '').isEmpty) return 'Құпиясөзді қайталаңыз';
    if (value != password) return 'Құпиясөздер сәйкес келмейді';
    return null;
  }
}
