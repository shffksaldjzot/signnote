import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/event_service.dart';
import '../../../services/user_service.dart';

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
      // 첫 번째 행사 자동 선택
      if (_events.isNotEmpty && _selectedEventId == null) {
        _selectedEventId = _events.first['id']?.toString();
      }
    }
    await _loadCustomers();
  }

  // 선택된 행사의 고객 목록 불러오기
  Future<void> _loadCustomers() async {
    if (_selectedEventId == null) {
      setState(() {
        _customers = [];
        _isLoading = false;
      });
      return;
    }

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
                      // 첫 번째 줄: 전체/미선택
                      const DropdownMenuItem<String?>(value: null, child: Text('행사를 선택해주세요', style: TextStyle(color: AppColors.textHint))),
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

          // ── 고객 테이블 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedEventId == null
                    ? const Center(child: Text('행사를 선택해주세요', style: TextStyle(color: AppColors.textHint)))
                    : customers.isEmpty
                        ? const Center(child: Text('참여한 고객이 없습니다', style: TextStyle(color: AppColors.textHint)))
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
                                  columnSpacing: 24,
                                  horizontalMargin: 20,
                                  columns: const [
                                    DataColumn(label: Text('이름', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('전화번호', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('이메일', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('동', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('호', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('타입', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('참여일', style: TextStyle(fontWeight: FontWeight.w600))),
                                    DataColumn(label: Text('관리', style: TextStyle(fontWeight: FontWeight.w600))),
                                  ],
                                  rows: customers.map<DataRow>((p) {
                                    // 플랫 구조/중첩 구조 모두 지원
                                    final name = p['name'] ?? p['user']?['name'] ?? '-';
                                    final phone = p['phone'] ?? p['user']?['phone'] ?? '-';
                                    final email = p['email'] ?? p['user']?['email'] ?? '-';
                                    final joinedAt = p['joinedAt'] != null
                                        ? _dateFormat.format(DateTime.parse(p['joinedAt']))
                                        : '-';
                                    final userId = p['id'] ?? p['user']?['id'] ?? '';
                                    return DataRow(cells: [
                                      DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(Text(phone)),
                                      DataCell(Text(email)),
                                      DataCell(Text(p['dong'] ?? '-')),
                                      DataCell(Text(p['ho'] ?? '-')),
                                      DataCell(Text(p['housingType'] ?? '-')),
                                      DataCell(Text(joinedAt, style: TextStyle(color: AppColors.textSecondary))),
                                      // 관리 버튼 (강제 탈퇴)
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.person_remove_outlined, size: 18, color: Colors.red),
                                        tooltip: '고객 탈퇴',
                                        onPressed: () => _confirmDeleteCustomer(userId, name),
                                      )),
                                    ]);
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
}
