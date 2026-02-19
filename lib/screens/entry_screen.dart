import 'package:flutter/material.dart';

/// 进入 App 的落地页，风格与提供的「Search Any Steam Game」图一致
class EntryScreen extends StatelessWidget {
  const EntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 全屏背景图（与首页同一资源）
          Positioned.fill(
            child: Image.asset(
              'assets/home_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // 半透明遮罩保证文字可读
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.35),
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                  const SizedBox(height: 48),
                  // 标题 Search Any Steam Game
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.95)],
                    ).createShader(bounds),
                    child: const Text(
                      'Search Any Steam Game',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 红色条幅 Instant price & discount results
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC54534),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Instant price & discount results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // 免责声明
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Not affiliated with Valve or Steam',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  // 进入按钮
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/main');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF66C0F4),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

