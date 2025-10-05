import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../pixel_config.dart';

List<OnboardingStep> buildOnboardingSteps({
  required BlocSession blocSession,
  required AppMode mode,
}) {
  return <OnboardingStep>[
    OnboardingStep(
      title: 'Auth',
      description: 'Verificando sesión previa (silent login)…',
      onEnter: () async {
        return Right<ErrorItem, Unit>(Unit.value);
      },
      autoAdvanceAfter: const Duration(milliseconds: 200),
    ),

    OnboardingStep(
      title: 'Tema',
      description: 'Cargando tema…',
      onEnter: () async => Right<ErrorItem, Unit>(Unit.value),
      autoAdvanceAfter: const Duration(milliseconds: 300),
    ),
    OnboardingStep(
      title: 'Canvas',
      description: 'Preparando canvas…',
      onEnter: () async => Right<ErrorItem, Unit>(Unit.value),
      autoAdvanceAfter: const Duration(milliseconds: 300),
    ),
    OnboardingStep(
      title: 'Inicializando servicios',
      description: 'Iniciando session...',
      onEnter: () async {
        blocSession.logInWithGoogle();
        return Right<ErrorItem, Unit>(Unit.value);
      },
      autoAdvanceAfter: const Duration(milliseconds: 300),
    ),
  ];
}
