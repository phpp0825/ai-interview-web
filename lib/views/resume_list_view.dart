import 'package:flutter/material.dart';
import '../models/resume_model.dart';
import '../services/resume/interfaces/resume_service_interface.dart';
import 'resume_view.dart';
import 'package:get_it/get_it.dart';

/// 이력서 목록 화면
/// 사용자의 모든 이력서를 보여주고 관리할 수 있는 화면입니다
class ResumeListView extends StatefulWidget {
  final Function(ResumeModel)? onResumeSelected;

  const ResumeListView({Key? key, this.onResumeSelected}) : super(key: key);

  @override
  State<ResumeListView> createState() => _ResumeListViewState();
}

class _ResumeListViewState extends State<ResumeListView> {
  // === 서비스 ===
  IResumeService? _resumeService;

  // === 상태 ===
  bool _isLoading = false;
  String? _error;
  List<ResumeModel> _allResumes = [];
  List<ResumeModel> _displayedResumes = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeService();
    _loadResumeList();

    // 검색 기능
    _searchController.addListener(() {
      _applySearch(_searchController.text);
    });
  }

  /// 서비스 초기화
  void _initializeService() {
    try {
      _resumeService = GetIt.instance<IResumeService>();
    } catch (e) {
      setState(() {
        _error = '이력서 서비스 초기화 실패: $e';
      });
    }
  }

  /// 이력서 목록 로드
  Future<void> _loadResumeList() async {
    if (_resumeService == null) {
      setState(() {
        _error = '이력서 서비스가 초기화되지 않았습니다';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 이력서 목록 데이터 가져오기
      final resumeListData = await _resumeService!.getCurrentUserResumeList();

      // ResumeModel 객체로 변환
      _allResumes =
          resumeListData.map((data) => ResumeModel.fromJson(data)).toList();

      // 검색 적용
      _applySearch(_searchController.text);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = '이력서 목록을 불러오는 중 오류가 발생했습니다: $e';
      });
    }
  }

  /// 검색 적용
  void _applySearch(String query) {
    final searchQuery = query.trim().toLowerCase();

    if (searchQuery.isEmpty) {
      _displayedResumes = List.from(_allResumes);
    } else {
      _displayedResumes = _allResumes.where((resume) {
        return resume.position.toLowerCase().contains(searchQuery) ||
            resume.field.toLowerCase().contains(searchQuery) ||
            resume.experience.toLowerCase().contains(searchQuery);
      }).toList();
    }

    if (mounted) setState(() {});
  }

  /// 이력서 삭제 처리
  Future<void> _handleDeleteResume(ResumeModel resume) async {
    final confirmed = await _showDeleteConfirmDialog(resume);
    if (confirmed) {
      try {
        final success = await _resumeService!.deleteResume(resume.resume_id);

        if (success) {
          // 로컬 목록에서도 제거
          _allResumes.removeWhere((r) => r.resume_id == resume.resume_id);
          _applySearch(_searchController.text);

          if (mounted) {
            _showSnackBar('✅ 이력서가 삭제되었습니다');
          }
        } else if (mounted) {
          _showSnackBar('❌ 이력서 삭제에 실패했습니다');
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('❌ 이력서 삭제 중 오류가 발생했습니다: $e');
        }
      }
    }
  }

  /// 삭제 확인 다이얼로그
  Future<bool> _showDeleteConfirmDialog(ResumeModel resume) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('이력서 삭제'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('다음 이력서를 삭제하시겠습니까?'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              resume.position,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              resume.field,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '⚠️ 삭제된 이력서는 복구할 수 없습니다.',
                  style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// 스낵바 표시
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 로딩 중
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    // 오류 발생
    if (_error != null) {
      return _buildErrorScreen();
    }

    // 정상 화면
    return _buildResumeListScreen();
  }

  /// 로딩 화면
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 이력서'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// 오류 화면
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 이력서'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '이력서를 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '알 수 없는 오류가 발생했습니다',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadResumeList,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 메인 이력서 목록 화면
  Widget _buildResumeListScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 이력서'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (context) => const ResumeView()),
              );
              if (result == true) {
                _loadResumeList();
              }
            },
            tooltip: '새 이력서 작성',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            padding: const EdgeInsets.all(24.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 검색 바
                _buildSearchBar(),
                const SizedBox(height: 24),

                // 통계 정보
                _buildStatsBar(),
                const SizedBox(height: 24),

                // 이력서 목록
                _buildResumeList(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const ResumeView()),
          );
          if (result == true) {
            _loadResumeList();
          }
        },
        child: const Icon(Icons.add),
        tooltip: '새 이력서 작성',
      ),
    );
  }

  /// 검색 바
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '이력서 검색...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  /// 통계 정보 바
  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.description, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            '총 ${_displayedResumes.length}개의 이력서',
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_searchController.text.trim().isNotEmpty) ...[
            Text(
              ' (검색 결과)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 이력서 목록
  Widget _buildResumeList() {
    if (_displayedResumes.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children:
          _displayedResumes.map((resume) => _buildResumeCard(resume)).toList(),
    );
  }

  /// 빈 상태
  Widget _buildEmptyState() {
    if (_searchController.text.trim().isNotEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                '검색 결과가 없습니다',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '다른 키워드로 검색해보세요',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined,
                size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              '아직 작성된 이력서가 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 이력서를 작성해보세요!',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (context) => const ResumeView()),
                );
                if (result == true) {
                  _loadResumeList();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('이력서 작성하기'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 이력서 카드
  Widget _buildResumeCard(ResumeModel resume) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (widget.onResumeSelected != null) {
            widget.onResumeSelected!(resume);
          } else {
            // 이력서 상세 정보 표시 (현재는 간단한 스낵바로 표시)
            _showSnackBar('${resume.position} 이력서가 선택되었습니다');
          }
        },
        child: Row(
          children: [
            // 아바타
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.person,
                size: 30,
                color: Colors.deepPurple.shade700,
              ),
            ),
            const SizedBox(width: 20),

            // 이력서 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resume.position,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    resume.field,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.work, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        resume.experience,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Icon(Icons.list, size: 16, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        '${resume.interviewTypes.length}개 면접 유형',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 액션 메뉴
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
              onSelected: (value) async {
                switch (value) {
                  case 'delete':
                    _handleDeleteResume(resume);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('삭제하기', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
