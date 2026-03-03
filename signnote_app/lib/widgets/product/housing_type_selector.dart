import 'package:flutter/material.dart';
import '../../config/theme.dart';

// ============================================
// HousingTypeSelector - 주거 타입 선택 위젯
//
// 디자인에서 사용되는 곳:
//   1. 평형 선택 모달 (라디오 버튼 - 하나만 선택)
//      "타입을 선택해 주세요." → 74A / 74B / 84A / 84B
//   2. 품목 추가 폼 (칩 형태 - 여러개 선택 가능)
//      "적용 타입" → [74A] [74B] [84A] [84B]
//   3. 행사 상세 헤더 (뱃지 형태 - 현재 선택된 타입 표시)
//      [84A타입]
//
// 사용 예시:
//   HousingTypeSelector.radio(types: [...], selected: '84B', onSelected: (v) {})
//   HousingTypeSelector.chips(types: [...], selectedTypes: ['74A','84A'], onChanged: (v) {})
//   HousingTypeBadge(type: '84A')
// ============================================

/// 라디오 버튼 형태 (하나만 선택 - 평형 선택 모달용)
class HousingTypeRadio extends StatelessWidget {
  final List<String> types;              // 선택 가능한 타입 목록
  final String? selectedType;            // 현재 선택된 타입
  final ValueChanged<String> onSelected; // 선택했을 때

  const HousingTypeRadio({
    super.key,
    required this.types,
    this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: types.map((type) {
        final isSelected = type == selectedType;
        return InkWell(
          onTap: () => onSelected(type),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                // 라디오 버튼 동그라미
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.primary : AppColors.white,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  // 선택되면 안에 흰 점 표시
                  child: isSelected
                      ? const Center(
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 0,
                            backgroundColor: Colors.transparent,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // 타입 이름
                Text(
                  '$type 타입',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 칩 형태 (여러개 선택 가능 - 품목 추가 폼용)
class HousingTypeChips extends StatelessWidget {
  final List<String> types;                    // 전체 타입 목록
  final List<String> selectedTypes;            // 선택된 타입들
  final ValueChanged<List<String>> onChanged;  // 선택 변경 시

  const HousingTypeChips({
    super.key,
    required this.types,
    required this.selectedTypes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,   // 가로 간격
      children: types.map((type) {
        final isSelected = selectedTypes.contains(type);
        return GestureDetector(
          onTap: () {
            // 선택/해제 토글
            final newList = List<String>.from(selectedTypes);
            if (isSelected) {
              newList.remove(type);
            } else {
              newList.add(type);
            }
            onChanged(newList);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.textPrimary : AppColors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppColors.textPrimary : AppColors.border,
              ),
            ),
            child: Text(
              type,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 뱃지 형태 (현재 선택된 타입 표시 - 행사 상세 헤더용)
class HousingTypeBadge extends StatelessWidget {
  final String type;   // 타입 이름 (예: "84A")

  const HousingTypeBadge({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.textPrimary, width: 1.5),
      ),
      child: Text(
        '$type타입',
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
