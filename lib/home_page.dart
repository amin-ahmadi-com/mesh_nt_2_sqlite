import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mesh_nt_2_sqlite/db_manager.dart';
import 'package:mesh_nt_2_sqlite/progress_with_labels_widget.dart';
import 'package:mesh_nt_2_sqlite/rate_per_sec_calculator.dart';
import 'package:n_triples_db/n_triples_db.dart';
import 'package:n_triples_parser/n_triples_parser.dart';

import 'definitions.dart';
import 'dialog_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum ProcessType {
  none,
  download,
  convert,
}

class _HomePageState extends State<HomePage> {
  final dbMan = DbManager("./data.db");

  var processType = ProcessType.none;
  String progressMessage = "";
  double progress = 0.0;

  final errorFile = File("./errors.log");

  String parsedPerSecMessage = "";
  late final rpsCalc = RatePerSecCalculator((rate) {
    if (rate > 0) {
      setState(() {
        parsedPerSecMessage =
            "Approximately $rate N-Triples parsed per second.";
      });
    } else {
      setState(() {
        parsedPerSecMessage = "";
      });
    }
  });

  Widget get drawer {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_circle, size: 75),
                Text("$applicationName v$applicationVersion"),
              ],
            ),
          ),
          ListTile(
            leading: processType == ProcessType.download
                ? const CircularProgressIndicator()
                : const Icon(Icons.download),
            title: const Text("Download"),
            onTap: download,
          ),
          ListTile(
            leading: processType == ProcessType.convert
                ? const CircularProgressIndicator()
                : const Icon(Icons.refresh),
            title: const Text("Convert"),
            onTap: convert,
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text("About"),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: applicationName,
              applicationVersion: applicationVersion,
              applicationLegalese: applicationLegalese,
            ),
          ),
        ],
      ),
    );
  }

  Widget get mainArea {
    return Expanded(
      child: ProgressWithLabelsWidget(
        processType == ProcessType.download ? null : progress,
        [progressMessage, parsedPerSecMessage],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    dbMan.dispose();
    super.dispose();
  }

  void convert() async {
    if (processType == ProcessType.convert) return;

    setState(() {
      processType = ProcessType.convert;
      progress = 0.0;
      progressMessage = "Starting to parse";
    });

    String? startingIndex, saveInterval;

    if (mounted) {
      startingIndex = await DialogUtils.showTextInputDialog(
        context,
        "Starting Index",
        dbMan.getParamValue("last_parsed") == null
            ? "0"
            : dbMan.getParamValue("last_parsed")!,
      );
    }

    if (startingIndex == null) return;

    if (mounted) {
      saveInterval = await DialogUtils.showTextInputDialog(
        context,
        "Save Interval",
        "10000",
      );
    }

    if (saveInterval == null) return;
    int saveIntervalInt = int.parse(saveInterval);

    final tdb = NTriplesDb(dbMan.db);
    NTriplesParser.parseFile(
      r"./mesh.nt",
      onProgress: (i, total) {
        setState(() {
          rpsCalc.setCurrentProcessedIndex(i);
          progress = total != 0 ? i / total : 0.0;
          progressMessage = "Parsed $i of $total";
          dbMan.insertOrReplaceParam("last_parsed", i.toString());

          if (i % saveIntervalInt == 0) {
            dbMan.save();
          }
        });
      },
      onLineParsed: (nt) {
        tdb.insertNTriple(nt);
      },
      onParseError: (line, exception) {
        errorFile.writeAsStringSync(
          "${DateTime.now()} -> $line\n",
          mode: FileMode.writeOnlyAppend,
          flush: true,
        );
        errorFile.writeAsStringSync(
          "${DateTime.now()} -> ${exception.toString()}\n",
          mode: FileMode.writeOnlyAppend,
          flush: true,
        );
      },
      onFinished: () {
        if (mounted) {
          DialogUtils.showSnackBar(
            context,
            "Conversion completed!"
            "\n"
            "Saved as ./data.db",
            Colors.green,
          );
        }

        dbMan.save();

        setState(() {
          processType = ProcessType.none;
          progress = 0.0;
          progressMessage = "Parsing complete.";
        });
      },
      rethrowOnError: true,
      startingIndex: int.parse(startingIndex),
    );
  }

  void download() async {
    if (processType == ProcessType.download) return;

    setState(() {
      processType = ProcessType.download;
      progressMessage = "Downloading ...";
    });

    final url = await DialogUtils.showTextInputDialog(
      context,
      "MeSH *.nt download URL",
      "https://nlmpubs.nlm.nih.gov/projects/mesh/rdf/2022/mesh2022.nt",
    );

    if (url != null) {
      final response = await http.get(Uri.parse(url));
      await File("./mesh.nt").writeAsString(response.body);
      // To avoid `Do not use BuildContexts across async gaps.`, do a mounted check.
      if (mounted) {
        DialogUtils.showSnackBar(
          context,
          "Download completed!"
          "\n"
          "Saved as ./mesh.nt",
          Colors.green,
        );
      }

      setState(() {
        processType = ProcessType.none;
        progress = 0.0;
        progressMessage = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            drawer,
            mainArea,
          ],
        ),
      ),
    );
  }
}
