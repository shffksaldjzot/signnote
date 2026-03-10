// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:excel/excel.dart';

// ============================================
// 엑셀/CSV 다운로드 유틸 (웹 환경)
// ============================================

// CSV 다운로드 (기존 호환)
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

// 엑셀(xlsx) 다운로드 — 제목행 + 중앙정렬 지원
Future<void> downloadExcel({
  required String title,         // 맨 윗줄에 표시할 행사 제목
  required List<String> headers, // 헤더 행 (컬럼명)
  required List<List<String>> dataRows, // 데이터 행들
  required String fileName,      // 파일명 (.xlsx 포함)
}) async {
  final excel = Excel.createExcel();
  // 기본 시트 이름 변경
  final defaultSheet = excel.getDefaultSheet();
  if (defaultSheet != null) {
    excel.rename(defaultSheet, '고객리스트');
  }
  final sheet = excel['고객리스트'];

  // 1행: 행사 제목 (병합 + 중앙정렬 + 굵게)
  final titleStyle = CellStyle(
    bold: true,
    fontSize: 14,
    horizontalAlign: HorizontalAlign.Center,
  );
  sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
    ..value = TextCellValue(title)
    ..cellStyle = titleStyle;

  // 제목 행 셀 병합 (첫 번째 셀부터 헤더 개수만큼)
  sheet.merge(
    CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    CellIndex.indexByColumnRow(columnIndex: headers.length - 1, rowIndex: 0),
  );

  // 2행: 헤더 (굵게 + 중앙정렬 + 배경색)
  final headerStyle = CellStyle(
    bold: true,
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Center,
    backgroundColorHex: ExcelColor.fromHexString('#E0E0E0'),
  );
  for (var col = 0; col < headers.length; col++) {
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1))
      ..value = TextCellValue(headers[col])
      ..cellStyle = headerStyle;
  }

  // 3행~: 데이터 (모두 중앙정렬)
  final dataStyle = CellStyle(
    fontSize: 11,
    horizontalAlign: HorizontalAlign.Center,
  );
  for (var row = 0; row < dataRows.length; row++) {
    for (var col = 0; col < dataRows[row].length; col++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row + 2))
        ..value = TextCellValue(dataRows[row][col])
        ..cellStyle = dataStyle;
    }
  }

  // 컬럼 너비 자동 조정 (대략적)
  for (var col = 0; col < headers.length; col++) {
    sheet.setColumnWidth(col, 15);
  }

  // xlsx 바이트 생성 + 다운로드
  final fileBytes = excel.save();
  if (fileBytes == null) return;

  final blob = html.Blob(
    [fileBytes],
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);

  html.AnchorElement(href: url)
    ..setAttribute('download', fileName)
    ..click();

  html.Url.revokeObjectUrl(url);
}
