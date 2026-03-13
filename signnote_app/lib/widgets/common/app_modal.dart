import 'dart:ui';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// AppModal - 모달/바텀시트 (아래에서 올라오는 팝업)
//
// 디자인에서 사용되는 곳:
//   - 평형 선택 모달 (74A/74B/84A/84B)
//   - 품목 상세 바텀시트 (이미지 + 정보 + 장바구니 담기)
//   - 참여 코드 입력 팝업
//
// 사용 예시:
//   AppModal.show(context, title: '타입을 선택해 주세요.', child: ...)
//   AppModal.showBottomSheet(context, child: ...)
// ============================================

class AppModal {
  // 가운데 팝업 모달 (평형 선택 등)
  static Future<T?> show<T>(
    BuildContext context, {
    String? title,              // 모달 제목 (선택사항)
    required Widget child,      // 모달 안에 넣을 내용
    bool dismissible = true,    // 바깥 눌러서 닫기 가능 여부
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: dismissible,
      // 반투명 배경 (블러 효과와 함께 사용)
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) {
        // 배경 블러 처리 (유리 느낌)
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            insetPadding: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,  // 내용 크기만큼만
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 (있으면 표시)
                  if (title != null) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // 내용
                  child,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // 아래에서 올라오는 바텀시트 (품목 상세 등)
  static Future<T?> showBottomSheet<T>(
    BuildContext context, {
    required Widget child,      // 바텀시트 안에 넣을 내용
    bool dismissible = true,    // 바깥 눌러서 닫기 가능 여부
    bool showCloseButton = true, // X 닫기 버튼 표시 여부
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: dismissible,
      isScrollControlled: true,   // 내용 크기에 맞게 높이 조절
      backgroundColor: AppColors.white,
      // 반투명 배경 (블러 효과와 함께 사용)
      barrierColor: Colors.black.withValues(alpha: 0.3),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            // 키보드가 올라와도 가리지 않게
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // X 닫기 버튼 (오른쪽 위)
              if (showCloseButton)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 12),
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              // 내용
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// 블러 배경 다이얼로그 표시 (AppModal 밖에서도 간편하게 사용 가능)
Future<T?> showBlurDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showDialog<T>(
    context: context,
    // 반투명 배경
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (context) => BackdropFilter(
      // 배경 블러 처리 (유리 느낌)
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: child,
    ),
  );
}
