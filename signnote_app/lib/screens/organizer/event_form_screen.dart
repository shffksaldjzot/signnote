import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../config/theme.dart';
import '../../services/event_service.dart';
import '../../utils/number_formatter.dart';

// ============================================
// 주관사용 행사 생성/수정 폼 (2차 디자인)
//
// 디자인 참고: 2.주관사용-행사 추가.jpg
// 필드 순서:
//   행사 제목 → 계약 방식(드롭다운) → 현장명 → 세대수 →
//   입주 예정일(월) → 적용 타입(칩+추가) → 커버 이미지 →
//   행사 기간(범위) → 취소 지정 기간(범위) →
//   취소 기간 온라인 계약 여부 → 작성 완료
// ============================================

class OrganizerEventFormScreen extends StatefulWidget {
  final Map<String, dynamic>? event; // 수정 시 기존 데이터

  const OrganizerEventFormScreen({super.key, this.event});

  @override
  State<OrganizerEventFormScreen> createState() =>
      _OrganizerEventFormScreenState();
}

class _OrganizerEventFormScreenState extends State<OrganizerEventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EventService _eventService = EventService();

  // 입력 필드 컨트롤러
  late final TextEditingController _titleController;
  late final TextEditingController _siteNameController;
  late final TextEditingController _unitCountController;

  // 날짜 선택
  DateTime? _moveInDate;
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _cancelDeadlineStart;
  DateTime? _cancelDeadlineEnd;

  // 평형 타입
  late List<String> _selectedTypes;
  final TextEditingController _typeInputController = TextEditingController();

  // 계약 방식
  String _contractMethod = 'integrated';
  bool _allowOnlineContract = true;

  // 커버 이미지
  String? _coverImageBase64;
  Uint8List? _coverImageBytes;

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
    _selectedTypes = List<String>.from(widget.event?['housingTypes'] ?? []);

    if (widget.event != null) {
      _startDate = widget.event!['startDate'];
      _endDate = widget.event!['endDate'];
      _moveInDate = widget.event!['moveInDate'];
      _contractMethod = widget.event!['contractMethod'] ?? 'integrated';
      _allowOnlineContract = widget.event!['allowOnlineContract'] ?? true;
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

  // 날짜 범위 선택 (숙박 예약 스타일)
  Future<void> _pickDateRange({
    required DateTime? currentStart,
    required DateTime? currentEnd,
    required void Function(DateTime start, DateTime end) onPicked,
  }) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDateRange: currentStart != null && currentEnd != null
          ? DateTimeRange(start: currentStart, end: currentEnd)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.organizer, // 주황색 강조
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onPicked(picked.start, picked.end);
    }
  }

  // 월 선택기 (입주 예정일)
  Future<void> _pickMonth() async {
    // showDatePicker를 사용하되 일(day)는 1일로 고정
    final picked = await showDatePicker(
      context: context,
      initialDate: _moveInDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year, // 연/월 먼저 선택
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.organizer,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _moveInDate = DateTime(picked.year, picked.month, 1));
    }
  }

  // 날짜 표시 포맷
  String _formatDate(DateTime? date) {
    if (date == null) return '날짜 선택';
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  // 월 표시 포맷
  String _formatMonth(DateTime? date) {
    if (date == null) return '날짜 선택';
    return '${date.year}. ${date.month.toString().padLeft(2, '0')}월';
  }

  // 범위 표시 포맷
  String _formatRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '날짜 선택';
    return '${_formatDate(start)} ~ ${_formatDate(end)}';
  }

  // API 전송용 ISO 날짜
  String _toIsoDate(DateTime date) {
    return date.toIso8601String().split('T').first;
  }

  // 폼 제출
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('행사 기간을 선택해 주세요')),
      );
      return;
    }
    if (_selectedTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('적용 타입을 1개 이상 추가해 주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> result;

    if (_isEditMode) {
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
                  color: AppColors.organizer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('참여 코드가 복사되었습니다')),
                );
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('복사하기'),
              style: TextButton.styleFrom(foregroundColor: AppColors.organizer),
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
                Navigator.of(context).pop();
                Navigator.of(context).pop(true);
              },
              child: const Text(
                '확인',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.organizer),
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
      // 상단 바: ← "행사 추가하기"
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isEditMode ? '행사 수정하기' : '행사 추가하기',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 행사 제목 ──
              _buildLabel('행사 제목'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hint: '제목을 입력해주세요.',
                validator: (v) => v == null || v.isEmpty ? '행사 제목을 입력해 주세요' : null,
              ),
              const SizedBox(height: 20),

              // ── 계약 방식 (드롭다운) ──
              _buildContractMethodDropdown(),
              const SizedBox(height: 20),

              // ── 현장명 ──
              _buildLabel('현장명'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _siteNameController,
                hint: '현장명을 입력해 주세요.',
              ),
              const SizedBox(height: 20),

              // ── 세대수 ──
              _buildLabel('세대수'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _unitCountController,
                hint: '',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CommaFormatter(),
                ],
                suffixText: '세대',
              ),
              const SizedBox(height: 20),

              // ── 입주 예정일 (월 선택) ──
              _buildLabel('입주 예정일'),
              const SizedBox(height: 8),
              _buildTapField(
                text: _formatMonth(_moveInDate),
                hasValue: _moveInDate != null,
                onTap: _pickMonth,
              ),
              const SizedBox(height: 20),

              // ── 적용 타입 (칩 + 추가 버튼) ──
              _buildLabel('적용 타입'),
              const SizedBox(height: 8),
              _buildTypeInput(),
              const SizedBox(height: 20),

              // ── 커버 이미지 ──
              _buildLabel('커버 이미지'),
              const SizedBox(height: 8),
              _buildCoverImagePicker(),
              const SizedBox(height: 20),

              // ── 행사 기간 (범위 선택) ──
              _buildLabel('행사 기간'),
              const SizedBox(height: 8),
              _buildTapField(
                text: _formatRange(_startDate, _endDate),
                hasValue: _startDate != null && _endDate != null,
                onTap: () => _pickDateRange(
                  currentStart: _startDate,
                  currentEnd: _endDate,
                  onPicked: (start, end) => setState(() {
                    _startDate = start;
                    _endDate = end;
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // ── 취소 지정 기간 (범위 선택) ──
              _buildLabel('취소 지정 기간'),
              const SizedBox(height: 8),
              _buildTapField(
                text: _formatRange(_cancelDeadlineStart, _cancelDeadlineEnd),
                hasValue: _cancelDeadlineStart != null && _cancelDeadlineEnd != null,
                onTap: () => _pickDateRange(
                  currentStart: _cancelDeadlineStart,
                  currentEnd: _cancelDeadlineEnd,
                  onPicked: (start, end) => setState(() {
                    _cancelDeadlineStart = start;
                    _cancelDeadlineEnd = end;
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // ── 취소 지정 기간 온라인 계약 허용 여부 ──
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Text(
                      '취소 지정기간에도 온라인을 통해 계약이 가능하도록 하시겠습니까?',
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 예/아니오 드롭다운
                  DropdownButton<bool>(
                    value: _allowOnlineContract,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: true, child: Text('예')),
                      DropdownMenuItem(value: false, child: Text('아니오')),
                    ],
                    onChanged: (v) => setState(() => _allowOnlineContract = v!),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── 작성 완료 / 수정하기 버튼 (주황색) ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.organizer,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                      : Text(_isEditMode ? '수정하기' : '작성 완료'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 라벨
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

  // 텍스트 입력 필드
  Widget _buildTextField({
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        suffixText: suffixText,
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
          borderSide: const BorderSide(color: AppColors.organizer, width: 1.5),
        ),
      ),
    );
  }

  // 탭 가능한 필드 (날짜 선택 등)
  Widget _buildTapField({
    required String text,
    required bool hasValue,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: hasValue ? AppColors.textPrimary : AppColors.textHint,
          ),
        ),
      ),
    );
  }

  // 계약 방식 드롭다운 (디자인: 드롭다운 버튼)
  Widget _buildContractMethodDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _contractMethod,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: const [
            DropdownMenuItem(value: 'integrated', child: Text('계약 방식: 통합 계약')),
            DropdownMenuItem(
              value: 'individual',
              enabled: false, // 비활성화
              child: Text('계약 방식: 개별 계약 (준비중)', style: TextStyle(color: AppColors.textHint)),
            ),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _contractMethod = v);
          },
        ),
      ),
    );
  }

  // 평형 타입 입력 (칩 + 추가 버튼)
  Widget _buildTypeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 추가된 타입 칩 + 추가 버튼 (한 줄에)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 기존 타입들
            ..._selectedTypes.map((type) {
              return Chip(
                label: Text(type),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _selectedTypes.remove(type)),
                backgroundColor: AppColors.white,
                labelStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border),
                ),
              );
            }),
            // + 추가 버튼 (검정 원형)
            GestureDetector(
              onTap: _showAddTypeDialog,
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: AppColors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 타입 추가 다이얼로그
  void _showAddTypeDialog() {
    _typeInputController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('타입 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: _typeInputController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '예: 84A, 59B 등',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onSubmitted: (_) {
            Navigator.pop(ctx);
            _addType();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _addType();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.organizer),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  // 타입 추가 처리
  void _addType() {
    final text = _typeInputController.text.trim();
    if (text.isEmpty) return;
    if (_selectedTypes.contains(text)) {
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

  // 커버 이미지 선택
  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) return;

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

  // 커버 이미지 미리보기
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _coverImageBase64 = null;
                        _coverImageBytes = null;
                      }),
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
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_outlined, size: 40, color: AppColors.textHint),
                  SizedBox(height: 8),
                  Text(
                    '탭하여 커버 이미지 선택',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }
}
