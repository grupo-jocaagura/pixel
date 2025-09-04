import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../app/pixel_config.dart';
import '../../main.dart';
import 'home_page.dart';

/// Splash screen that reacts to the onboarding progress.
///
/// The widget is stateless on purpose; it subscribes to [BlocOnboarding]
/// stream and renders:
/// - a CircularProgressIndicator
/// - a short label with the current step (`i / N · title`)
/// - optional error with Retry/Skip
///
/// Navigation to the next page is triggered when the onboarding completes/skips.
///
/// ### Usage
/// The page assumes:
/// - `BlocOnboarding` is available from `context.appManager.onboarding`.
/// - You configure `onboardingSteps` globally (or per environment).
/// - The initial stack contains [SplashScreenPage.pageModel].
class SplashScreenPage extends StatelessWidget {
  const SplashScreenPage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'splash',
    segments: <String>['splash'],
  );
  static bool _navigated = false;
  @override
  Widget build(BuildContext context) {
    final BlocOnboarding onboarding = context.appManager.onboarding;

    // Kick off onboarding after first frame if still idle.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (onboarding.state.status == OnboardingStatus.idle) {
        onboarding.configure(onboardingSteps);
        onboarding.start();
      }
    });
    debugPrint('CONSTRUYENDO LA PANTALLA DE CARGA');
    return Scaffold(
      body: Center(
        child: StreamBuilder<OnboardingState>(
          stream: onboarding.stateStream,
          initialData: onboarding.state,
          builder: (BuildContext context, AsyncSnapshot<OnboardingState> snap) {
            final OnboardingState s = snap.data ?? onboarding.state;

            // Navigate away when done (completed or skipped).
            if ((s.status == OnboardingStatus.completed ||
                    s.status == OnboardingStatus.skipped) &&
                !_navigated) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.appManager.pageManager.debugLogStack(' BEFORE NAV');
                context.appManager.replaceTopModel(HomePage.pageModel);
                context.appManager.pageManager.debugLogStack('  AFTER NAV');

                context.appManager.replaceTopModel(HomePage.pageModel);
              });
            }

            final OnboardingStep? step = onboarding.currentStep;
            final String line = switch (s.status) {
              OnboardingStatus.idle => 'Preparando inicio…',
              OnboardingStatus.running => _formatRunningLine(s, step),
              OnboardingStatus.completed => '¡Listo!',
              OnboardingStatus.skipped => 'Omitido',
            };

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (step?.description?.isNotEmpty ?? false) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      step!.description!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (s.error != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      // Ajusta si tu ErrorItem expone otro campo (p.ej. title)
                      s.error?.title ?? 'Error',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextButton(
                          onPressed: onboarding.retryOnEnter,
                          child: const Text('Reintentar'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: onboarding.skip,
                          child: const Text('Omitir'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Formats "i/N · Title" while running.
  static String _formatRunningLine(OnboardingState s, OnboardingStep? step) {
    final int current = (s.stepIndex >= 0 ? s.stepIndex : 0) + 1;
    final int total = (s.totalSteps > 0 ? s.totalSteps : 1);
    final String title = (step?.title.isNotEmpty ?? false)
        ? step!.title
        : 'Cargando…';
    return '$current/$total · $title';
  }
}
