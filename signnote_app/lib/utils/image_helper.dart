import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// ============================================
// 이미지 표시 헬퍼
//
// base64 데이터 URL (data:image/...;base64,...) 과
// 일반 네트워크 URL (https://...) 둘 다 처리
// ============================================

/// 이미지 문자열이 base64 데이터 URL인지 확인
bool isBase64DataUrl(String? url) {
  if (url == null) return false;
  return url.startsWith('data:image');
}

/// base64 데이터 URL에서 바이트 추출
Uint8List? decodeBase64Image(String dataUrl) {
  try {
    // "data:image/png;base64,iVBORw0..." 에서 base64 부분만 추출
    final parts = dataUrl.split(',');
    if (parts.length < 2) return null;
    return base64Decode(parts[1]);
  } catch (_) {
    return null;
  }
}

/// 이미지 URL(base64 또는 네트워크)을 자동 감지하여 Image 위젯 반환
Widget buildSmartImage(
  String? imageUrl, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
}) {
  // 이미지 없을 때 플레이스홀더
  if (imageUrl == null || imageUrl.isEmpty) {
    return placeholder ?? const Icon(Icons.image_outlined, color: Color(0xFF9CA3AF));
  }

  // base64 데이터 URL
  if (isBase64DataUrl(imageUrl)) {
    final bytes = decodeBase64Image(imageUrl);
    if (bytes != null) {
      return Image.memory(bytes, width: width, height: height, fit: fit);
    }
    return placeholder ?? const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF));
  }

  // 일반 네트워크 URL
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) =>
        placeholder ?? const Icon(Icons.broken_image_outlined, color: Color(0xFF9CA3AF)),
  );
}
