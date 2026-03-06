import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

// ============================================
// 이미지 다운로드 유틸 (웹 환경)
// PNG 바이트를 브라우저에서 파일로 다운로드
// ============================================

Future<void> downloadImageBytes(Uint8List bytes, String fileName) async {
  final base64 = base64Encode(bytes);
  final dataUrl = 'data:image/png;base64,$base64';

  html.AnchorElement(href: dataUrl)
    ..setAttribute('download', fileName)
    ..click();
}
