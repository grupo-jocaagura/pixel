import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import '../../widgets/legal/info_grid_widget.dart';
import '../../widgets/legal/section_widget.dart';
import '../../widgets/legal/sub_section_widget.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({
    super.key,
    this.contactEmail = 'soporte@jocaagura.com',
  });

  final String contactEmail;

  static const String title = 'Política de Privacidad';
  static const PageModel pageModel = PageModel(
    name: 'privacy-policy',
    segments: <String>['privacy-policy'],
  );
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle h1 = theme.textTheme.headlineSmall!.copyWith(
      fontWeight: FontWeight.w700,
    );
    final TextStyle h2 = theme.textTheme.titleMedium!.copyWith(
      fontWeight: FontWeight.w700,
    );
    final TextStyle body = theme.textTheme.bodyMedium!;
    final String lastUpdatedStr = _fmtDate(DateTime(2025, 10, 26));

    return Scaffold(
      appBar: AppBar(title: const Text(title)),
      body: ColoredBox(
        color: theme.colorScheme.surface,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: <Widget>[
            Text('Política de Privacidad – Pixel / Pixarra', style: h1),
            const SizedBox(height: 4),
            Text(
              'Última actualización: $lastUpdatedStr',
              style: body.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: 12),
            InfoGridWidget(contactEmail: contactEmail),
            const SizedBox(height: 12),

            SectionWidget(
              title: '1. Introducción',
              paragraphs: const <String>[
                'En JOCAAGURA valoramos y protegemos tu privacidad. Esta política explica cómo la aplicación ',
                'accede, utiliza, almacena y protege los datos personales, incluyendo aquellos autorizados a través ',
                'de servicios de terceros para autenticación.',
                'Al utilizar la aplicación o iniciar sesión, aceptas esta Política de Privacidad.',
              ],
              h2: h2,
              body: body,
            ),

            SectionWidget(
              title: '2. Datos que recopilamos',
              paragraphs: const <String>[
                'Recopilamos la información mínima necesaria para operar y mejorar la aplicación.',
              ],
              bullets: const <String>[
                'Nombre, correo electrónico y foto de perfil obtenidos mediante el proveedor de identidad (p. ej., Google).',
                'Preferencias de idioma y configuración local.',
              ],
              subSections: const <SubSectionWidget>[
                SubSectionWidget(
                  subtitle: 'Datos técnicos automáticos',
                  bullets: <String>[
                    'Tipo de dispositivo, sistema operativo y versión del navegador.',
                    'Identificadores (cookies o almacenamiento local) para mantener sesión y mejorar la experiencia.',
                  ],
                ),
              ],
              h2: h2,
              body: body,
            ),

            SectionWidget(
              title: '3. Finalidad del uso de los datos',
              numbered: const <String>[
                'Autenticación y acceso seguro a funcionalidades.',
                'Personalización básica (p. ej., nombre/foto de perfil visible en la UI).',
                'Sincronización de información asociada a tu usuario cuando aplique.',
                'Mejora continua de estabilidad, rendimiento y experiencia de uso.',
              ],
              paragraphs: const <String>[
                'No utilizamos tu información personal para publicidad dirigida ni la compartimos con terceros ',
                'para fines ajenos al funcionamiento de la aplicación.',
              ],
              h2: h2,
              body: body,
            ),

            SectionWidget(
              title: '4. Base legal y consentimiento',
              paragraphs: const <String>[
                'Tratamos los datos conforme a la Ley 1581 de 2012 y normativas aplicables de protección de datos, ',
                'así como a las políticas de los proveedores usados para autenticación. ',
                'El consentimiento se obtiene al iniciar sesión y autorizar los permisos solicitados.',
              ],
              h2: h2,
              body: body,
            ),

            SectionWidget(
              title: '5. Almacenamiento y protección',
              bullets: const <String>[
                'Infraestructura en la nube con certificaciones de seguridad (p. ej., ISO 27001, SOC 2).',
                'Cifrado TLS/HTTPS en tránsito y cifrado en reposo según la plataforma.',
                'Controles de acceso interno restringido y registro/auditoría.',
                'Políticas de respaldo y recuperación razonables para continuidad.',
              ],
              h2: h2,
              body: body,
            ),

            SectionWidget(
              title: '6. Retención y eliminación de datos',
              bullets: <String>[
                'Conservamos datos mientras tu cuenta se mantenga activa o por requerimientos legales.',
                'Para solicitar la eliminación total, escribe a $contactEmail con asunto “Eliminación de datos”. ',
                'Responderemos en un plazo razonable conforme a la normativa aplicable.',
              ],
              h2: h2,
              body: body,
            ),

            SectionWidget(
              title: '7. Compartición de datos y proveedores',
              paragraphs: const <String>[
                'No vendemos ni alquilamos datos personales. Únicamente empleamos proveedores tecnológicos necesarios ',
                'para operar la aplicación. A continuación, algunos de los más relevantes:',
              ],
              table: const <List<String>>[
                <String>['Proveedor', 'Finalidad', 'Política'],
                <String>[
                  'Google Firebase / Cloud',
                  'Autenticación, almacenamiento, hosting',
                  'https://policies.google.com/privacy',
                ],
                <String>[
                  'Google Identity / APIs',
                  'Inicio de sesión e integraciones',
                  'https://developers.google.com/terms/api-services-user-data-policy',
                ],
              ],
              h2: h2,
              body: body,
            ),

            SectionWidget(
              title: '8. Derechos del usuario',
              paragraphs: <String>[
                'Puedes solicitar acceso, actualización, rectificación o eliminación de tus datos enviando un correo a ',
                '$contactEmail. Atenderemos tu solicitud dentro de los plazos previstos por la ley.',
              ],
              h2: h2,
              body: body,
            ),

            const SectionWidget(
              title: '9. Menores de edad',
              paragraphs: <String>[
                'La aplicación no está dirigida a menores de 13 años. Ante la detección de datos de un menor, ',
                'los eliminaremos al ser notificados.',
              ],
              h2: null,
              body: null,
            ),

            SectionWidget(
              title: '10. Cookies y almacenamiento local',
              paragraphs: const <String>[
                'Utilizamos cookies y/o almacenamiento local para mantener la sesión, recordar preferencias y ',
                'mejorar el rendimiento. Puedes gestionarlo desde la configuración de tu navegador.',
              ],
              h2: h2,
              body: body,
            ),

            const SectionWidget(
              title: '11. Cambios en esta política',
              paragraphs: <String>[
                'Podemos actualizar esta política. Cuando existan cambios materiales, actualizaremos la fecha e ',
                'informaremos oportunamente por los canales disponibles.',
              ],
              h2: null,
              body: null,
            ),

            const SizedBox(height: 24),
            Divider(color: theme.dividerColor),
            const SizedBox(height: 12),
            Center(
              child: Text(
                '© ${0} GRUPO JOCAAGURA S.A.S. · Términos y Condiciones · Privacidad'
                    .replaceFirst('0', DateTime.now().year.toString()),
                style: body.copyWith(color: theme.hintColor),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    // Formato dd/mm/yyyy sin dependencias.
    final String dd = d.day.toString().padLeft(2, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    final String yyyy = d.year.toString();
    return '$dd/$mm/$yyyy';
  }
}
