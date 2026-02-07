import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _isNotificationsEnabled = true;
  bool _isRemindersEnabled = true;
  bool _isBioAuthEnabled = false;

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? LogBTheme.slate900
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '로그아웃',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: const Text('앱에서 로그아웃 하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: LogBTheme.slate500),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text(
              '로그아웃',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? LogBTheme.slate950 : LogBTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            backgroundColor: isDark ? LogBTheme.slate950 : LogBTheme.bgLight,
            elevation: 0,
            title: Text(
              '설정',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                fontFamily: 'Pretendard',
                color: isDark ? Colors.white : LogBTheme.slate900,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildProfileCard(isDark),
                  const SizedBox(height: 30),

                  _buildSectionHeader('앱 설정'),
                  _buildSettingTile(
                    icon: Icons.dark_mode,
                    title: '테크 모드 (준비 중)',
                    subtitle: '앱의 테마를 변경합니다',
                    trailing: Switch(
                      value: isDark,
                      onChanged: (v) {
                        // Theme state management implementation needed
                      },
                      activeColor: LogBTheme.emerald600,
                    ),
                  ),
                  _buildSettingTile(
                    icon: Icons.notifications_active,
                    title: '알림 설정',
                    subtitle: '주요 업데이트 및 공지사항 알림',
                    trailing: Switch(
                      value: _isNotificationsEnabled,
                      onChanged: (v) =>
                          setState(() => _isNotificationsEnabled = v),
                      activeColor: LogBTheme.emerald600,
                    ),
                  ),
                  _buildSettingTile(
                    icon: Icons.timer,
                    title: '미팅 리마인더',
                    subtitle: '회의 10분 전 알림을 보냅니다',
                    trailing: Switch(
                      value: _isRemindersEnabled,
                      onChanged: (v) => setState(() => _isRemindersEnabled = v),
                      activeColor: LogBTheme.emerald600,
                    ),
                  ),

                  const SizedBox(height: 30),
                  _buildSectionHeader('보안 및 계정'),
                  _buildSettingTile(
                    icon: Icons.fingerprint,
                    title: '생체 인식 보안',
                    subtitle: 'Face ID / 지문 인식 사용',
                    trailing: Switch(
                      value: _isBioAuthEnabled,
                      onChanged: (v) => setState(() => _isBioAuthEnabled = v),
                      activeColor: LogBTheme.emerald600,
                    ),
                  ),
                  _buildSettingActionTile(
                    icon: Icons.lock_reset,
                    title: '비밀번호 변경',
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),
                  _buildSectionHeader('데이터 관리'),
                  _buildSettingActionTile(
                    icon: Icons.download,
                    title: '전체 데이터 내보내기 (CSV)',
                    onTap: () {},
                  ),
                  _buildSettingActionTile(
                    icon: Icons.cloud_done,
                    title: '클라우드 동기화 확인',
                    onTap: () {},
                  ),

                  const SizedBox(height: 30),
                  _buildSectionHeader('고객 지원'),
                  _buildSettingActionTile(
                    icon: Icons.help_outline,
                    title: '이용 가이드',
                    onTap: () {},
                  ),
                  _buildSettingActionTile(
                    icon: Icons.feedback_outlined,
                    title: '의견 보내기',
                    onTap: () {},
                  ),
                  _buildSettingActionTile(
                    icon: Icons.info_outline,
                    title: '서비스 이용약관',
                    onTap: () {},
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'Log,B v1.0.0 Stable Gold',
                      style: TextStyle(
                        color: LogBTheme.slate500,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: LogBTheme.emerald600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? LogBTheme.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: LogBTheme.greenGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 35),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? '사용자님',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  user?.email ?? '로그인이 필요합니다',
                  style: TextStyle(color: LogBTheme.slate500, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: '로그아웃',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? LogBTheme.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: LogBTheme.emerald600),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: LogBTheme.slate500, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _buildSettingActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? LogBTheme.slate900 : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: LogBTheme.emerald600),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: LogBTheme.slate500,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
