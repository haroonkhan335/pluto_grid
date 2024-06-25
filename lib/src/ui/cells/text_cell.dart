import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pluto_grid/pluto_grid.dart';

abstract class TextCell extends StatefulWidget {
  final PlutoGridStateManager stateManager;

  final PlutoCell cell;

  final PlutoColumn column;

  final PlutoRow row;

  const TextCell({
    required this.stateManager,
    required this.cell,
    required this.column,
    required this.row,
    super.key,
  });
}

abstract class TextFieldProps {
  TextInputType get keyboardType;

  List<TextInputFormatter>? get inputFormatters;
}

mixin TextCellState<T extends TextCell> on State<T> implements TextFieldProps {
  dynamic _initialCellValue;

  final _textController = TextEditingController();

  final PlutoDebounceByHashCode _debounce = PlutoDebounceByHashCode();

  late final FocusNode cellFocus;

  late _CellEditingStatus _cellEditingStatus;

  @override
  TextInputType get keyboardType => TextInputType.text;

  @override
  List<TextInputFormatter>? get inputFormatters => [];

  String get formattedValue =>
      widget.column.formattedValueForDisplayInEditing(widget.cell.value);

  @override
  void initState() {
    super.initState();

    widget.stateManager.setTextEditingController(_textController);

    _textController.text = formattedValue;

    _initialCellValue = _textController.text;

    _cellEditingStatus = _CellEditingStatus.init;

    _textController.addListener(() {
      _handleOnChanged(_textController.text.toString());
    });
  }

  @override
  void dispose() {
    /**
     * Saves the changed value when moving a cell while text is being input.
     * if user do not press enter key, onEditingComplete is not called and the value is not saved.
     */
    if (_cellEditingStatus.isChanged) {
      _changeValue();
    }

    if (!widget.stateManager.isEditing ||
        widget.stateManager.currentColumn?.enableEditingMode != true) {
      widget.stateManager.setTextEditingController(null);
    }

    _debounce.dispose();

    _textController.dispose();

    cellFocus.dispose();

    super.dispose();
  }

  void _changeValue() {
    if (formattedValue == _textController.text) {
      return;
    }

    widget.stateManager.changeCellValue(widget.cell, _textController.text);

    _textController.text = formattedValue;

    _initialCellValue = _textController.text;

    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: _textController.text.length),
    );

    _cellEditingStatus = _CellEditingStatus.updated;
  }

  void _handleOnChanged(String value) {
    _cellEditingStatus = formattedValue != value.toString()
        ? _CellEditingStatus.changed
        : _initialCellValue.toString() == value.toString()
            ? _CellEditingStatus.init
            : _CellEditingStatus.updated;
  }

  void _handleOnComplete() {
    final old = _textController.text;

    _changeValue();

    _handleOnChanged(old);
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: cellFocus,
      controller: _textController,
      readOnly: widget.column.checkReadOnly(widget.row, widget.cell),
      onChanged: _handleOnChanged,
      onEditingComplete: _handleOnComplete,
      onSubmitted: (_) => _handleOnComplete(),
      style: widget.stateManager.configuration.style.cellTextStyle,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.zero,
      ),
      maxLines: 1,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textAlignVertical: TextAlignVertical.center,
      textAlign: widget.column.textAlign.value,
    );
  }
}

enum _CellEditingStatus {
  init,
  changed,
  updated;

  bool get isNotChanged {
    return _CellEditingStatus.changed != this;
  }

  bool get isChanged {
    return _CellEditingStatus.changed == this;
  }

  bool get isUpdated {
    return _CellEditingStatus.updated == this;
  }
}
