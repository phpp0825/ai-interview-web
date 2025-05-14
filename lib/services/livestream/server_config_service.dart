import 'package:flutter/material.dart';
import '../../controllers/livestream_controller.dart';

/// 서버 연결 설정 관리를 위한 서비스
class ServerConfigService {
  // 미리 정의된 서버 설정
  final Map<String, String> presetServers = {
    'python': 'ws://localhost:8080',
    'nodeJS': 'ws://localhost:3000',
    'custom': '',
  };

  /// 서버 URL 설정 대화상자 표시
  void showServerConfigDialog({
    required BuildContext context,
    required String currentServerUrl,
    required String currentConnectionType,
    required bool autoConnect,
    required bool autoRecord,
    required bool showServerUrl,
    required Function(String, String, bool, bool, bool) onSaveSettings,
  }) {
    final TextEditingController serverUrlController =
        TextEditingController(text: currentServerUrl);
    String connectionType = currentConnectionType;
    bool localAutoConnect = autoConnect;
    bool localAutoRecord = autoRecord;
    bool localShowServerUrl = showServerUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('서버 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 서버 유형 선택
              DropdownButtonFormField<String>(
                value: connectionType,
                decoration: const InputDecoration(
                  labelText: '서버 유형',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'python',
                    child: Text('Python 서버 (${presetServers['python']})'),
                  ),
                  DropdownMenuItem(
                    value: 'nodeJS',
                    child: Text('Node.js 서버 (${presetServers['nodeJS']})'),
                  ),
                  const DropdownMenuItem(
                    value: 'custom',
                    child: Text('커스텀 서버'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      connectionType = value;
                      if (value != 'custom') {
                        serverUrlController.text = presetServers[value] ?? '';
                      }
                    });
                  }
                },
              ),

              const SizedBox(height: 16),

              // 커스텀 URL 입력 필드
              if (connectionType == 'custom')
                TextField(
                  controller: serverUrlController,
                  decoration: const InputDecoration(
                    hintText: 'ws://example.com:8080',
                    labelText: 'WebSocket 서버 URL',
                    border: OutlineInputBorder(),
                  ),
                ),

              const SizedBox(height: 16),

              // 추가 옵션
              Row(
                children: [
                  Checkbox(
                    value: localAutoConnect,
                    onChanged: (value) {
                      setState(() {
                        localAutoConnect = value ?? true;
                      });
                    },
                  ),
                  const Text('자동 연결'),
                  const SizedBox(width: 16),
                  Checkbox(
                    value: localAutoRecord,
                    onChanged: (value) {
                      setState(() {
                        localAutoRecord = value ?? true;
                      });
                    },
                  ),
                  const Text('자동 녹화'),
                ],
              ),

              Row(
                children: [
                  Checkbox(
                    value: localShowServerUrl,
                    onChanged: (value) {
                      setState(() {
                        localShowServerUrl = value ?? true;
                      });
                    },
                  ),
                  const Text('서버 URL 표시'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                String newServerUrl;

                if (connectionType == 'custom') {
                  newServerUrl = serverUrlController.text;
                } else {
                  newServerUrl =
                      presetServers[connectionType] ?? 'ws://localhost:8080';
                }

                onSaveSettings(newServerUrl, connectionType, localAutoConnect,
                    localAutoRecord, localShowServerUrl);

                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  /// 서버 설정 적용
  void applyServerConfig({
    required LivestreamController controller,
    required String newServerUrl,
    required bool autoConnect,
  }) {
    // 연결이 되어 있다면 먼저 해제
    if (controller.isConnected) {
      controller.disconnect();
    }

    // 컨트롤러에 URL 설정
    controller.setServerUrl(newServerUrl);

    // 자동 연결이 활성화되어 있으면 다시 연결
    if (autoConnect) {
      controller.connect();
    }
  }
}
