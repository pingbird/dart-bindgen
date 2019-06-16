import 'package:bindgen/clang_decl.dart';

/// A reference to the destination symbol of a [CUnitDecl] declaration.
///
/// The field [name] is the name exposed by the generated Dart library.
///
/// The field [dest] is the file to declare it, without the .dart extension.
///
/// The field [destClass] is the destination class to put the declaration in.
class DartRef {
  DartRef(this.name, {this.dest, this.destClass});
  String name;
  String dest;
  String destClass;
  toString() => "${dest == null ? "" : "$dest::"}${destClass == null ? "" : "$destClass."}$name";

  DartRef.fromJson(dynamic jsonData) :
    name = jsonData["name"],
    dest = jsonData["dest"],
    destClass = jsonData["destClass"];
}

/// Container for mapping C struct and field declarations to their [DartRef]s.
class StructDeclMap {
  StructDeclMap(this.ref, this.fieldRefs);
  DartRef ref;
  Map<String, DartRef> fieldRefs;

  StructDeclMap.fromJson(dynamic jsonData) :
    ref = DartRef.fromJson(jsonData["ref"]),
    fieldRefs = (jsonData["fieldRefs"] as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, DartRef.fromJson(v)));
}

/// Container for mapping all C declarations to their [DartRef]s.
///
/// Currently there are 3 declaration types supported: [structs], [vars],
/// and [constants]. These declarations are mapped to [DartRef]s which tell
/// codegen where to place the declarations in Dart.
///
/// The field [structs] contains all struct declarations.
///
/// The field [vars] contains all variable declarations, including functions.
///
/// The field [constants] contains all constants.
class BindMap {
  BindMap(this.structs, this.vars, this.constants);

  Map<String, StructDeclMap> structs = {};
  Map<String, DartRef> vars = {};
  Map<String, DartRef> constants = {};

  /// Constructs a default [BindMap] which maps a [CUnitDecl]s declarations 1:1.
  BindMap.build(CUnitDecl unit) {
    structs = unit.structs.map((k, v) =>
      MapEntry(k, StructDeclMap(DartRef(k), v.fields.map((fk, fv) =>
        MapEntry(fk, DartRef(fk))
      )))
    );
    vars = unit.vars.map((k, v) => MapEntry(k, DartRef(k)));
    constants = unit.constants.map((k, v) => MapEntry(k, DartRef(k)));
  }

  BindMap.fromJson(dynamic jsonData) :
    structs = (jsonData["structs"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(k, StructDeclMap.fromJson(v))
    ),
    vars = (jsonData["vars"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(k, DartRef.fromJson(v))
    ),
    constants = (jsonData["constants"] as Map<String, dynamic>).map((k, v) =>
      MapEntry(k, DartRef.fromJson(v))
    );
}