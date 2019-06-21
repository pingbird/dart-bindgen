import 'dart:collection';
import 'dart:convert';

import 'package:bindgen/clang_decl.dart';
import 'package:quiver/core.dart';

/// A reference to a C symbol in a specific library
class BindSymbol {
  BindSymbol(this.name, this.library);

  String name;

  String library;

  get hashCode => hash3("CSymbolRef", name, library);
  operator==(other) =>
    other is BindSymbol &&
    other.name == name &&
    other.library == library;

  BindSymbol.fromJson(dynamic jsonData) :
    name = jsonData["name"],
    library = jsonData["library"];
}

/// A reference to the destination symbol of a [CUnitDecl] declaration.
class DartRef {
  DartRef(this.name, {this.dest, this.destClass});

  /// The name exposed by the generated Dart library.
  String name;

  /// The file to declare it (without the .dart extension).
  String dest;

  /// The destination class to put the declaration in.
  String destClass;

  toString() => "${dest == null ? "" : "$dest::"}"
    "${destClass == null ? "" : "$destClass."}$name";

  DartRef.fromJson(dynamic jsonData) :
    name = jsonData["name"],
    dest = jsonData["dest"],
    destClass = jsonData["destClass"];
}

/// Container for mapping C struct and field declarations to their [DartRef]s.
class StructDeclMap {
  StructDeclMap(this.ref, this.fields);
  DartRef ref;
  LinkedHashMap<String, DartRef> fields;
  StructDeclMap.fromJson(dynamic jsonData) :
    ref = DartRef.fromJson(jsonData["ref"]),
    fields = LinkedHashMap.fromEntries((jsonData["fieldRefs"] as List).map((e) {
      return MapEntry(e["name"], DartRef.fromJson(e["ref"]));
    }));
}

/// Container for mapping all C declarations to their [DartRef]s.
///
/// Currently there are 3 declaration types supported: [structs], [vars],
/// and [constants]. These declarations are mapped to [DartRef]s which tell
/// codegen where to place the declarations in Dart.
class BindMap {
  BindMap({this.structs, this.vars, this.constants}) {
    structs ??= {};
    vars ??= {};
    constants ??= {};
  }

  /// Source references for all declarations.
  Map<BindSymbol, CSrcRef> srcRefs;

  /// Bindings for all struct declarations.
  Map<BindSymbol, StructDeclMap> structs = {};

  /// Bindings for all variable declarations (including functions).
  Map<BindSymbol, DartRef> vars = {};

  /// Bindings for all constants.
  Map<BindSymbol, DartRef> constants = {};

  BindMap.fromJson(dynamic jsonData) :
    structs = (jsonData["structs"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(BindSymbol.fromJson(jsonDecode(k)), StructDeclMap.fromJson(v))
    ),
    vars = (jsonData["vars"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(BindSymbol.fromJson(jsonDecode(k)), DartRef.fromJson(v))
    ),
    constants = (jsonData["constants"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(BindSymbol.fromJson(jsonDecode(k)), DartRef.fromJson(v))
    );
}