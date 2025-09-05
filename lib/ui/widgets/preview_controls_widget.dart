import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';
import 'package:text_responsive/text_responsive.dart';

import '../../app/blocs/bloc_canvas.dart';
import '../../app/blocs/bloc_canvas_preview.dart';
import '../../domain/states/state_preview.dart';
import 'pixel_icon_button.dart';

/// Common bottom controls for draw previews:
/// - toggle coordinates
/// - fill switch
/// - stroke input
/// - square resolution input (NxN)
/// - "Apply" action
///
/// Consumers inject shape-specific coordinate editors via [coordinatesEditor].
///
/// ### Example
/// ```dart
/// PreviewControlsCommon(
///   canvasBloc: canvasBloc,
///   previewBloc: previewBloc,
///   state: state,
///   applyLabel: 'Dibujar rect',
///   applyIcon: Icons.crop_square,
///   coordinatesEditor: Row(children: [
///     CoordEditorWidget(...), // P1
///     CoordEditorWidget(...), // P2
///   ]),
/// )
/// ```
class PreviewControlsWidget extends StatelessWidget {
  const PreviewControlsWidget({
    required this.canvasBloc,
    required this.previewBloc,
    required this.state,
    required this.coordinatesEditor,
    required this.applyLabel,
    required this.applyIcon,
    super.key,
    this.showFill = true,
    this.showStroke = true,
    this.showCoordsSwitch = true,
    this.showResolution = true,
    this.extraActions = const <Widget>[],
  });

  final BlocCanvas canvasBloc;
  final BlocCanvasPreview previewBloc;
  final StatePreview state;

  /// Shape-specific section (e.g., P1/P2 editors, Center/Edge editors).
  final Widget coordinatesEditor;

  /// Main apply button.
  final String applyLabel;
  final IconData applyIcon;

  /// Toggles for which common controls to show.
  final bool showFill;
  final bool showStroke;
  final bool showCoordsSwitch;
  final bool showResolution;

  /// Optional trailing actions.
  final List<Widget> extraActions;

  String? _validateStroke(String? v) {
    if (v == null || v.isEmpty) {
      return 'requerido';
    }
    final int? n = int.tryParse(v);
    if (n == null || n < 1) {
      return 'mínimo 1';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    String pendingRes = canvasBloc.canvas.width.toString();

    return Material(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              coordinatesEditor,

              if (showCoordsSwitch)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const InlineTextWidget('Mostrar coord'),
                    Switch(
                      value: state.showCoords,
                      onChanged: (bool v) => previewBloc.setShowCoords(
                        v,
                        canvasBloc.canvas,
                        canvasBloc.selectedHex,
                      ),
                    ),
                  ],
                ),

              if (showFill)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const InlineTextWidget('Relleno'),
                    Switch(
                      value: state.fill,
                      onChanged: (bool v) => previewBloc.setFill(
                        v,
                        canvasBloc.canvas,
                        canvasBloc.selectedHex,
                      ),
                    ),
                  ],
                ),

              if (showStroke)
                SizedBox(
                  width: 120,
                  child: CustomAutoCompleteInputWidget(
                    label: 'Stroke',
                    initialData: state.stroke.toString(),
                    placeholder: '≥ 1',
                    textInputType: TextInputType.number,
                    suggestList: const <String>['1', '2', '3', '4', '5', '8'],
                    onChangedDebounce: const Duration(milliseconds: 120),
                    onEditingValidateFunction: _validateStroke,
                    onChanged: (String v) {
                      final int? n = int.tryParse(v);
                      if (n != null && n >= 1) {
                        previewBloc.setStroke(
                          n,
                          canvasBloc.canvas,
                          canvasBloc.selectedHex,
                        );
                      }
                    },
                    onFieldSubmitted: (String v) {
                      final int? n = int.tryParse(v);
                      if (n != null && n >= 1) {
                        previewBloc.setStroke(
                          n,
                          canvasBloc.canvas,
                          canvasBloc.selectedHex,
                        );
                      }
                    },
                  ),
                ),

              if (showResolution) ...<Widget>[
                SizedBox(
                  width: 140,
                  child: CustomAutoCompleteInputWidget(
                    label: 'Resolución',
                    initialData: canvasBloc.canvas.width.toString(),
                    placeholder: 'N (NxN)',
                    textInputType: TextInputType.number,
                    suggestList: const <String>['10', '20', '40', '80', '160'],
                    onEditingValidateFunction: (String? value) =>
                        canvasBloc.validateResolutionValue(
                          Utils.getStringFromDynamic(value),
                        ),
                    onChanged: (String v) => pendingRes = v,
                    onFieldSubmitted: (String v) {
                      pendingRes = v;
                      canvasBloc.updateResolutionFromString(pendingRes);
                    },
                  ),
                ),
                PixelIconButton(
                  tooltip: 'Aplicar resolución',
                  icon: const Icon(Icons.check_circle, color: Colors.blue),
                  onPressed: () =>
                      canvasBloc.updateResolutionFromString(pendingRes),
                ),
              ],

              ElevatedButton.icon(
                onPressed: state.hasSelection
                    ? () => previewBloc.apply(canvasBloc)
                    : null,
                icon: Icon(applyIcon),
                label: Text(applyLabel),
              ),

              ...extraActions,
            ],
          ),
        ),
      ),
    );
  }
}
