import 'package:bindgen/binding.dart';
import 'package:bindgen/clang_decl.dart';
import 'package:meta/meta.dart';

/// Binding generator
abstract class BindLibraryGen {
  Map<String, String> generate({
    BindMap bindMap, CUnitDecl unit,
  });
}


