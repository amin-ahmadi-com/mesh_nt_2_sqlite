import 'dart:io';

import 'package:sqlite3/sqlite3.dart' as sqlite3_lib;

class DbManager {
  final String outputDbName;

  late sqlite3_lib.Database _db;
  late final sqlite3_lib.Database _backupDb =
      sqlite3_lib.sqlite3.open(outputDbName);

  late final _insertOrReplaceIntoParamsStatement = _db.prepare(""
      "INSERT OR REPLACE INTO params "
      "(param, value) "
      "VALUES "
      "(?,?)");

  DbManager(this.outputDbName) {
    if (File(outputDbName).existsSync()) {
      _db = sqlite3_lib.sqlite3
          .copyIntoMemory(sqlite3_lib.sqlite3.open(outputDbName));
    } else {
      _db = sqlite3_lib.sqlite3.openInMemory();
    }

    _db.execute(
      "CREATE TABLE IF NOT EXISTS params"
      "("
      "param TEXT PRIMARY KEY,"
      "value TEXT"
      ")",
    );
  }

  void insertOrReplaceParam(String param, String value) {
    _insertOrReplaceIntoParamsStatement.execute([param, value]);
  }

  String? getParamValue(String param) {
    final statement = _db.prepare("SELECT * FROM params WHERE param = ?");
    final result = statement.select([param]);
    statement.dispose();
    return result.isEmpty ? null : result.first["value"];
  }

  void dispose() {
    _insertOrReplaceIntoParamsStatement.dispose();
    _db.dispose();
    _backupDb.dispose();
  }

  void save() {
    _db.backup(_backupDb).drain();
  }

  sqlite3_lib.Database get db => _db;
}
