import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:poketto/ui/app_theme.dart';

class PokettoAuthShell extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget form;
  final Widget? footer;
  final bool showBackButton;

  const PokettoAuthShell({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.form,
    this.footer,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPadding = keyboardInset > 0 ? 12.0 : 28.0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const Positioned.fill(child: _AuthBackground()),
          SafeArea(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(
                PokettoSpacing.xl,
                topPadding,
                PokettoSpacing.xl,
                keyboardInset + PokettoSpacing.xxl,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      MediaQuery.paddingOf(context).vertical -
                      topPadding -
                      PokettoSpacing.xxl,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        if (showBackButton)
                          IconButton.filledTonal(
                            onPressed: () => Navigator.maybePop(context),
                            icon: const Icon(Icons.arrow_back_rounded),
                          )
                        else
                          const SizedBox(width: 48),
                        const Spacer(),
                        const _BrandMark(),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                    SizedBox(height: keyboardInset > 0 ? 12 : 22),
                    Text(
                      eyebrow.toUpperCase(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.hero.copyWith(
                        fontSize: 30,
                        color: isDark ? Colors.white : AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 330),
                      child: Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: isDark ? Colors.white60 : AppColors.mutedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(PokettoRadius.extraLarge),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 430),
                          padding: const EdgeInsets.all(PokettoSpacing.xl),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF191512).withOpacity(.84)
                                : Colors.white.withOpacity(.78),
                            borderRadius:
                                BorderRadius.circular(PokettoRadius.extraLarge),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withOpacity(.08)
                                  : Colors.white.withOpacity(.9),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withOpacity(.28)
                                    : const Color(0xFFB95512).withOpacity(.10),
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: form,
                        ),
                      ),
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: 14),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withOpacity(.75),
          shape: BoxShape.circle,
          border: Border.all(color: context.poketto.border),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Image(
          image: AssetImage('assets/cat_pixel.png'),
          fit: BoxFit.contain,
        ),
      );
}

class _AuthBackground extends StatelessWidget {
  const _AuthBackground();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [
                  Color(0xFF201A16),
                  Color(0xFF100E0C),
                  Color(0xFF090807),
                ]
              : const [
                  Color(0xFFFFFBF7),
                  Color(0xFFFFF0E4),
                  Color(0xFFFFDCC6),
                ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: _Glow(
              size: 250,
              color: const Color(0xFFFF8A3D).withOpacity(dark ? .14 : .20),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: _Glow(
              size: 300,
              color: const Color(0xFFFFC08A).withOpacity(dark ? .07 : .20),
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withOpacity(0)]),
        ),
      );
}
