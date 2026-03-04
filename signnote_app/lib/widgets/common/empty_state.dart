import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// 공통 빈 상태 위젯 (Empty State)
//
// 리스트가 비어있을 때 보여주는 공통 화면.
// 아이콘 + 메인 텍스트 + 보조 텍스트 + 버튼(선택)
// ============================================

class EmptyState extends StatelessWidget {
  final IconData icon;       // 표시할 아이콘
  final String message;      // 메인 텍스트 (예: "장바구니가 비어있습니다")
  final String? subMessage;  // 보조 텍스트 (예: "품목 리스트에서 상품을 담아보세요")
  final String? actionLabel; // 버튼 텍스트 (예: "다시 시도")
  final VoidCallback? onAction; // 버튼 클릭 시 실행

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.subMessage,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
            if (subMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                subMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textHint,
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
