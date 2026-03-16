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

/// 전화번호 하이픈 포맷 (A-10, B-37 공통)
/// 예: '01012341234' → '010-1234-1234'
/// 예: '0212345678' → '02-1234-5678'
String formatPhone(String? phone) {
  if (phone == null || phone.isEmpty) return '-';
  // 숫자만 추출
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
  // 이미 하이픈이 있으면 그대로 반환
  if (phone.contains('-') && phone.length >= 12) return phone;
  // 010-XXXX-XXXX (11자리)
  if (digits.length == 11) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
  }
  // 02-XXXX-XXXX (10자리, 서울)
  if (digits.length == 10 && digits.startsWith('02')) {
    return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  // 0XX-XXX-XXXX (10자리, 지역번호)
  if (digits.length == 10) {
    return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  // 그 외는 원본 반환
  return phone;
}

/// 날짜 문자열을 한국어 친화 형식으로 변환 (A-12)
/// 예: '2026-03-11T14:30:00' → '3.11 14:30'
/// 예: '2026-03-11T14:30:00' (오늘이면) → '오늘 14:30'
String formatDateKr(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '';
  try {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    if (dateOnly == today) {
      return '오늘 $hour:$minute';
    }
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return '어제 $hour:$minute';
    }
    return '${date.month}.${date.day} $hour:$minute';
  } catch (_) {
    // 파싱 실패 시 원본에서 최소한 T를 제거하고 반환
    return dateStr.length >= 16
        ? dateStr.substring(0, 16).replaceAll('T', ' ')
        : dateStr;
  }
}
