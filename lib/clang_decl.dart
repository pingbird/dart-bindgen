/// Library containing definitions for clang types and declarations from a
/// clang compilation unit.
///
/// To load a declaration file use [jsonDecode] and [CUnitDecl.fromJson].
library clang_decl;

import 'dart:collection';
import 'dart:convert';

import 'package:bindgen/bindmap.dart';

import 'package:quiver/core.dart';
import 'package:quiver/collection.dart';

/// The base class for canonicalized clang types
abstract class CType {
  CType();

  factory CType.fromJson(dynamic jsonData) {
    if (jsonData["kind"] == "Function") return CFuncType.fromJson(jsonData);
    if (jsonData["kind"] == "Pointer") return CPointerType.fromJson(jsonData);
    if (jsonData["kind"] == "Struct") return CStructType.fromJson(jsonData);
    if (jsonData["kind"] == "Primitive") return CPrimitiveType.fromJson(jsonData);
    return null;
  }
}

class CFuncType extends CType {
  CFuncType(this.returnType, this.argTypes, {this.varadic = false});

  bool varadic;
  CType returnType;
  List<CType> argTypes;

  CFuncType.fromJson(dynamic jsonData) :
    returnType = CType.fromJson(jsonData["returnType"]),
    argTypes = (jsonData["argTypes"] as Iterable).map((e) => CType.fromJson(e)).toList(),
    varadic = jsonData["varadic"] == true;

  get hashCode => hash4("CFunc", varadic, returnType, hashObjects(argTypes));
  operator ==(other) =>
    other is CFuncType &&
    varadic == other.varadic &&
    returnType == other.returnType &&
    listsEqual(argTypes, other.argTypes);
}

class CPointerType extends CType {
  CPointerType(this.pointee);

  CType pointee;

  CPointerType.fromJson(dynamic jsonData) :
    pointee = CType.fromJson(jsonData["pointee"]);

  get hashCode => hash2("CPointer", pointee);
  operator ==(other) =>
    other is CPointerType &&
    pointee == other.pointee;

}

class CStructType extends CType {
  CStructType(this.name);

  String name;

  CStructType.fromJson(dynamic jsonData) :
    name = jsonData["name"];

  get hashCode => hash2("CStruct", name);
  operator ==(other) =>
    other is CStructType &&
    name == other.name;
}

enum CPrimitiveKind {
  VOID, BOOL,
  UCHAR, USHORT, UINT, ULONG, ULLONG,
  SCHAR, SSHORT, SINT, SLONG, SLLONG,
  FLOAT, DOUBLE,
  UNKNOWN,
}

class CPrimitiveType extends CType {
  CPrimitiveType(this.kind);
  CPrimitiveKind kind;

  static const kindNames = {
    "void": CPrimitiveKind.VOID,
    "bool": CPrimitiveKind.BOOL,
    "unsigned char": CPrimitiveKind.UCHAR,
    "unsigned short": CPrimitiveKind.USHORT,
    "unsigned int": CPrimitiveKind.UINT,
    "unsigned long": CPrimitiveKind.ULONG,
    "unsigned long long": CPrimitiveKind.ULLONG,
    "signed char": CPrimitiveKind.SCHAR,
    "signed short": CPrimitiveKind.SSHORT,
    "signed int": CPrimitiveKind.SINT,
    "signed long": CPrimitiveKind.SLONG,
    "signed long long": CPrimitiveKind.SLLONG,
    "float": CPrimitiveKind.FLOAT,
    "double": CPrimitiveKind.DOUBLE,
  };

  CPrimitiveType.fromJson(dynamic jsonData) :
    kind = CPrimitiveType.kindNames.containsKey(jsonData["name"]) ?
      CPrimitiveType.kindNames[jsonData["name"]] : CPrimitiveKind.UNKNOWN;

  get hashCode => hash2("CPrimitive", kind);
  operator ==(other) =>
    other is CPrimitiveType &&
    kind == other.kind;
}

class CSrcRef {
  CSrcRef(this.fileName, this.line, this.col, this.offset);

  String fileName;
  int line;
  int col;
  int offset;

  CSrcRef.fromJson(dynamic jsonData) :
    fileName = jsonData["fileName"],
    line = jsonData["line"],
    col = jsonData["col"],
    offset = jsonData["offset"];

  get hashCode => hashObjects(["CSrcRef", fileName, line, col, offset]);
  operator ==(other) =>
    other is CSrcRef &&
    other.fileName == fileName &&
    other.line == line &&
    other.col == col &&
    other.offset == offset;
}

class CFieldDecl {
  CFieldDecl(this.name, this.type, this.size, this.offset);

  String name;
  CType type;
  int size;
  int offset;

  CFieldDecl.fromJson(dynamic jsonData) :
    name = jsonData["name"],
    type = CType.fromJson(jsonData["type"]),
    size = jsonData["size"],
    offset = jsonData["offset"];
}

class CStructDecl {
  CStructDecl(this.fields, this.size);

  LinkedHashMap<String, CFieldDecl> fields;
  int size;

  CStructDecl.fromJson(dynamic jsonData) :
    fields = LinkedHashMap.fromEntries((jsonData["fields"] as List).map((e) {
      var field = CFieldDecl.fromJson(e);
      return MapEntry(field.name, field);
    })),
    size = jsonData["size"];
}

class CVarDecl {
  CVarDecl(this.type);

  CFuncType type;

  CVarDecl.fromJson(dynamic jsonData) :
    type = CFuncType.fromJson(jsonData);
}

class CConstDecl {
  CConstDecl(this.name, this.type, this.value);

  String name;
  CType type;
  dynamic value;

  CConstDecl.fromJson(dynamic jsonData) :
    name = jsonData["name"],
    type = CType.fromJson(jsonData["type"]),
    value = jsonData["value"];
}

/// A container for all of a clang compilation units top-level declarations.
class CUnitDecl {
  CUnitDecl({this.structs, this.vars, this.constants}) {
    structs ??= {};
    vars ??= {};
    constants ??= {};
  }

  Map<String, CSrcRef> srcRefs;
  Map<String, CStructDecl> structs;
  Map<String, CVarDecl> vars;
  Map<String, CConstDecl> constants;

  CUnitDecl.fromJson(dynamic jsonData) :
    structs = (jsonData["structs"] as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, CStructDecl.fromJson(v))),
    vars = (jsonData["vars"] as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, CVarDecl.fromJson(v))),
    constants = (jsonData["constants"] as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, CConstDecl.fromJson(v))),
    srcRefs = (jsonData["srcRefs"] as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, CSrcRef.fromJson(v)));
}