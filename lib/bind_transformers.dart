/// Library to mutate [BindMap]s
///
/// By default [BindMap]s contain every declaration from a clang
/// compilation unit, including those from system headers.
///
/// This library provides a set of [BindTransformer]s which can be used to remove
/// unwanted declarations including those from different files
/// (see [SourceFileFilter]) or from libraries that are outside of your binding
/// (see [DynamicLibraryFilter]).
library bind_filter;

import 'dart:async';
import 'dart:ffi';

import 'package:path/path.dart' as path_util;

import 'package:bindgen/bindmap.dart';
import 'package:bindgen/clang_decl.dart';

/// The base class for filters that transform a [BindMap].
abstract class BindTransformer {
  Future transform(BindMap bind);
}

/// Adds a clang unit to a [BindMap] with default mapping of declaration names.
class UnitDeclInit extends BindTransformer {
  UnitDeclInit(this.unit, {this.library});
  CUnitDecl unit;
  String library;

  transform(BindMap bind) async {
    bind.srcRefs.addEntries(unit.srcRefs.entries.map((e) => MapEntry(
      BindSymbol(e.key, library), e.value
    )));

    bind.structs.addEntries(unit.structs.entries.map((e) => MapEntry(
      BindSymbol(e.key, library),
      StructDeclMap(DartRef(e.key), e.value.fields.map((k, v) => MapEntry(
        k, DartRef(k)
      ))),
    )));

    bind.vars.addEntries(unit.vars.entries.map((e) => MapEntry(
      BindSymbol(e.key, library), DartRef(e.key),
    )));

    bind.constants.addEntries(unit.constants.entries.map((e) => MapEntry(
      BindSymbol(e.key, library), DartRef(e.key)
    )));
  }
}

/// Removes symbols which are not found in the provided dart:ffi [libraries].
///
/// If [inclusive] is false this filter removes symbols which are
/// provided in [libraries] instead of keeping ones that are.
class DynamicLibraryFilter extends BindTransformer {
  DynamicLibraryFilter(this.libraries, {this.inclusive = true});

  List<DynamicLibrary> libraries;
  bool inclusive;

  transform(BindMap bind) async {
    bind.vars.removeWhere((k, vr) =>
      inclusive != libraries.any((lib) {
        bool hit = true;

        try {
          lib.lookup(k.name);
        } on ArgumentError catch (e) {
          hit = false;
        }

        return hit;
      })
    );
  }
}

/// Removes declarations outside of source files matching [paths].
///
/// Paths in [paths] may contain wildcards "*". Example:
///
///     // Remove declarations outside of llvm
///     var filter = SourceFileFilter(["/usr/lib/llvm-6.0/include/*"]);
///
/// If [inclusive] is false this filter removes declarations that match [paths]
/// instead of keeping declaration that do. Example:
///
///     // Remove system declarations
///     var filter = SourceFileFilter(["/usr/include/*"], inclusive: false);
///
class SourceFileFilter extends BindTransformer {
  SourceFileFilter(this.paths, {this.inclusive = true}) {
    paths = paths.map(path_util.canonicalize).toList();
  }

  List<String> paths = [];
  bool inclusive;

  bool acceptsPath(String path) => inclusive == paths.any((apath) =>
    RegExp("^${RegExp.escape(path_util.canonicalize(apath))
      .replaceAll("\\*", ".+")}\$").hasMatch(path_util.canonicalize(path))
  );

  transform(BindMap bind) async {
    bind.vars.removeWhere((k, e) => !acceptsPath(bind.srcRefs[k].fileName));
    bind.structs.removeWhere((k, e) => !acceptsPath(bind.srcRefs[k].fileName));
    bind.constants.removeWhere((k, e) => !acceptsPath(bind.srcRefs[k].fileName));
  }
}