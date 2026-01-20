import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  final _storage = const FlutterSecureStorage();
  static const _onboardingKey = 'onboarding_completed';
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      image: 'assets/images/onboarding_1.png',
      title: 'Tambah Lokasi Bambu',
      description:
          'Tandai lokasi bambu di peta dengan koordinat GPS dan ambil foto untuk dokumentasi',
    ),
    OnboardingContent(
      image: 'assets/images/onboarding_2.png',
      title: 'Jelajahi Peta Anda',
      description:
          'Lihat semua lokasi bambu yang tercatat di peta interaktif dengan informasi dan gambar lengkap',
    ),
    OnboardingContent(
      image: 'assets/images/onboarding_3.png',
      title: 'Perbarui Kapan Saja',
      description:
          'Edit data bambu, perbarui foto, atau sesuaikan koordinat lokasi saat ada informasi baru',
    ),
    OnboardingContent(
      image: 'assets/images/onboarding_4.png',
      title: 'Kelola & Ekspor',
      description:
          'Hapus data yang sudah tidak relevan dan ekspor data bambu ke Excel untuk laporan dan analisis',
    ),
  ];

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Future<void> _goToNextPage() async {
    if (_currentPage < _contents.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page - save completion and navigate to welcome
      await _storage.write(key: _onboardingKey, value: 'true');
      if (mounted) {
        context.go('/welcome');
      }
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFBFB),
      body: SafeArea(
        child: Column(
          children: [
            // PageView content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  return _buildPage(_contents[index]);
                },
              ),
            ),
            // Page indicator
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _PageIndicator(
                currentPage: _currentPage,
                pageCount: _contents.length,
              ),
            ),
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  _currentPage > 0
                      ? TextButton(
                          onPressed: _goToPreviousPage,
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF491B6D),
                            ),
                          ),
                        )
                      : const SizedBox(width: 80),
                  // Next/Start button
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _goToNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF62A148),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _contents.length - 1
                            ? 'Mulai'
                            : 'Lanjut',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingContent content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          // Image
          Image.asset(
            content.image,
            height: 250,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),
          // Title
          Text(
            content.title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212529),
              letterSpacing: -0.48,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              content.description,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.normal,
                color: Color(0xFF212529),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const _PageIndicator({
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 80 : 15,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFCED4DA) : Colors.transparent,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(
              color: const Color(0xFFCED4DA),
              width: isActive ? 1 : 1.5,
            ),
          ),
        );
      }),
    );
  }
}

class OnboardingContent {
  final String image;
  final String title;
  final String description;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}
