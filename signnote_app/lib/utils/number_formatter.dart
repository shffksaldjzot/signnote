import 'package:flutter/services.dart';

// ============================================
// 숫자 콤마 포맷터
//
// 숫자 입력 시 자동으로 천 단위 콤마 삽입
// 예: 500000 → 500,000
//
// 사용법:
//   TextField(
//     inputFormatters: [CommaFormatter()],
//   )
//
// 서버 전송 시 콤마 제거:
//   parseCommaNumber('500,000') → 500000
// ============================================

/// 숫자 입력 시 자동 콤마 삽입 포맷터
class CommaFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // 빈 값이면 그대로
    if (newValue.text.isEmpty) return newValue;

    // 숫자만 추출 (콤마, 공백 등 제거)
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) return const TextEditingValue(text: '');

    // 콤마 삽입
    final formatted = _addCommas(digitsOnly);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// 숫자 문자열에 천 단위 콤마 삽입
  String _addCommas(String digits) {
    final buffer = StringBuffer();
    final length = digits.length;
    for (int i = 0; i < length; i++) {
      buffer.write(digits[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }
}

/// 콤마가 포함된 문자열에서 숫자만 추출 (서버 전송용)
/// 예: '500,000' → 500000
int parseCommaNumber(String text) {
  final digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');
  return int.tryParse(digitsOnly) ?? 0;
}

/// 콤마가 포함된 문자열에서 소수점 숫자 추출
/// 예: '1,234.56' → 1234.56
double parseCommaDouble(String text) {
  final cleaned = text.replaceAll(',', '');
  return double.tryParse(cleaned) ?? 0.0;
}

/// 숫자를 콤마 포맷 문자열로 변환 (표시용)
/// 예: 500000 → '500,000'
String formatWithComma(int number) {
  final text = number.toString();
  final buffer = StringBuffer();
  final length = text.length;
  for (int i = 0; i < length; i++) {
    buffer.write(text[i]);
    final remaining = length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
