import 'dart:io';

class                                                                                                                                                                                               ShimComponent {
  ShimComponent(this.targetFile, this.code, {
    this.includes = const [], this.sysIncludes = const [],
    this.libraries = const [], this.extraArgs = const [],
    this.libraryPaths = const [],
    this.stackTrace
  }) {
    stackTrace ??= StackTrace.current;
  }

  String targetFile;
  String code;
  List<String> sysIncludes;
  List<String> includes;
  List<String> libraries;
  List<String> libraryPaths;
  List<String> extraArgs;
  StackTrace stackTrace;

  ShimComponent.fromJson(dynamic jsonData) :
    targetFile = jsonData["target"],
    code = jsonData["code"],
    sysIncludes = (jsonData["sysIncludes"] as List).cast<String>(),
    includes = (jsonData["includes"] as List).cast<String>(),
    libraries = (jsonData["libraries"] as List).cast<String>(),
    libraryPaths = (jsonData["libraryPaths"] as List).cast<String>(),
    extraArgs = (jsonData["extraArgs"] as List).cast<String>(),
    stackTrace = StackTrace.fromString(jsonData["stackTrace"]);
}

class ShimCompilerException {
  ShimCompilerException(this.cause);
  String cause;
  toString() => cause;
}

class ShimCompiler {
  Future compile({
    String compiler,
    String outputObject,
    List<ShimComponent> components,
    List<String> extraArgs,
    bool debugPrints = true,
  }) async {
    var args = [
      "-c", "-fPIC", "-shared", "-x", "c", "-o", outputObject,
      ...extraArgs
    ];

    var sysIncludes = <String>{};
    var includes = <String>{};
    var libraries = <String>{};
    var libraryPaths = <String>{};
    for (var comp in components) {
      args.addAll(comp.extraArgs);
      sysIncludes.addAll(comp.sysIncludes);
      includes.addAll(comp.includes);
      libraries.addAll(comp.libraries);
      libraryPaths.addAll(comp.libraryPaths);
    }

    for (var l in libraryPaths) {
      args.add("-L$l");
    }

    for (var l in libraries) {
      args.add("-l$l");
    }

    args.add("-");

    var cres = await Process.start(compiler, args);

    for (var i in sysIncludes) {
      cres.stdin.writeln("#include <$i>");
    }

    for (var i in sysIncludes) {
      cres.stdin.writeln("#include \"$i\"");
    }

    for (var comp in components) {
      cres.stdin.writeln(comp.code);
    }

    await cres.stdin.close();

    if (await cres.exitCode != 0) {
      // TODO: parse line numbers in errors and propagate these exceptions with
      // the components stack trace
      throw ShimCompilerException(await cres.stderr.join());
    }
  }
}