import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../widgets/layout/app_header.dart';
import '../../widgets/common/app_button.dart';
import '../../services/event_service.dart';
import '../../utils/number_formatter.dart';

// ============================================
// 주관사용 행사 생성/수정 폼 화면
//
// 디자인 참고: 13.주관사용-행사 등록.jpg
// - 상단: ← "행사 등록" 헤더
// - 입력 필드들:
//   - 행사명
//   - 현장명
//   - 세대수
//   - 입주 예정일
//   - 행사 기간 (시작일 ~ 종료일)
//   - 평형 타입 (체크박스)
//   - 계약 방식 (현장/온라인 선택)
//   - 취소 가능 기간
// - 하단: "등록하기" 버튼
// - 등록 성공 시 참여 코드(6자리 숫자) 자동 생성됨
// ============================================

class OrganizerEventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? event;  // 수정 시 기존 데이터 (null이면 새 등록)

  const OrganizerEventFormScreen({super.key, this.event});

  @override
  State<OrganizerEventFormScreen> createState() =>
      _OrganizerEventFormScreenState();
}

class _OrganizerEventFormScreenState extends State<OrganizerEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  // 입력 필드 컨트롤러들
  late final TextEditingController _titleController;
  late final TextEditingController _siteNameController;
  late final TextEditingController _unitCountController;

  // 날짜 선택
  DateTime? _moveInDate;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _cancelDeadlineStart;
  DateTime? _cancelDeadlineEnd;

  // 평형 타입 (자유 입력 방식 — 아파트 단지마다 타입이 다를 수 있으므로)
  late List<String> _selectedTypes;
  final TextEditingController _typeInputController = TextEditingController();

  // 계약 방식: 'integrated'(통합계약) 또는 'individual'(개별계약)
  String _contractMethod = 'integrated';
  bool _allowOnlineContract = true;

  // 커버 이미지 (base64 문자열)
  String? _coverImageBase64;
  Uint8List? _coverImageBytes; // 미리보기용

  bool _isLoading = false;
  bool get _isEditMode => widget.event != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?['title'] ?? '');
    _siteNameController = TextEditingController(text: widget.event?['siteName'] ?? '');
    _unitCountController = TextEditingController(
      text: widget.event?['unitCount']?.toString() ?? '',
    );
    _selectedTypes = List<String>.from(
      widget.event?['housingTypes'] ?? [],
    );

    // 수정 모드일 때 기존 날짜 채우기
    if (widget.event != null) {
      _startDate = widget.event!['startDate'];
      _endDate = widget.event!['endDate'];
      _moveInDate = widget.event!['moveInDate'];
      _contractMethod = widget.event!['contractMethod'] ?? 'integrated';
      _allowOnlineContract = widget.event!['allowOnlineContract'] ?? true;
      // 기존 커버이미지가 있으면 불러오기
      final existingImage = widget.event!['coverImage']?.toString();
      if (existingImage != null && existingImage.startsWith('data:image')) {
        _coverImageBase64 = existingImage;
        try {
          final base64Str = existingImage.split(',').last;
          _coverImageBytes = base64Decode(base64Str);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _siteNameController.dispose();
    _unitCountController.dispose();
    _typeInputController.dispose();
    super.dispose();
  }

  // 날짜 선택 다이얼로그
  // (한국어 설정은 main.dart에서 전체 적용됨)
  Future<DateTime?> _pickDate(DateTime? initialDate) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
  }

  // 날짜를 텍스트로 변환
  String _formatDate(DateTime? date) {
    if (date == null) return '날짜 선택';
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 날짜를 API 전송용 문자열로 변환 (ISO 8601)
  String _toIsoDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  // 폼 제출 — 실제 API 호출
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('행사 시작일과 종료일을 선택해 주세요')),
      );
      return;
    }
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('평형 타입을 1개 이상 선택해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isEditMode) {
      // 수정 모드: updateEvent API 호출
      result = await _eventService.updateEvent(
        widget.event!['id'].toString(),
        {
          'title': _titleController.text,
          'startDate': _toIsoDate(_startDate!),
          'endDate': _toIsoDate(_endDate!),
          if (_siteNameController.text.isNotEmpty)
            'siteName': _siteNameController.text,
          if (_unitCountController.text.isNotEmpty)
            'unitCount': parseCommaNumber(_unitCountController.text),
          if (_moveInDate != null)
            'moveInDate': _toIsoDate(_moveInDate!),
          'housingTypes': _selectedTypes.toList(),
          'contractMethod': _contractMethod,
          'allowOnlineContract': _allowOnlineContract,
          if (_coverImageBase64 != null)
            'coverImage': _coverImageBase64,
          if (_cancelDeadlineStart != null)
            'cancelDeadlineStart': _toIsoDate(_cancelDeadlineStart!),
          if (_cancelDeadlineEnd != null)
            'cancelDeadlineEnd': _toIsoDate(_cancelDeadlineEnd!),
        },
      );
    } else {
      // 등록 모드: createEvent API 호출
      result = await _eventService.createEvent(
        title: _titleController.text,
        startDate: _toIsoDate(_startDate!),
        endDate: _toIsoDate(_endDate!),
        siteName: _siteNameController.text.isNotEmpty
            ? _siteNameController.text
            : null,
        unitCount: _unitCountController.text.isNotEmpty
            ? parseCommaNumber(_unitCountController.text)
            : null,
        moveInDate: _moveInDate != null ? _toIsoDate(_moveInDate!) : null,
        housingTypes: _selectedTypes.toList(),
        coverImage: _coverImageBase64,
        contractMethod: _contractMethod,
        allowOnlineContract: _allowOnlineContract,
        cancelDeadlineStart: _cancelDeadlineStart != null
            ? _toIsoDate(_cancelDeadlineStart!)
            : null,
        cancelDeadlineEnd: _cancelDeadlineEnd != null
            ? _toIsoDate(_cancelDeadlineEnd!)
            : null,
      );
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      if (!_isEditMode) {
        // 등록 성공 시 서버에서 반환한 실제 참여 코드 사용
        final event = result['event'] ?? {};
        final entryCode = event['entryCode']?.toString() ?? '------';
        _showEntryCodeDialog(entryCode);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('행사가 수정되었습니다')),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '처리에 실패했습니다')),
      );
    }
  }

  // 참여 코드 생성 완료 다이얼로그
  void _showEntryCodeDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          '행사가 등록되었습니다!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '참여 코드',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            // 참여 코드 크게 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 8,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // 복사하기 버튼
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('참여 코드가 복사되었습니다')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('복사하기'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            const SizedBox(height: 4),
            const Text(
              '이 코드를 고객과 업체에게 공유해 주세요',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();    // 다이얼로그 닫기
                Navigator.of(context).pop(true); // 폼 화면 닫기
              },
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppHeader(title: _isEditMode ? '행사 수정' : '행사 등록'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 행사명
              _buildLabel('행사명'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: '예: 창원 자이 사전 박람회',
                validator: (v) => v == null || v.isEmpty ? '행사명을 입력해 주세요' : null,
              ),
              const SizedBox(height: 20),

              // 현장명
              _buildLabel('현장명'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _siteNameController,
                hint: '예: 창원 자이 아파트',
              ),
              const SizedBox(height: 20),

              // 세대수
              _buildLabel('세대수'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _unitCountController,
                hint: '예: 500',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CommaFormatter(),  // 천 단위 콤마 자동 삽입
                ],
              ),
              const SizedBox(height: 20),

              // 입주 예정일
              _buildLabel('입주 예정일'),
              const SizedBox(height: 8),
              _buildDatePicker(
                date: _moveInDate,
                onTap: () async {
                  final picked = await _pickDate(_moveInDate);
                  if (picked != null) setState(() => _moveInDate = picked);
                },
              ),
              const SizedBox(height: 20),

              // 평형 타입 (자유 입력)
              _buildLabel('평형 타입'),
              const SizedBox(height: 8),
              _buildTypeInput(),
              const SizedBox(height: 20),

              // 계약 방식
              _buildLabel('계약 방식'),
              const SizedBox(height: 8),
              _buildContractMethodSelector(),
              const SizedBox(height: 20),

              // 커버 이미지 (행사 카드 배경으로 사용)
              _buildLabel('커버 이미지 (선택)'),
              const SizedBox(height: 8),
              _buildCoverImagePicker(),
              const SizedBox(height: 20),

              // 행사 기간 (취소 가능 기간 바로 위에 배치)
              _buildLabel('행사 기간'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      date: _startDate,
                      onTap: () async {
                        final picked = await _pickDate(_startDate);
                        if (picked != null) setState(() => _startDate = picked);
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('~', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    child: _buildDatePicker(
                      date: _endDate,
                      onTap: () async {
                        final picked = await _pickDate(_endDate);
                        if (picked != null) setState(() => _endDate = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 취소 가능 기간
              _buildLabel('취소 가능 기간 (선택)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDatePicker(
                      date: _cancelDeadlineStart,
                      onTap: () async {
                        final picked = await _pickDate(_cancelDeadlineStart);
                        if (picked != null) {
                          setState(() => _cancelDeadlineStart = picked);
                        }
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('~', style: TextStyle(fontSize: 16)),
                  ),
                  Expanded(
                    child: _buildDatePicker(
                      date: _cancelDeadlineEnd,
                      onTap: () async {
                        final picked = await _pickDate(_cancelDeadlineEnd);
                        if (picked != null) {
                          setState(() => _cancelDeadlineEnd = picked);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // 등록/수정 버튼
              AppButton.black(
                text: _isEditMode ? '수정하기' : '등록하기',
                isLoading: _isLoading,
                onPressed: _handleSubmit,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 라벨 텍스트
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }

  // 공통 텍스트 입력 필드
  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // 날짜 선택 위젯
  Widget _buildDatePicker({DateTime? date, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(date),
              style: TextStyle(
                fontSize: 14,
                color: date != null ? AppColors.textPrimary : AppColors.textHint,
              ),
            ),
            const Icon(Icons.calendar_today, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  // 평형 타입 자유 입력 + 추가 버튼
  // (아파트 단지마다 타입이 다를 수 있으므로 직접 입력)
  Widget _buildTypeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 입력 필드 (suffix에 추가 버튼 포함)
        TextField(
          controller: _typeInputController,
          decoration: InputDecoration(
            hintText: '예: 84A, 59B 등',
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            // 입력 필드 오른쪽에 추가 버튼
            suffixIcon: GestureDetector(
              onTap: _addType,
              child: Container(
                margin: const EdgeInsets.all(4),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '추가',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
            suffixIconConstraints: const BoxConstraints(minWidth: 60, minHeight: 40),
          ),
          onSubmitted: (_) => _addType(),  // 엔터 키로도 추가 가능
        ),
        const SizedBox(height: 12),
        // 추가된 타입 목록 (칩 형태, X 버튼으로 삭제 가능)
        if (_selectedTypes.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTypes.map((type) {
              return Chip(
                label: Text('$type타입'),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _selectedTypes.remove(type));
                },
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                labelStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppColors.primary),
                ),
              );
            }).toList(),
          )
        else
          Text(
            '아직 추가된 타입이 없습니다',
            style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          ),
      ],
    );
  }

  // 타입 추가 처리
  void _addType() {
    final text = _typeInputController.text.trim();
    if (text.isEmpty) return;
    if (_selectedTypes.contains(text)) {
      // 이미 있는 타입이면 안내
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('\'$text\' 타입이 이미 추가되어 있습니다')),
      );
      return;
    }
    setState(() {
      _selectedTypes.add(text);
      _typeInputController.clear();
    });
  }

  // 커버 이미지 선택 (파일 선택 다이얼로그 → base64 변환)
  // file_picker 사용 — PC 웹 + 모바일 모두 호환
  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,  // 이미지 파일만 선택 가능
        withData: true,        // 파일 바이트 데이터 포함
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

      // base64 문자열로 변환 (data URL 형식)
      final base64Str = base64Encode(bytes);
      final extension = file.extension?.toLowerCase() ?? 'jpg';
      final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

      setState(() {
        _coverImageBase64 = 'data:$mimeType;base64,$base64Str';
        _coverImageBytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  // 커버 이미지 선택/미리보기 위젯
  Widget _buildCoverImagePicker() {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: _coverImageBytes != null
            // 이미지가 선택된 경우: 미리보기 표시
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _coverImageBytes!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  // 삭제 버튼
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _coverImageBase64 = null;
                          _coverImageBytes = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              )
            // 이미지가 없는 경우: 업로드 안내
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text(
                    '탭하여 커버 이미지 선택',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '행사 카드 배경으로 표시됩니다',
                    style: TextStyle(fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
      ),
    );
  }

  // 계약 방식 선택 (라디오 버튼)
  // 통합계약: 모든 품목을 한 번에 계약 / 개별계약: 품목별로 따로 계약
  Widget _buildContractMethodSelector() {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('통합계약', style: TextStyle(fontSize: 14)),
          subtitle: const Text('모든 품목을 한 번에 계약', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          value: 'integrated',
          groupValue: _contractMethod,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() {
            _contractMethod = v!;
          }),
        ),
        RadioListTile<String>(
          title: const Text('개별계약', style: TextStyle(fontSize: 14)),
          subtitle: const Text('품목별로 따로 계약', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          value: 'individual',
          groupValue: _contractMethod,
          activeColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) => setState(() {
            _contractMethod = v!;
          }),
        ),
      ],
    );
  }
}
