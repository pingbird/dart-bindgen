import 'dart:collection';
import 'dart:convert';

import 'package:bindgen/clang_decl.dart';
import 'package:bindgen/shims.dart';
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

abstract class DeclMap {
  DeclMap(this.ref, this.srcRef);
  DartRef ref;
  CSrcRef srcRef;
  DeclMap.fromJson(dynamic jsonData) :
    ref = DartRef.fromJson(jsonData["ref"]),
    srcRef = CSrcRef.fromJson(jsonData["srcRef"]);
}

/// Container for mapping C struct and field declarations to their [DartRef]s.
class StructDeclMap extends DeclMap {
  StructDeclMap(this.decl, this.fields, DartRef ref, CSrcRef srcRef) :
    super(ref, srcRef);

  CStructDecl decl;
  LinkedHashMap<String, String> fields;

  StructDeclMap.fromJson(dynamic jsonData) :
    decl = CStructDecl.fromJson(jsonData["decl"]),
    fields = LinkedHashMap.fromEntries((jsonData["fields"] as List).map((e) {
      return MapEntry(e["name"], e["ref"]);
    })),
    super.fromJson(jsonData);
}

/// Container for mapping C variable declarations (incl. functions) to
/// their [DartRef]s.
class VarDeclMap extends DeclMap {
  VarDeclMap(this.decl, DartRef ref, CSrcRef srcRef) :
    super(ref, srcRef);

  CVarDecl decl;

  VarDeclMap.fromJson(dynamic jsonData) :
    decl = CVarDecl.fromJson(jsonData["decl"]),
    super.fromJson(jsonData);
}

/// Container for mapping C constants to their [DartRef]s.
class ConstDeclMap extends DeclMap {
  ConstDeclMap(this.decl, DartRef ref, CSrcRef srcRef) :
    super(ref, srcRef);

  CConstDecl decl;

  ConstDeclMap.fromJson(dynamic jsonData) :
    decl = CConstDecl.fromJson(jsonData["decl"]),
    super.fromJson(jsonData);
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

  /// Bindings for all struct declarations.
  Map<BindSymbol, StructDeclMap> structs = {};

  /// Bindings for all variable declarations (including functions).
  Map<BindSymbol, VarDeclMap> vars = {};

  /// Bindings for all constants.
  Map<BindSymbol, ConstDeclMap> constants = {};

  /// Shim components to be compiled.
  List<ShimComponent> shims = [];

  BindMap.fromJson(dynamic jsonData) :
    structs = (jsonData["structs"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(BindSymbol.fromJson(jsonDecode(k)), StructDeclMap.fromJson(v))
    ),
    vars = (jsonData["vars"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(BindSymbol.fromJson(jsonDecode(k)), VarDeclMap.fromJson(v))
    ),
    constants = (jsonData["constants"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(BindSymbol.fromJson(jsonDecode(k)), ConstDeclMap.fromJson(v))
    ),
    shims = (jsonData["shims"] as List).map((e) =>
      ShimComponent.fromJson(e)
    ).toList();
}