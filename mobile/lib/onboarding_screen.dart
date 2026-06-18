import 'package:flutter/material.dart';
import 'package:poketto/ui/app_theme.dart';
import 'package:poketto/ui/poketto_light_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('poketto_onboarding_completed', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _onNextPressed() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (_currentPage > 0) {
          _pageController.animateToPage(
            _currentPage - 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
          return false;
        }
        return true;
      },
      child: PokettoGradientScaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Positioned(
                right: -90,
                top: -100,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(isDark ? .08 : .09),
                  ),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                        PokettoSpacing.xl, 8, PokettoSpacing.md, 0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(.72),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: context.poketto.border),
                          ),
                          child: const Text(
                            'POKETTO',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                        ),
                        const Spacer(),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _currentPage < 2 ? 1 : 0,
                          child: TextButton(
                            onPressed:
                                _currentPage < 2 ? _completeOnboarding : null,
                            child: const Text('Lewati'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: const [
                        OnboardingSlide(
                          index: 0,
                          imagePath: 'assets/cat_coins.png',
                          title: 'Catat tanpa ribet',
                          subtitle:
                              'Pemasukan dan pengeluaran tersimpan rapi, lengkap dengan kategori, waktu, dan lokasi.',
                        ),
                        OnboardingSlide(
                          index: 1,
                          imagePath: 'assets/cat_pixel.png',
                          title: 'Budget tetap terkendali',
                          subtitle:
                              'Pantau batas harian dan bulanan, lalu dapatkan peringatan sebelum pengeluaran kelewat jauh.',
                        ),
                        OnboardingSlide(
                          index: 2,
                          imagePath: 'assets/cat_shops.png',
                          title: 'Pahami pola uangmu',
                          subtitle:
                              'Ringkasan, komposisi, dan tren membantu kamu mengambil keputusan finansial dengan lebih tenang.',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PokettoSpacing.xl,
                      PokettoSpacing.sm,
                      PokettoSpacing.xl,
                      PokettoSpacing.xxl,
                    ),
                    child: Row(
                      children: [
                        Row(
                          children: List.generate(3, (index) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 280),
                              margin: const EdgeInsets.only(right: 7),
                              height: 7,
                              width: _currentPage == index ? 28 : 7,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                color: _currentPage == index
                                    ? Theme.of(context).colorScheme.primary
                                    : context.poketto.border,
                              ),
                            );
                          }),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _onNextPressed,
                          icon: Icon(_currentPage == 2
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded),
                          label: Text(_currentPage == 2 ? 'Mulai' : 'Lanjut'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(132, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(PokettoRadius.medium),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingSlide extends StatelessWidget {
  final int index;
  final String imagePath;
  final String title;
  final String subtitle;

  const OnboardingSlide({
    super.key,
    required this.index,
    required this.imagePath,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: PokettoSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                constraints: const BoxConstraints(maxWidth: 340),
                height: constraints.maxHeight < 520 ? 210 : 270,
                padding: const EdgeInsets.all(PokettoSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? const [Color(0xFF29211C), Color(0xFF171310)]
                        : const [Color(0xFFFFF8F1), Color(0xFFFFE4D0)],
                  ),
                  borderRadius: BorderRadius.circular(PokettoRadius.extraLarge),
                  border: Border.all(color: context.poketto.border),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(.12),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Image.asset(imagePath, fit: BoxFit.contain),
              ),
              const SizedBox(height: PokettoSpacing.xxl),
              Text(
                '0${index + 1} / 03',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: PokettoSpacing.sm),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.hero.copyWith(
                  fontSize: constraints.maxHeight < 520 ? 27 : 31,
                  color: isDark ? Colors.white : AppColors.text,
                ),
              ),
              const SizedBox(height: PokettoSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: isDark ? Colors.white60 : AppColors.mutedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
