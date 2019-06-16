import 'dart:io';

const bindgenHelp = """Usage: dart-bindgen <command> ...

Commands:
  decldump <source_file> <output_file> [-a <compiler arg>]
    | Dump declarations from a C/C++ source file to a JSON file.
    | To add compiler args pass -a followed by the argument,
    | -a can be used multiple times to pass multiple compiler arguments.
  
  ls-decl <decl_file>
    | Pretty-prints all of the raw declarations in a decl file.
  
  newbind <decl_file> <output_file>
    | Generates a default bindmap file from the decl file
  
  filter <decl_file> <bind_file> <filter> ...
    | Filters bindmap files using one of the built-in filters, see below.
""";

void main(List<String> args) async {

}