import 'package:flutter/material.dart';
import '../../utils/image_helper.dart';

// ============================================
// 이미지 갤러리 뷰어 (전체화면)
//
// - 전체 화면에 이미지를 꽉 차게 표시
// - 핀치 줌(확대/축소) 지원
// - 여러 장일 경우 좌우 스와이프로 넘기기
// - 하단에 페이지 인디케이터 (1/5 등)
// - 상단에 닫기(X) 버튼
// ============================================

class ImageGalleryScreen extends StatefulWidget {
  final List<String> images;    // 이미지 URL 리스트 (base64 또는 네트워크)
  final int initialIndex;       // 시작 이미지 인덱스

  const ImageGalleryScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 이미지 페이지 뷰 (좌우 스와이프)
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final imageUrl = widget.images[index];
              return Center(
                // InteractiveViewer: 핀치 줌(확대/축소) 지원
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: _buildFullImage(imageUrl),
                ),
              );
            },
          ),
          // 상단: 닫기 버튼
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
          // 하단: 페이지 인디케이터 (여러 장일 때만 표시)
          if (widget.images.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // 숫자 인디케이터 (1 / 5)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 점 인디케이터
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.images.length, (index) {
                      final isActive = index == _currentIndex;
                      return Container(
                        width: isActive ? 8 : 6,
                        height: isActive ? 8 : 6,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? Colors.white : Colors.white38,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // base64 또는 네트워크 이미지를 전체 화면으로 표시
  Widget _buildFullImage(String imageUrl) {
    if (isBase64DataUrl(imageUrl)) {
      final bytes = decodeBase64Image(imageUrl);
      if (bytes != null) {
        return Image.memory(bytes, fit: BoxFit.contain);
      }
      return const Icon(Icons.broken_image, color: Colors.white54, size: 48);
    }
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.broken_image, color: Colors.white54, size: 48),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(color: Colors.white54),
        );
      },
    );
  }
}
