// This file was generated with 'yamlt'
// Datetime: ${^date}
// Template: ${^templateFile}
//     YAML: ${^yamlFile}

import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

Future<Database> _database() async {
  final Database db = await openDatabase(
    join(await getDatabasesPath(), 'database.db'),
    onCreate: (db, version) async {
%%type:object%%
      await db.execute(
        'CREATE TABLE ${^name}(id INTEGER PRIMARY KEY%%foreach:columns;oneline%%
, ${^name} ${.sql_type.${^value}}
%%end%%
)',
      );
%%end%%
    },
    version: 1,
  );
  return db;
}

Future<Database> database = _database();

%%type:object%%
Future<void> insert${^name}(${^name} item) async {
  final Database db = await database;

  await db.insert(
    '${^name}',
    item.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<int> new${^name}(%%foreach:columns;oneline%%
${.dart_type.${^value}} ${^name}, 
%%end%%
) async {
  final Database db = await database;

  return db.insert(
    '${^name}',
    {
%%foreach:columns%%
        '${^name}': ${^name},
%%end%%
    },
  );
}

Future<List<${^name}>> all${^name}() async {
  final Database db = await database;

  final List<Map<String, dynamic>> maps = await db.query('${^name}');

  return List.generate(maps.length, (i) {
    return ${^name}(
      id: maps[i]['id'],
%%foreach:columns%%
      ${^name}: maps[i]['${^name}'],
%%end%%
    );
  });
}

Future<void> update${^name}(${^name} item) async {
  final db = await database;

  await db.update(
    '${^name}',
    item.toMap(),
    where: "id = ?",
    whereArgs: [item.id],
  );
}

Future<void> delete${^name}(int id) async {
  final db = await database;

  await db.delete(
    '${^name}',
    where: "id = ?",
    whereArgs: [id],
  );
}
%%end%%

Future<void> deleteDatabase() async {
  try {
    final path = join(await getDatabasesPath(), 'database.db');
    await File(path).delete();
  } catch (e) {}
}

Future<void> newDatabase() async {
  final db = await database;
  await db.close();
  await deleteDatabase();
  database = _database();
}
%%type:object%%

class ${^name} {
  final int id;
%%foreach:columns%%
  final ${.dart_type.${^value}} ${^name};
%%end%%

  ${^name}({this.id%%foreach:columns;oneline%%
, this.${^name}
%%end%%
});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
%%foreach:columns%%
      '${^name}': ${^name},
%%end%%
    };
  }
}
%%end%%
