import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../widgets/section_tile_widget.dart';

class TermsAndConditionsProdPage extends StatelessWidget {
  const TermsAndConditionsProdPage({super.key});

  static const PageModel pageModel = PageModel(
    name: 'terms',
    segments: <String>['terms'],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const InlineTextWidget('Términos y Condiciones')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InlineTextWidget('Última actualización: 26 de octubre de 2025'),
            SizedBox(height: 12),
            ParagraphTextWidget(
              'Bienvenido. Al utilizar esta aplicación, aceptas los presentes Términos y Condiciones, '
              'que regulan el acceso y uso de los servicios ofrecidos. '
              'Si no estás de acuerdo con ellos, por favor no utilices la aplicación.',
            ),

            SectionTitleWidget('1. Uso de la aplicación'),
            ParagraphTextWidget(
              'Esta aplicación permite a los usuarios autenticarse mediante servicios de Google '
              'para acceder a funcionalidades personalizadas. '
              'El uso debe realizarse de manera responsable y conforme a las leyes aplicables.',
            ),

            SectionTitleWidget('2. Autenticación con Google'),
            ParagraphTextWidget(
              'La aplicación utiliza Google Sign-In como método de autenticación. '
              'Durante este proceso se pueden obtener datos básicos de tu perfil de Google '
              'como nombre, dirección de correo electrónico y foto de perfil. '
              'Estos datos se emplean exclusivamente para identificarte dentro de la aplicación '
              'y ofrecerte una experiencia personalizada.',
            ),

            SectionTitleWidget(
              '3. Principio de uso limitado (“Limited Use Policy”)',
            ),
            ParagraphTextWidget(
              'Cumplimos la política de uso limitado de datos de Google: '
              'la información obtenida mediante APIs de Google se utiliza únicamente '
              'para proporcionar y mejorar las funcionalidades del servicio, '
              'sin vender, compartir o transferir dicha información a terceros '
              'para fines ajenos al funcionamiento de la aplicación.',
            ),

            SectionTitleWidget('4. Privacidad y protección de datos'),
            ParagraphTextWidget(
              'Los datos personales recolectados son tratados conforme a las leyes de protección de datos vigentes. '
              'Solo se conservarán durante el tiempo necesario para cumplir con las finalidades del servicio '
              'y se eliminarán de forma segura cuando dejen de ser requeridos.',
            ),

            SectionTitleWidget('5. Responsabilidad del usuario'),
            ParagraphTextWidget(
              'El usuario se compromete a utilizar la aplicación de manera adecuada y segura. '
              'Cualquier uso indebido o actividad que contravenga estos términos puede resultar en la suspensión de la cuenta.',
            ),

            SectionTitleWidget('6. Propiedad intelectual'),
            ParagraphTextWidget(
              'Todos los derechos sobre el diseño, código fuente, logotipos y contenidos de la aplicación '
              'pertenecen a sus respectivos titulares. No se autoriza su uso, copia o modificación sin permiso expreso.',
            ),

            SectionTitleWidget('7. Limitación de responsabilidad'),
            ParagraphTextWidget(
              'Hacemos esfuerzos razonables para asegurar la disponibilidad y correcto funcionamiento del servicio. '
              'Sin embargo, no garantizamos la ausencia de interrupciones, errores o pérdidas de información derivadas del uso de la aplicación.',
            ),

            SectionTitleWidget('8. Modificaciones'),
            ParagraphTextWidget(
              'Podemos actualizar estos Términos y Condiciones en cualquier momento. '
              'La versión vigente estará siempre disponible en esta sección, indicando la fecha de la última actualización.',
            ),

            SectionTitleWidget('9. Contacto'),
            ParagraphTextWidget(
              'Si tienes preguntas o deseas ejercer tus derechos de acceso, rectificación o eliminación de datos, '
              'puedes escribirnos a: soporte@pragma.com.co',
            ),

            SizedBox(height: 24),
            ParagraphTextWidget(
              'Al continuar utilizando esta aplicación, confirmas que has leído y aceptas '
              'los presentes Términos y Condiciones.',
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
