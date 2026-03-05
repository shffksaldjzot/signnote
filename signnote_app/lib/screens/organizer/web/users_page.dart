import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../services/user_service.dart';
import '../../../services/api_service.dart';

// ============================================
// 사용자 관리 페이지 (Users Page)
//
// 구조:
// ┌─ 역할 탭 ──────────────────────────────────┐
// | [전체]  [고객]  [업체]  [주관사]              |
// └────────────────────────────────────────────┘
//
// ┌─ 사용자 테이블 ─────────────────────────────┐
// | 이름 | 이메일 | 전화번호 | 역할 | 승인 | 가입일 | 관리 |
// └────────────────────────────────────────────┘
//
// 기능:
//   - 관리자: 주관사+협력업체 전체 열람, 승인/거부 가능
//   - 주관사: 협력업체 정보만 열람 가능
//   - 사용자 상세보기 (사업자등록번호, 사업자등록증 이미지 등)
// ============================================

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final UserService _userService = UserService();

  bool _isLoading = true;
  List<dynamic> _users = [];          // 사용자 목록
  String? _selectedRole;              // 선택된 역할 필터
  String _searchQuery = '';           // 검색어
  String _currentUserRole = '';       // 현재 로그인한 사용자의 역할

  // 날짜 포맷
  final _dateFormat = DateFormat('yyyy-MM-dd');

  // 역할별 한글 이름
  static const _roleNames = {
    'CUSTOMER': '고객',
    'VENDOR': '업체',
    'ORGANIZER': '주관사',
    'ADMIN': '관리자',
  };

  // 역할별 색상
  static const _roleColors = {
    'CUSTOMER': Colors.blue,
    'VENDOR': Colors.orange,
    'ORGANIZER': Colors.green,
    'ADMIN': Colors.red,
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserRole();
    _loadUsers();
  }

  // 현재 로그인한 사용자의 역할 확인
  Future<void> _loadCurrentUserRole() async {
    final userInfo = await ApiService().getUserInfo();
    if (userInfo != null && mounted) {
      setState(() {
        _currentUserRole = userInfo['role'] ?? '';
      });
    }
  }

  // 관리자인지 확인
  bool get _isAdmin => _currentUserRole == 'ADMIN';

  // 사용자 목록 불러오기
  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    final result = await _userService.getUsers(role: _selectedRole);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _users = result['users'] ?? [];
        }
      });
    }
  }

  // 검색어로 필터링된 사용자 목록
  List<dynamic> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final query = _searchQuery.toLowerCase();
    return _users.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final phone = (u['phone'] ?? '').toString().toLowerCase();
      return name.contains(query) || email.contains(query) || phone.contains(query);
    }).toList();
  }

  // ---- 사용자 승인 처리 ----
  Future<void> _approveUser(dynamic user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 승인'),
        content: Text('${user['name']}의 가입을 승인하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('승인'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _userService.approveUser(user['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user['name']}이(가) 승인되었습니다')),
      );
      _loadUsers(); // 목록 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '승인 처리에 실패했습니다')),
      );
    }
  }

  // ---- 사용자 거부 처리 ----
  Future<void> _rejectUser(dynamic user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가입 거부'),
        content: Text(
          '${user['name']}의 가입을 거부하시겠습니까?\n\n'
          '거부하면 해당 계정이 삭제됩니다.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('거부'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _userService.rejectUser(user['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user['name']}의 가입이 거부되었습니다')),
      );
      _loadUsers(); // 목록 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '거부 처리에 실패했습니다')),
      );
    }
  }

  // ---- 회원 강제 탈퇴 (관리자 전용) ----
  Future<void> _deleteUser(dynamic user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: Text(
          '${user['name']}을(를) 강제 탈퇴시키겠습니까?\n\n'
          '탈퇴하면 해당 사용자의 모든 데이터가 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _userService.deleteUser(user['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user['name']}이(가) 탈퇴 처리되었습니다')),
      );
      _loadUsers(); // 목록 새로고침
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '탈퇴 처리에 실패했습니다')),
      );
    }
  }

  // ---- 비밀번호 초기화 (관리자 전용) ----
  Future<void> _resetUserPassword(dynamic user) async {
    // 확인 다이얼로그
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 초기화'),
        content: Text('${user['name']}의 비밀번호를 무작위로 초기화하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text('초기화'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _userService.resetPassword(user['id']);
    if (!mounted) return;

    if (result['success'] == true) {
      // 새 비밀번호를 보여주는 다이얼로그
      final newPassword = result['newPassword'] ?? '';
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('비밀번호 초기화 완료'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user['name']}의 새 비밀번호:'),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SelectableText(
                  newPassword,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '이 비밀번호를 해당 사용자에게 전달해 주세요.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? '비밀번호 초기화에 실패했습니다')),
      );
    }
  }

  // ---- 사용자 상세 보기 다이얼로그 ----
  void _showUserDetail(dynamic user) {
    final role = user['role'] ?? 'CUSTOMER';
    final roleName = _roleNames[role] ?? role;
    final isApproved = user['isApproved'] ?? true;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Row(
                children: [
                  const Text('사용자 상세 정보',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // 기본 정보
              _buildDetailRow('이름/업체명', user['name'] ?? '-'),
              _buildDetailRow('이메일', user['email'] ?? '-'),
              _buildDetailRow('전화번호', user['phone'] ?? '-'),
              _buildDetailRow('역할', roleName),
              _buildDetailRow('승인 상태', isApproved ? '승인됨' : '대기중',
                  valueColor: isApproved ? Colors.green : Colors.orange),

              // 사업자 정보 (업체/주관사만)
              if (role == 'VENDOR' || role == 'ORGANIZER') ...[
                const SizedBox(height: 8),
                const Divider(),
                const SizedBox(height: 8),
                _buildDetailRow('사업자등록번호', user['businessNumber'] ?? '미등록'),

                // 사업자등록증 이미지
                const SizedBox(height: 12),
                const Text('사업자등록증',
                    style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                if (user['businessLicenseImage'] != null)
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        user['businessLicenseImage'],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('이미지를 불러올 수 없습니다', style: TextStyle(color: Colors.grey)),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Text('사업자등록증 미첨부', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
              ],

              // 가입일
              const SizedBox(height: 8),
              _buildDetailRow('가입일',
                  user['createdAt'] != null
                      ? _dateFormat.format(DateTime.parse(user['createdAt']))
                      : '-'),

              // 관리자 전용 버튼들
              if (_isAdmin) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // 회원 강제 탈퇴 버튼 (관리자 전용)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _deleteUser(user);
                      },
                      icon: const Icon(Icons.person_remove, size: 18),
                      label: const Text('회원 탈퇴'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                    // 비밀번호 초기화 버튼 (관리자 전용)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetUserPassword(user);
                      },
                      icon: const Icon(Icons.lock_reset, size: 18),
                      label: const Text('비밀번호 초기화'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                    // 미승인 사용자만 승인/거부 버튼 표시
                    if (!isApproved) ...[
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _rejectUser(user);
                        },
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        child: const Text('거부'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveUser(user);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: const Text('승인', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 상세 정보 행 위젯
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: valueColor ?? Colors.black87,
                )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 페이지 제목 ──
          const Text(
            '사용자 관리',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '전체 ${_filteredUsers.length}명',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 20),

          // ── 필터 바 (역할 탭 + 검색) ──
          _buildFilterBar(),
          const SizedBox(height: 16),

          // ── 사용자 테이블 ──
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? const Center(child: Text('등록된 사용자가 없습니다'))
                    : _buildUserTable(),
          ),
        ],
      ),
    );
  }

  // 필터 바 위젯
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          // 역할 필터 탭
          // 주관사는 업체 탭만 표시, 관리자는 전체 표시
          if (_isAdmin) ...[
            _buildRoleTab(null, '전체'),
            const SizedBox(width: 8),
            _buildRoleTab('CUSTOMER', '고객'),
            const SizedBox(width: 8),
          ],
          _buildRoleTab('VENDOR', '업체'),
          if (_isAdmin) ...[
            const SizedBox(width: 8),
            _buildRoleTab('ORGANIZER', '주관사'),
          ],

          const Spacer(),

          // 검색어 입력
          SizedBox(
            width: 280,
            child: TextField(
              decoration: const InputDecoration(
                hintText: '이름, 이메일, 전화번호로 검색',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  // 역할 탭 버튼
  Widget _buildRoleTab(String? role, String label) {
    final isSelected = _selectedRole == role;
    return InkWell(
      onTap: () {
        setState(() => _selectedRole = role);
        _loadUsers();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // 사용자 테이블 위젯
  Widget _buildUserTable() {
    final users = _filteredUsers;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4),
        ],
      ),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Colors.grey[50]),
          columnSpacing: 24,
          columns: [
            const DataColumn(label: Text('이름/업체명', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('이메일', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('전화번호', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('역할', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('승인', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('가입일', style: TextStyle(fontWeight: FontWeight.bold))),
            const DataColumn(label: Text('관리', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: users.map<DataRow>((u) {
            final role = u['role'] ?? 'CUSTOMER';
            final roleName = _roleNames[role] ?? role;
            final roleColor = _roleColors[role] ?? Colors.grey;
            final isApproved = u['isApproved'] ?? true;
            final createdAt = u['createdAt'] != null
                ? _dateFormat.format(DateTime.parse(u['createdAt']))
                : '-';

            return DataRow(cells: [
              DataCell(Text(u['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.w500))),
              DataCell(Text(u['email'] ?? '-')),
              DataCell(Text(u['phone'] ?? '-')),
              DataCell(_buildRoleBadge(roleName, roleColor)),
              // 승인 상태 표시
              DataCell(_buildApprovalBadge(isApproved)),
              DataCell(Text(createdAt, style: TextStyle(color: Colors.grey[600]))),
              // 관리 버튼 (상세보기 + 승인/거부)
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 상세보기 버튼
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 20),
                    tooltip: '상세보기',
                    onPressed: () => _showUserDetail(u),
                  ),
                  // 승인 버튼 (관리자 + 미승인 사용자만)
                  if (_isAdmin && !isApproved) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                      tooltip: '승인',
                      onPressed: () => _approveUser(u),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, size: 20, color: Colors.red),
                      tooltip: '거부',
                      onPressed: () => _rejectUser(u),
                    ),
                  ],
                ],
              )),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // 역할 뱃지 위젯
  Widget _buildRoleBadge(String roleName, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        roleName,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 승인 상태 뱃지
  Widget _buildApprovalBadge(bool isApproved) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isApproved
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isApproved ? '승인' : '대기',
        style: TextStyle(
          color: isApproved ? Colors.green : Colors.orange,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
