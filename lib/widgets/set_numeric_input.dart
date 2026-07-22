import 'package:flutter/material.dart';

class SetNumericInput extends StatefulWidget {
  final double initialValue;
  final String suffix;
  final bool isDecimal;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const SetNumericInput({
    super.key,
    required this.initialValue,
    this.suffix = '',
    this.isDecimal = true,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  State<SetNumericInput> createState() => _SetNumericInputState();
}

class _SetNumericInputState extends State<SetNumericInput> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: _formatValue(widget.initialValue));
    _focusNode.addListener(_onFocusChange);
  }

  String _formatValue(double val) {
    if (!widget.isDecimal) {
      return val.toInt().toString();
    }
    if (val == val.toInt()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      final parsed = double.tryParse(_controller.text.replaceAll(',', '.')) ?? widget.initialValue;
      _controller.text = _formatValue(parsed);
      widget.onChanged(parsed);
    } else {
      // Select all text on tap to allow fast replacement
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(SetNumericInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.initialValue != widget.initialValue) {
      _controller.text = _formatValue(widget.initialValue);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: widget.enabled ? const Color(0xff2d2d34) : Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _focusNode.hasFocus
              ? const Color(0xff2563eb)
              : (widget.enabled ? const Color(0xff3f3f46) : Colors.transparent),
          width: _focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 32, maxWidth: 54),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.numberWithOptions(
                  decimal: widget.isDecimal,
                  signed: false,
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: widget.enabled ? Colors.white : Colors.grey[500],
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val.replaceAll(',', '.')) ?? 0.0;
                  widget.onChanged(parsed);
                },
              ),
            ),
            if (widget.suffix.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Text(
                  widget.suffix,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: widget.enabled ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
