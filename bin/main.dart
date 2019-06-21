import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bindgen/clang_decl.dart';
import 'package:bindgen/bind_transformers.dart';
import 'package:bindgen/bindmap.dart';

Future main() async {
  var unit = CUnitDecl.fromJson(jsonDecode(await File("testUnit.json").readAsString()));
  debugger();
  print(unit);
}