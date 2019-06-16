/// Library to mutate [BindMap]s
///
/// By default [BindMap]s contain every declaration from a clang
/// compilation unit, including those from system headers.
///
/// This library provides a set of [BindFilter]s which can be used to remove
/// unwanted declarations including those from different files
/// (see [SourceFileFilter]) or from libraries that are outside of your binding
/// (see [DynamicLibraryFilter]).
library bind_filter;

import 'dart:async';
import 'dart:ffi';

import 'package:path/path.dart' as pathUtil;

import 'package:bindgen/binding.dart';
import 'package:bindgen/clang_decl.dart';

/// The base class for filters that mutate a [BindMap].
abstract class BindFilter {
  Future filter(BindMap bindMap, CUnitDecl compUnit);
}

/// Removes symbols which are not found in the provided dart:ffi [libraries].
///
/// If [inclusive] is false this filter removes symbols which are
/// provided in [libraries] instead of keeping ones that are.
class DynamicLibraryFilter extends BindFilter {
  DynamicLibraryFilter(this.libraries, {this.inclusive = true});

  List<DynamicLibrary> libraries = [];
  bool inclusive;

  filter(BindMap bindMap, CUnitDecl unit) async {
    bindMap.vars.removeWhere((k, vr) =>
      inclusive != libraries.any((lib) => lib.lookupFunction(k) != null)
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
class SourceFileFilter extends BindFilter {
  SourceFileFilter(this.paths, {this.inclusive = true}) {
    paths = paths.map(pathUtil.canonicalize).toList();
  }

  List<String> paths = [];
  bool inclusive;

  bool acceptsPath(String path) => inclusive == paths.any((apath) =>
    RegExp("^${RegExp.escape(pathUtil.canonicalize(apath))
      .replaceAll("\\*", ".+")}\$").hasMatch(pathUtil.canonicalize(path))
  );

  filter(BindMap bindMap, CUnitDecl unit) async {
    bindMap.vars.removeWhere((k, e) => !acceptsPath(unit.vars[k].fileName));
    bindMap.structs.removeWhere((k, e) => !acceptsPath(unit.vars[k].fileName));
    bindMap.constants.removeWhere((k, e) => !acceptsPath(unit.vars[k].fileName));
  }
}