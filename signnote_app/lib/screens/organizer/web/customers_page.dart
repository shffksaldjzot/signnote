import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/event_service.dart';

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

  // 검색 필터
  List<dynamic> get _filteredCustomers {
    if (_searchQuery.isEmpty) return _customers;
    final query = _searchQuery.toLowerCase();
    return _customers.where((p) {
      final user = p['user'] as Map<String, dynamic>? ?? {};
      final name = (user['name'] ?? '').toString().toLowerCase();
      final phone = (user['phone'] ?? '').toString().toLowerCase();
      final dong = (p['dong'] ?? '').toString().toLowerCase();
      final ho = (p['ho'] ?? '').toString().toLowerCase();
      return name.contains(query) || phone.contains(query) ||
             dong.contains(query) || ho.contains(query);
    }).toList();
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
                  child: DropdownButtonFormField<String>(
                    value: _selectedEventId,
                    decoration: const InputDecoration(
                      labelText: '행사 선택',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _events.map((e) => DropdownMenuItem(
                      value: e['id']?.toString(),
                      child: Text(e['title'] ?? '', overflow: TextOverflow.ellipsis),
                    )).toList(),
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
                                  ],
                                  rows: customers.map<DataRow>((p) {
                                    final user = p['user'] as Map<String, dynamic>? ?? {};
                                    final joinedAt = p['joinedAt'] != null
                                        ? _dateFormat.format(DateTime.parse(p['joinedAt']))
                                        : '-';
                                    return DataRow(cells: [
                                      DataCell(Text(user['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
                                      DataCell(Text(user['phone'] ?? '-')),
                                      DataCell(Text(user['email'] ?? '-')),
                                      DataCell(Text(p['dong'] ?? '-')),
                                      DataCell(Text(p['ho'] ?? '-')),
                                      DataCell(Text(p['housingType'] ?? '-')),
                                      DataCell(Text(joinedAt, style: TextStyle(color: AppColors.textSecondary))),
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
