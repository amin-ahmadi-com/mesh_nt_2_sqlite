import 'package:flutter/material.dart';

class ProgressWithLabelsWidget extends StatelessWidget {
  final double? value;
  final List<String> labels;

  const ProgressWithLabelsWidget(this.value, this.labels, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
            CircularProgressIndicator(value: value),
            const SizedBox(height: 25),
          ] +
          labels.map((e) => Text(e)).toList(),
    );
  }
}
