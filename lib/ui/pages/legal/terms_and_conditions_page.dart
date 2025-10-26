import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../../app/env.dart';
import '../../widgets/section_tile_widget.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'terms',
    segments: <String>['terms'],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: InlineTextWidget(
          'Términos y Condiciones ${Env.isProd ? '' : 'QA'}',
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InlineTextWidget('Última actualización: 22 de octubre de 2025'),
            SizedBox(height: 12),
            ParagraphTextWidget(
              'Bienvenido. Esta versión QA está destinada a pruebas internas de la plataforma. '
              'Al usar esta aplicación aceptas estos Términos y Condiciones. '
              'Si no estás de acuerdo, por favor no utilices la aplicación.',
            ),

            SectionTitleWidget('1. Propósito del entorno QA'),
            ParagraphTextWidget(
              'El entorno QA se utiliza exclusivamente para pruebas, validaciones y control de calidad. '
              'Los datos pueden ser restablecidos o eliminados sin previo aviso.',
            ),

            SectionTitleWidget('2. Cuenta y autenticación (Google)'),
            ParagraphTextWidget(
              'Para iniciar sesión usamos Google Sign-In. Durante el flujo de autenticación podemos '
              'recibir tu nombre, correo electrónico y foto de perfil. En QA, además, podemos solicitar '
              'permisos adicionales para validar integraciones (por ejemplo, acceso a Google Sheets/Drive '
              'limitado al alcance de la prueba).',
            ),

            SectionTitleWidget('3. Uso de la información'),
            ParagraphTextWidget(
              'La información recolectada se utiliza únicamente para: '
              'a) permitir el inicio de sesión y personalización básica; '
              'b) validar funcionalidades y flujos de negocio; '
              'c) mejorar la calidad y estabilidad del sistema. '
              'No vendemos ni cedemos tus datos a terceros.',
            ),

            SectionTitleWidget('4. Principio de “Limited Use” de Google'),
            ParagraphTextWidget(
              'Cumplimos el principio de uso limitado: los datos procedentes de APIs de Google se usan '
              'exclusivamente para proporcionar las funcionalidades de la app y no para otros fines no '
              'relacionados, incluyendo publicidad dirigida.',
            ),

            SectionTitleWidget('5. Conservación y eliminación'),
            ParagraphTextWidget(
              'Los datos en QA pueden ser eliminados periódicamente como parte del ciclo de pruebas. '
              'Puedes solicitar la eliminación de tu cuenta y datos de prueba a través del canal de contacto indicado.',
            ),

            SectionTitleWidget('6. Responsabilidad'),
            ParagraphTextWidget(
              'Debido a la naturaleza de QA, la aplicación puede presentar errores, interrupciones o pérdida de datos. '
              'El uso es bajo tu responsabilidad y no asumimos garantías de disponibilidad o continuidad en este entorno.',
            ),

            SectionTitleWidget('7. Cambios a estos términos'),
            ParagraphTextWidget(
              'Podemos actualizar estos Términos y Condiciones en cualquier momento. '
              'Publicaremos la versión vigente en esta misma pantalla, con la fecha de última actualización.',
            ),

            SectionTitleWidget('8. Contacto'),
            ParagraphTextWidget(
              'Si tienes preguntas o deseas ejercer tus derechos de acceso o eliminación en QA, '
              'escríbenos a: soporte@pragma.com.co (asunto: QA – Términos y Datos).',
            ),

            SizedBox(height: 24),
            ParagraphTextWidget(
              'Al continuar, confirmas que has leído y aceptas estos Términos y Condiciones del entorno QA.',
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
