// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

// ============================================
// CSV 다운로드 유틸 (웹 환경)
// 엑셀 호환 CSV 파일을 브라우저에서 다운로드
// ============================================

Future<void> downloadCsv(List<List<String>> rows, String fileName) async {
  // BOM (Byte Order Mark) — 엑셀에서 한글 깨짐 방지
  const bom = '\uFEFF';

  final csvContent = rows.map((row) {
    return row.map((cell) {
      // 쉼표나 줄바꿈이 있으면 따옴표로 감싸기
      if (cell.contains(',') || cell.contains('\n') || cell.contains('"')) {
        return '"${cell.replaceAll('"', '""')}"';
      }
      return cell;
    }).join(',');
  }).join('\n');

  final bytes = utf8.encode('$bom$csvContent');
  final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}
