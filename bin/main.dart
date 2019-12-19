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

  var _nextId = 1;

  int _id;
  int get id {
    if (_id == null) {
      var r = root;
      _id = r._nextId++;
    }
    return _id;
  }

  Environment get root {
    return parent == null ? this : parent.root;
  }

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
      } else if (value is YamlList) {
        final listEnv = Environment(parent: env, name: key);
        var index = 0;
        env.values[key] = Value(env: listEnv);
        value.forEach((item) {
          listEnv.values[index.toString()] = Value(string: item.toString());
          index += 1;
        });
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

const _onelineTag = '411FD25C-ABBB-4668-AC59-592DEC99386F';

class Macros {
  final Map<String, Section> _macros = {};
  Section operator [](String key) {
    return _macros[key];
  }

  operator []=(String key, Section section) {
    _macros[key] = section;
  }
}

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
    final macros = Macros();
    section._body.add(macros);
    lines.forEach((line) {
      if (line.contains('%%end%%')) {
        sectionStack.removeLast(); // pop section
      } else if (line.contains('%%')) {
        final first = line.indexOf('%%');
        if (first > 0) {
          sectionStack.last?._body?.add(line.substring(0, first) + _onelineTag);
          line = line.substring(first);
        }
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
        if (section._header.entries.first.key == 'define') {
          macros[section._header.entries.first.value] = section;
          sectionStack.add(section); // push new section
        } else if (section._header.entries.first.key == 'macro') {
          sectionStack.last?._body?.add(section);
        } else {
          sectionStack.last?._body?.add(section);
          sectionStack.add(section); // push new section
        }
      } else {
        sectionStack.last?._body?.add(line);
      }
    });
    return section;
  }
}

// --------------------------------------------------------------------------------

void _printLine(bool oneline, String indent, String line) {
  if (line != null) {
    if (oneline) {
      stdout.write(line);
    } else if (line.contains(_onelineTag)) {
      stdout.write(line.replaceAll(_onelineTag, ''));
    } else {
      print(indent + line);
    }
  }
}

void dumpTemplate(Environment env, List<dynamic> template,
    {String indent = '', Macros macros, bool oneline = false}) {
  template.forEach((item) {
    if (item is Macros) {
      macros = item;
    } else if (item is Section) {
      var newindent = indent + (item._header['indent'] ?? '');
      var oneline = item._header['oneline'] == 'true';
      String delimiter;
      switch (item._header.entries.first.key) {
        case 'foreach': // %%foreach:key%%
          final foreachKey = expandLine(env, item._header.entries.first.value);
          if (env.values[foreachKey] != null &&
              env.values[foreachKey].isEnvironment) {
            env.values[foreachKey].env.values.forEach((key, value) {
              if (delimiter != null) {
                final line = expandLine(env, delimiter);
                _printLine(oneline, indent, line);
              } else {
                delimiter = item._header['delimiter'];
              }
              if (value.isEnvironment) {
                dumpTemplate(value.env, item._body,
                    indent: newindent, macros: macros, oneline: oneline);
              } else {
                final valueEnv =
                    Environment(parent: env.values[foreachKey].env, name: key);
                valueEnv.values['^value'] = value;
                dumpTemplate(valueEnv, item._body,
                    indent: newindent, macros: macros, oneline: oneline);
              }
            });
          }
          break;
        case 'macro': // %%macro:nnn%%
          final foreachKey = expandLine(env, item._header.entries.first.value);
          final section = macros[foreachKey];
          if (section != null) {
            dumpTemplate(env, section._body, indent: indent, macros: macros);
          }
          break;
        default: // %%key:value%%
          env.values.forEach((key, value) {
            if (value.isEnvironment &&
                value.env.values[item._header.entries.first.key]?.string ==
                    item._header.entries.first.value) {
              if (delimiter != null) {
                final line = expandLine(value.env, delimiter);
                _printLine(oneline, indent, line);
              } else {
                delimiter = item._header['delimiter'];
              }
              dumpTemplate(value.env, item._body,
                  indent: newindent, macros: macros, oneline: oneline);
            }
          });
      }
    } else {
      final line = expandLine(env, item);
      _printLine(oneline, indent, line);
    }
  });
}

String expandLine(Environment env, String line) {
  final exp = RegExp(r'\${[\^a-zA-Z0-9_\.]*}');
  var previousEnv = env;
  bool repeat;
  do {
    env = previousEnv;
    repeat = false;
    final match = exp.firstMatch(line);
    if (match != null) {
      final reference = line.substring(match.start + 2, match.end - 1);
      var path = reference.split('.');
      if (path.length > 1 && path.first == '') {
        previousEnv = env;
        env = env.root;
        path.removeAt(0);
      }
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
      } else if (path.first == '^id') {
        line = line.replaceRange(match.start, match.end, env.id.toString());
        repeat = true;
      } else {
        if (env.values[path.first] != null &&
            !env.values[path.first].isEnvironment) {
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
