import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/value_slide.dart';

/// docs/04_User_Flows.md §2, Экраны 3.1–3.3. Swipe or "Далее" advances;
/// "Пропустить" jumps straight to the auth-choice screen from any slide.
class OnboardingCarouselScreen extends StatefulWidget {
  const OnboardingCarouselScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  State<OnboardingCarouselScreen> createState() =>
      _OnboardingCarouselScreenState();
}

class _OnboardingCarouselScreenState extends State<OnboardingCarouselScreen> {
  static const _slideCount = 3;

  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slideCount - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final slides = [
      ValueSlide(
        icon: Icons.receipt_long_outlined,
        title: l10n.onboardingValue1Title,
        subtitle: l10n.onboardingValue1Subtitle,
      ),
      ValueSlide(
        icon: Icons.calendar_month_outlined,
        title: l10n.onboardingValue2Title,
        subtitle: l10n.onboardingValue2Subtitle,
      ),
      ValueSlide(
        icon: Icons.smart_toy_outlined,
        title: l10n.onboardingValue3Title,
        subtitle: l10n.onboardingValue3Subtitle,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onFinished,
                child: Text(l10n.onboardingSkip),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _page = index),
                children: slides,
              ),
            ),
            _DotsIndicator(count: _slideCount, activeIndex: _page),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page == _slideCount - 1
                        ? l10n.onboardingGetStarted
                        : l10n.onboardingNext,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color:
                isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
