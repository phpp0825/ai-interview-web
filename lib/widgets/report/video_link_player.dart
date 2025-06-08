import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;

/// 새 창에서 비디오를 여는 링크 방식 플레이어
class VideoLinkPlayer extends StatelessWidget {
  final String videoUrl;
  final String questionText;
  final int questionNumber;

  const VideoLinkPlayer({
    Key? key,
    required this.videoUrl,
    required this.questionText,
    required this.questionNumber,
  }) : super(key: key);

  void _openVideoInNewTab() {
    if (kIsWeb) {
      html.window.open(videoUrl, '_blank');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 비디오 아이콘
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.play_circle_filled,
              size: 64,
              color: Colors.blue.shade600,
            ),
          ),

          const SizedBox(height: 24),

          // 제목
          Text(
            '질문 $questionNumber 답변 영상',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),

          const SizedBox(height: 8),

          // 질문 내용 (요약)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              questionText.length > 60
                  ? '${questionText.substring(0, 60)}...'
                  : questionText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 24),

          // 새 창에서 열기 버튼
          ElevatedButton.icon(
            onPressed: _openVideoInNewTab,
            icon: const Icon(Icons.open_in_new, size: 20),
            label: const Text(
              '새 창에서 비디오 재생',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
          ),

          const SizedBox(height: 16),

          // 안내 텍스트
          Text(
            'Firebase Storage 보안 정책으로 인해 새 창에서 재생됩니다',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
