import 'package:flutter/material.dart';
import '../utils/tts_helper.dart';

class InstructionTts extends StatefulWidget {
  final String text;
  final bool enabled;

  const InstructionTts({Key? key, required this.text, this.enabled = true})
    : super(key: key);

  @override
  State<InstructionTts> createState() => _InstructionTtsState();
}

class _InstructionTtsState extends State<InstructionTts> {
  final _tts = TtsHelper.instance;
  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _tts.speakFrFemale(widget.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
