import 'dart:io';

import 'package:yaml/yaml.dart';

// --------------------------------------------------------------------------------

class Value {
  Value({this.env, this.string});
  Environment env;
  String string;

  bool get isEnvironment {
    return env != null;
  }

  @override
  String toString() {
    if (env != null) {
      return env.toString();
    }
    return string;
  }
}

// --------------------------------------------------------------------------------

class Environment {
  Environment({this.parent, this.name});

  final Environment parent;
  final Map<String, Value> values = {};
  final String name;
  String get path {
    if (parent != null && parent.name != null) {
      return parent.path + '.' + name;
    } else {
      return name;
    }
  }

  static Environment parse({Environment parent, YamlMap node, String name}) {
    final env = Environment(parent: parent, name: name);
    node.forEach((key, value) {
      if (value is YamlMap) {
        env.values[key] =
            Value(env: Environment.parse(parent: env, node: value, name: key));
      } else {
        env.values[key] = Value(string: value.toString());
      }
    });
    return env;
  }

  String toStringWithIndent({String indent = ''}) {
    var str = '{\n';
    final indent2 = indent + '  ';
    values.forEach((key, value) {
      if (value.isEnvironment) {
        str += '$indent2$key: ';
        str += value.env.toStringWithIndent(indent: indent2);
      } else {
        str += '$indent2$key: "${value.toString().replaceAll('"', '\\"')}",\n';
      }
    });
    if (name != null) {
      str += '$indent} // $path\n';
    } else {
      str += '$indent}\n';
    }
    return str;
  }

  @override
  String toString() {
    return toStringWithIndent();
  }
}

// --------------------------------------------------------------------------------

class Section {
  Map<String, String> _header;
  final List<dynamic> _body = [];

  static List<dynamic> parse(String content) {
    final lines = content.split('\n');
    return Section.parseLines(lines)._body;
  }

  static Section parseLines(List<String> lines) {
    final section = Section();
    final sectionStack = <Section>[section];
    lines.forEach((line) {
      if (line.contains('%%end%%')) {
        sectionStack.removeLast(); // pop section
      } else if (line.contains('%%')) {
        final section = Section();
        section._header = <String, String>{};
        line.replaceAll('%%', '').split(';').forEach((item) {
          final i = item.split(':');
          if (i.length == 1) {
            section._header[i.first] = 'true';
          } else if (i.length == 2) {
            section._header[i[0]] = i[1];
          }
        });
        sectionStack.last?._body?.add(section);
        sectionStack.add(section); // push new section
      } else {
        sectionStack.last?._body?.add(line);
      }
    });
    return section;
  }
}

void dumpTemplate(Environment env, List<dynamic> template,
    {String indent = ''}) {
  template.forEach((item) {
    if (item is Section) {
      switch (item._header.entries.first.key) {
        case 'foreach': // %%foreach:key%%
          if (env.values[item._header.entries.first.value] != null &&
              env.values[item._header.entries.first.value].isEnvironment) {
            env.values[item._header.entries.first.value].env.values
                .forEach((key, value) {
              if (value.isEnvironment) {
                dumpTemplate(value.env, item._body, indent: indent + '....');
              } else {
                final valueEnv = Environment(
                    parent: env.values[item._header.entries.first.value].env,
                    name: key);
                valueEnv.values['^value'] = value;
                dumpTemplate(valueEnv, item._body, indent: indent + '....');
              }
            });
          }
          break;
        default: // %%key:value%%
          env.values.forEach((key, value) {
            if (value.isEnvironment &&
                value.env.values[item._header.entries.first.key]?.string ==
                    item._header.entries.first.value) {
              dumpTemplate(value.env, item._body, indent: indent + '....');
            }
          });
      }
    } else {
      final line = expandLine(env, item);
      if (line != null) {
        print(indent + line);
      }
    }
  });
}

String expandLine(Environment env, String line) {
  final exp = RegExp(r'\${[\^a-zA-Z0-9_\.]*}');
  bool repeat;
  do {
    repeat = false;
    final match = exp.firstMatch(line);
    if (match != null) {
      final reference = line.substring(match.start + 2, match.end - 1);
      var path = reference.split('.');
      while (path.length > 1) {
        env = env.values[path.first].env;
        path.removeAt(0);
      }
      if (path.first == '^name') {
        line = line.replaceRange(match.start, match.end, env.name);
        repeat = true;
      } else if (path.first == '^path') {
        line = line.replaceRange(match.start, match.end, env.path);
        repeat = true;
      } else {
        if (env.values[path.first] != null && !env.values[path.first].isEnvironment) {
          line = line.replaceRange(
              match.start, match.end, env.values[path.first].string ?? '');
          repeat = true;
        } else {
          line = null;          
        }
      }
    }
  } while (repeat);
  return line;
}

// --------------------------------------------------------------------------------

// class SectionX {
//   Map<String, String> _header;
//   final List<dynamic> _body = [];

//   void dump(
//       {YamlMap global,
//       YamlMap local,
//       String path,
//       String name,
//       String indent = ''}) {
//     //print(path);
//     if (_header != null) {
//       //print('$_header');
//       if (_header['indent'] != null) {
//         indent = indent + _header['indent'];
//       }
//       String delimiter;
//       local.forEach((key, node) {
//         if (node is YamlMap) {
//           //print('$node');
//           ifprint('${validate(global: global, local: node, name: key)}');
//           // %%foreach:node%%
//           if (_header.entries.first.key == 'foreach') {
//             var node = local[_header.entries.first.value];
//             if (node is YamlMap) {
//               print('------>>');
//               node.forEach((key, value) {
//                 print('$key $value');
//               });
//               print('------>>');
//             }
//             // %%field:value%%
//           } else if (node[_header.entries.first.key] == _header.entries.first.value &&
//               validate(global: global, local: node, name: key)) {
//             if (delimiter != null) {
//               final line = expandLine(global, local, key, delimiter);
//               print('$indent$line');
//             }
//             _body.forEach((item) {
//               if (item is Section) {
//                 item.dump(
//                     global: global,
//                     local: node,
//                     path: '$path.$key',
//                     name: key,
//                     indent: indent);
//               } else {
//                 final line = expandLine(global, node, key, item);
//                 print('$indent$line');
//               }
//             });
//             delimiter = _header['delimiter'];
//           }
//         }
//       });
//     } else {
//       _body.forEach((item) {
//         if (item is Section) {
//           item.dump(
//               global: global,
//               local: local,
//               path: '$name',
//               name: name,
//               indent: indent);
//         } else {
//           if (validateLine(global, local, name, item)) {
//             final line = expandLine(global, local, name, item);
//             print('$indent$line');
//           }
//         }
//       });
//     }
//   }

//   bool validate({YamlMap global, String name, YamlMap local}) {
//     var validated = true;
//     _body.forEach((item) {
//       if (!(item is Section) && !validateLine(global, local, name, item)) {
//         validated = false;
//       }
//     });
//     return validated;
//   }

//   static Section parse(List<String> lines) {
//     final section = Section();
//     final sectionStack = <Section>[section];
//     lines.forEach((line) {
//       if (line.contains('%%end%%')) {
//         sectionStack.removeLast(); // pop section
//       } else if (line.contains('%%')) {
//         final section = Section();
//         section._header = <String, String>{};
//         line.replaceAll('%%', '').split(';').forEach((item) {
//           final i = item.split(':');
//           if (i.length == 1) {
//             section._header[i.first] = 'true';
//           } else if (i.length == 2) {
//             section._header[i[0]] = i[1];
//           }
//         });
//         sectionStack.last?._body?.add(section);
//         sectionStack.add(section); // push new section
//       } else {
//         sectionStack.last?._body?.add(line);
//       }
//     });
//     return section;
//   }

//   bool validateLine(YamlMap global, YamlMap local, String name, String line) {
//     final exp = RegExp(r'\${[\^a-zA-Z0-9_\.]*}');
//     bool repeat;
//     do {
//       repeat = false;
//       final match = exp.firstMatch(line);
//       if (match != null) {
//         final reference = line.substring(match.start + 2, match.end - 1);
//         var path = reference.split('.');
//         var env = local;
//         while (path.length > 1) {
//           env = env[path.first];
//           path.removeAt(0);
//         }
//         if (path.first == '^name' && name != null) {
//           line = line.replaceRange(match.start, match.end, name);
//           repeat = true;
//         } else if (env[path.first] != null) {
//           line = line.replaceRange(
//               match.start, match.end, env[path.first].toString());
//           repeat = true;
//         } else {
//           ifprint('$env');
//           ifprint('${path.first}');
//           return false;
//         }
//       }
//     } while (repeat);
//     return true;
//   }

//   String expandLine(YamlMap global, YamlMap local, String name, String line) {
//     final exp = RegExp(r'\${[\^a-zA-Z0-9_\.]*}');
//     bool repeat;
//     do {
//       repeat = false;
//       final match = exp.firstMatch(line);
//       if (match != null) {
//         final reference = line.substring(match.start + 2, match.end - 1);
//         var path = reference.split('.');
//         var env = local;
//         while (path.length > 1) {
//           env = env[path.first];
//           path.removeAt(0);
//         }
//         if (path.first == '^name' && name != null) {
//           line = line.replaceRange(match.start, match.end, name);
//           repeat = true;
//         } else {
//           line = line.replaceRange(
//               match.start, match.end, env[path.first].toString());
//           repeat = true;
//         }
//       }
//     } while (repeat);
//     return line;
//   }
// }

void main(List<String> arguments) async {
  if (arguments.length > 1) {
    try {
      final yamlContent = await File(arguments[1]).readAsString();
      final doc = loadYaml(yamlContent);
      final env = Environment.parse(node: doc);

      final templateContent = await File(arguments[0]).readAsString();
      final sections = Section.parse(templateContent);

      // print(env);
      // print(sections);

      dumpTemplate(env, sections);
    } catch (error) {
      print('Error: $error');
    }
  }
}
