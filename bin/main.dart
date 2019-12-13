import 'dart:io';

import 'package:yaml/yaml.dart';

class Section {
  Map<String, String> sectionInfo;
  List<dynamic> sequence = [];

  void dump({YamlMap global, String name, YamlMap local, String indent = ''}) {
    if (sectionInfo != null) {
      //print('$indent$sectionInfo');
      local.forEach((key, node) {
        if (node is YamlMap) {
          if (node[sectionInfo.entries.first.key] ==
              sectionInfo.entries.first.value) {
            sequence.forEach((item) {
              if (item is Section) {
                item.dump(global: global, name: key, local: node, indent: indent + '……');
              } else {
                final line = expandLine(global, node, item);
                print('$indent$line');
              }
            });
          }
        }
      });
    } else {
      sequence.forEach((item) {
        if (item is Section) {
          item.dump(global: global, local: local, indent: indent + '……');
        } else {
          final line = expandLine(global, local, item);
          print('$indent$line');
        }
      });
    }
  }

  static Section parse(List<String> lines) {
    final section = Section();
    final sectionStack = <Section>[section];
    lines.forEach((line) {
      if (line.contains('%%end%%')) {
        sectionStack.removeLast(); // pop section
      } else if (line.contains('%%')) {
        final section = Section();
        section.sectionInfo = <String, String>{};
        line.replaceAll('%%', '').split(';').forEach((item) {
          final i = item.split(':');
          if (i.length == 1) {
            section.sectionInfo[i.first] = 'true';
          } else if (i.length == 2) {
            section.sectionInfo[i[0]] = i[1];
          }
        });
        sectionStack.last?.sequence?.add(section);
        sectionStack.add(section); // push new section
      } else {
        sectionStack.last?.sequence?.add(line);
      }
    });
    return section;
  }

  String expandLine(YamlMap global, YamlMap local, String line) {
    final exp = RegExp(r'\${[a-zA-Z0-9_\.]*}');
    bool repeat;
    do {
      repeat = false;
      final match = exp.firstMatch(line);
      if (match != null) {
        final reference = line.substring(match.start + 2, match.end - 1);
        var path = reference.split('.');
        var env = local;
        while (path.length > 1) {
          env = env[path.first];
          path.removeAt(0);
        }
        line = line.replaceRange(
            match.start, match.end, env[path.first].toString());
        repeat = true;
      }
    } while (repeat);
    return line;
  }
}

void main(List<String> arguments) async {
  if (arguments.length > 1) {
    try {
      final yamlContent = await File(arguments[1]).readAsString();
      final templateContent = await File(arguments[0]).readAsString();
      final doc = loadYaml(yamlContent);
      (doc as YamlMap).forEach((key, value) {
        if (value is YamlMap) {
          //_rootNode(key, value);
        }
      });
      final sections = _parseTemplate(templateContent);
      sections.dump(local: doc);
    } catch (error) {
      print('Error: $error');
    }
  }
}

void _rootNode(String name, YamlMap map) {
  print('Name: $name');
  print(map.runtimeType);
  switch (map['type']) {
    case 'object':
      print('type: object');
      break;
    default:
      print('unkonwn type');
  }
}

Section _parseTemplate(String content) {
  final lines = content.split('\n');
  return Section.parse(lines);
}
