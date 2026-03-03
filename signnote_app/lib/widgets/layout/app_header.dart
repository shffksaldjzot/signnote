import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// AppHeader - 상단 헤더 (네비게이션 바)
//
// 디자인: ← 뒤로가기 버튼 + 가운데 제목
// 예시: "← 창원 자이 사전 박람회"
//
// 사용 예시:
//   AppHeader(title: '창원 자이 사전 박람회')
//   AppHeader(title: '장바구니', showBackButton: false)
// ============================================

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;               // 헤더 제목
  final bool showBackButton;        // 뒤로가기 버튼 표시 여부
  final VoidCallback? onBackPressed; // 뒤로가기 눌렀을 때 (기본: 이전 화면으로)
  final List<Widget>? actions;      // 오른쪽에 넣을 버튼들 (선택사항)

  const AppHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,                           // 그림자 없음
      centerTitle: true,                       // 제목 가운데 정렬
      // 뒤로가기 버튼 (< 모양)
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.chevron_left,
                color: AppColors.textPrimary,
                size: 28,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      automaticallyImplyLeading: false,
      // 가운데 제목
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // 오른쪽 버튼들
      actions: actions,
      // 하단 구분선
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.divider,
          height: 1,
        ),
      ),
    );
  }
}
