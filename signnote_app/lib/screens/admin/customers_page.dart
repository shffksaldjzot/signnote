import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/event_service.dart';
import '../../services/user_service.dart';
import '../../utils/number_formatter.dart';
import '../../utils/csv_download.dart';

// ============================================
// 고객 관리 페이지 (Customers Page)
//
// 행사별 고객 리스팅 (행사 드롭다운으로 필터링)
// ============================================

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final EventService _eventService = EventService();
  final UserService _userService = UserService();
  final _dateFormat = DateFormat('yyyy-MM-dd');

  bool _isLoading = true;
  List<dynamic> _events = [];
  List<dynamic> _customers = [];
  String? _selectedEventId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // 행사 목록 불러오기
  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    final result = await _eventService.getEvents();
    if (result['success'] == true) {
      _events = result['events'] as List? ?? [];
    }
    // 기본값: 전체 (null) → 모든 고객 표시
    await _loadCustomers();
  }

  // 고객 목록 불러오기 (행사 선택 없으면 전체 고객)
  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);

    if (_selectedEventId == null) {
      // 전체 고객 조회 (행사 무관)
      final result = await _userService.getUsers(role: 'CUSTOMER');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            // 응답이 배열인 경우 직접 사용, 아니면 users 키에서 추출
            final data = result['users'];
            if (data is List) {
              _customers = data;
            } else {
              _customers = [];
            }
          } else {
            _customers = [];
          }
        });
      }
    } else {
      // 특정 행사의 고객만 조회
      final result = await _eventService.getParticipants(_selectedEventId!, role: 'CUSTOMER');
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (result['success'] == true) {
            _customers = result['participants'] as List? ?? [];
          }
        });
      }
    }
  }

  // 검색 필터 (서버 응답이 플랫 구조: name, phone이 직접 참여자 객체에 있음)
  List<dynamic> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((p) {
      // 플랫 구조 (서버가 user 풀어서 반환) 또는 중첩 구조 (user 포함) 모두 지원
      final name = (p['name'] ?? p['user']?['name'] ?? '').toString().toLowerCase();
      final phone = (p['phone'] ?? p['user']?['phone'] ?? '').toString().toLowerCase();
      final dong = (p['dong'] ?? '').toString().toLowerCase();
      final ho = (p['ho'] ?? '').toString().toLowerCase();
      return name.contains(query) || phone.contains(query) ||
             dong.contains(query) || ho.contains(query);
    }).toList();
  }

  // 고객 강제 탈퇴 확인 다이얼로그
  void _confirmDeleteCustomer(String userId, String name) {
    if (userId.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('고객 탈퇴'),
        content: Text('$name 고객을 탈퇴시키겠습니까?\n\n탈퇴하면 관련 데이터가 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _userService.deleteUser(userId);
              if (!mounted) return;
              if (result['success'] == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$name 고객이 탈퇴 처리되었습니다')),
                );
                _loadCustomers();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['error'] ?? '탈퇴 처리에 실패했습니다')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filteredCustomers;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 제목 ──
          const Text('고객 관리', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            '전체 ${customers.length}명',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // ── 필터 바 (행사 드롭다운 + 검색) ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
            ),
            child: Row(
              children: [
                // 행사 드롭다운
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _selectedEventId,
                    decoration: const InputDecoration(
                      labelText: '행사 선택',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      // 첫 번째 줄: 전체 고객
                      const DropdownMenuItem<String?>(value: null, child: Text('전체', style: TextStyle(fontWeight: FontWeight.w500))),
                      ..._events.map((e) => DropdownMenuItem<String?>(
                        value: e['id']?.toString(),
                        child: Text(e['title'] ?? '', overflow: TextOverflow.ellipsis),
                      )),
                    ],
                    onChanged: (value) {
                      _selectedEventId = value;
                      _loadCustomers();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // 검색
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: '이름, 전화번호, 동호수로 검색',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // B-26: 전체 선택 시 동/호수 빈칸 안내
          if (_selectedEventId == null && customers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('행사를 선택하면 동/호수/타입 정보가 표시됩니다', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const Spacer(),
                    // B-25: 엑셀 다운로드
                    TextButton.icon(
                      onPressed: customers.isEmpty ? null : () => _downloadCustomerExcel(customers),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('엑셀', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          if (_selectedEventId != null && customers.isNotEmpty)
            // B-25: 행사 선택 시에도 엑셀 버튼
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _downloadCustomerExcel(customers),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('엑셀 다운로드', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ),
            ),

          // ── 고객 테이블 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_outline, size: 48, color: AppColors.textHint),
                                const SizedBox(height: 12),
                                const Text('참여한 고객이 없습니다', style: TextStyle(color: AppColors.textHint)),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                            ),
                            child: SingleChildScrollView(
                              child: SizedBox(
                                width: double.infinity,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(AppColors.background),
                                  dataRowMinHeight: 56,
                                  dataRowMaxHeight: 64,
                                  columnSpacing: 20,
                                  horizontalMargin: 20,
                                  columns: const [
                                    DataColumn(label: Text('이름', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('전화번호', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('이메일', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('행사명', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('동', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('호', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('타입', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('참여일', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('관리', style: TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                  rows: customers.map<DataRow>((p) {
                                    final name = p['name'] ?? p['user']?['name'] ?? '-';
                                    final phone = p['phone'] ?? p['user']?['phone'] ?? '-';
                                    final email = p['email'] ?? p['user']?['email'] ?? '-';
                                    final eventTitle = p['eventTitle'] ?? '-';
                                    final joinedAt = p['joinedAt'] != null
                                        ? _dateFormat.format(DateTime.parse(p['joinedAt']))
                                        : '-';
                                    final userId = p['id'] ?? p['user']?['id'] ?? '';
                                    return DataRow(
                                      // B-24: 고객 클릭 → 상세 팝업
                                      onSelectChanged: (_) => _showCustomerDetail(p),
                                      cells: [
                                        DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                        // B-37: 전화번호 하이픈
                                        DataCell(Text(formatPhone(phone?.toString()))),
                                        DataCell(Text(email, style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(eventTitle, style: const TextStyle(fontSize: 13))),
                                        DataCell(Text(p['dong'] ?? '-')),
                                        DataCell(Text(p['ho'] ?? '-')),
                                        DataCell(Text(p['housingType'] ?? '-')),
                                        DataCell(Text(joinedAt, style: const TextStyle(color: AppColors.textSecondary))),
                                        DataCell(IconButton(
                                          icon: const Icon(Icons.person_remove_outlined, size: 18, color: Colors.red),
                                          tooltip: '고객 탈퇴',
                                          onPressed: () => _confirmDeleteCustomer(userId.toString(), name),
                                        )),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // B-24: 고객 상세 팝업
  void _showCustomerDetail(dynamic customer) {
    final name = customer['name'] ?? customer['user']?['name'] ?? '-';
    final phone = customer['phone'] ?? customer['user']?['phone'] ?? '-';
    final email = customer['email'] ?? customer['user']?['email'] ?? '-';
    final dong = customer['dong'] ?? '-';
    final ho = customer['ho'] ?? '-';
    final housingType = customer['housingType'] ?? '-';
    final eventTitle = customer['eventTitle'] ?? '-';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                children: [
                  const Text('고객 상세 정보', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              _detailRow('이름', name),
              _detailRow('전화번호', formatPhone(phone?.toString())),
              _detailRow('이메일', email),
              _detailRow('행사', eventTitle),
              _detailRow('동/호수', '$dong동 $ho호'),
              _detailRow('타입', housingType),
              if (customer['joinedAt'] != null)
                _detailRow('참여일', _dateFormat.format(DateTime.parse(customer['joinedAt']))),
            ],
          ),
        ),
      ),
    );
  }

  // 상세 행
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // B-25: 고객 엑셀 다운로드
  void _downloadCustomerExcel(List<dynamic> customers) {
    final headers = ['이름', '전화번호', '이메일', '행사명', '동', '호수', '타입'];
    final dataRows = customers.map<List<String>>((p) => [
      p['name'] ?? p['user']?['name'] ?? '-',
      p['phone'] ?? p['user']?['phone'] ?? '-',
      p['email'] ?? p['user']?['email'] ?? '-',
      p['eventTitle'] ?? '-',
      p['dong'] ?? '-',
      p['ho'] ?? '-',
      p['housingType'] ?? '-',
    ]).toList();

    final eventName = _selectedEventId != null
        ? _events.firstWhere((e) => e['id']?.toString() == _selectedEventId, orElse: () => {})['title'] ?? '전체'
        : '전체';

    downloadExcel(
      title: '고객 리스트 ($eventName)',
      subtitle: '작성: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      headers: headers,
      dataRows: dataRows,
      fileName: '고객리스트_$eventName.xlsx',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${customers.length}명 고객 리스트 다운로드 완료')),
    );
  }
}
