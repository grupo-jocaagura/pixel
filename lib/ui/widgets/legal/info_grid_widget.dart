import 'package:flutter/material.dart';

class InfoGridWidget extends StatelessWidget {
  const InfoGridWidget({required this.contactEmail, super.key});

  final String contactEmail;

  @override
  Widget build(BuildContext context) {
    final TextStyle body = Theme.of(context).textTheme.bodyMedium!;
    final Color hint = Theme.of(context).hintColor;
    return LayoutBuilder(
      builder: (BuildContext _, BoxConstraints c) {
        final bool wide = c.maxWidth >= 720;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: SelectableText(
                'Entidad responsable: GRUPO JOCAAGURA S.A.S.\n'
                'NIT: 901270782-7\n'
                'Domicilio: Mosquera, Cundinamarca, Colombia',
                style: body.copyWith(color: hint),
              ),
            ),
            const SizedBox(width: 16, height: 8),
            Flexible(
              child: SelectableText(
                'Contacto: $contactEmail\n'
                'Enlaces legales disponibles en el sitio.',
                style: body.copyWith(color: hint),
              ),
            ),
          ],
        );
      },
    );
  }
}
