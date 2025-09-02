import 'package:flutter/material.dart';
import 'package:jocaaguraarchetype/jocaaguraarchetype.dart';

import 'pixel_config.dart';
import 'ui/pages/pages.dart';

void main() => runApp(
  JocaaguraApp(
    appManager: AppManager(pixelConfig.dev()),
    registry: pageRegistry,
  ),
);
