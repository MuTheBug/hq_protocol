import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/field_spec.dart';
import '../theme.dart';
import 'common.dart';

/// محرّك نماذج عام: يرسم نموذجاً من [EntitySpec] ويعيد القيم كـ Map عند الحفظ.
class RecordFormScreen extends StatefulWidget {
  final EntitySpec spec;
  final Map<String, dynamic> initial;

  /// عنوان فرعي اختياري (مثل اسم الناجي).
  final String? subtitle;

  const RecordFormScreen({
    super.key,
    required this.spec,
    required this.initial,
    this.subtitle,
  });

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _values = {};

  bool _isText(FieldType t) =>
      t == FieldType.text ||
      t == FieldType.multiline ||
      t == FieldType.integer ||
      t == FieldType.decimal;

  @override
  void initState() {
    super.initState();
    for (final f in widget.spec.fields) {
      final v = widget.initial[f.key];
      if (_isText(f.type)) {
        _controllers[f.key] =
            TextEditingController(text: v == null ? '' : v.toString());
      } else if (f.type == FieldType.boolean) {
        _values[f.key] = v == true;
      } else if (f.type == FieldType.multiChoice) {
        _values[f.key] =
            (v is List) ? v.map((e) => e.toString()).toList() : <String>[];
      } else {
        // choice أو date
        _values[f.key] =
            (v == null || (v is String && v.isEmpty)) ? null : v.toString();
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final textOk = _formKey.currentState?.validate() ?? true;
    final missing = <String>[];
    for (final f in widget.spec.fields) {
      if (!f.required) continue;
      if (f.type == FieldType.choice || f.type == FieldType.date) {
        final v = _values[f.key];
        if (v == null || (v is String && v.isEmpty)) missing.add(f.label);
      } else if (f.type == FieldType.multiChoice) {
        if ((_values[f.key] as List).isEmpty) missing.add(f.label);
      }
    }
    if (!textOk || missing.isNotEmpty) {
      final msg = missing.isNotEmpty
          ? 'يرجى إكمال الحقول المطلوبة: ${missing.join('، ')}'
          : 'يرجى تصحيح الحقول المطلوبة';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    final result = <String, dynamic>{};
    for (final f in widget.spec.fields) {
      switch (f.type) {
        case FieldType.text:
        case FieldType.multiline:
          result[f.key] = _controllers[f.key]!.text.trim();
          break;
        case FieldType.integer:
          final t = _controllers[f.key]!.text.trim();
          result[f.key] = t.isEmpty ? null : int.tryParse(t);
          break;
        case FieldType.decimal:
          final t = _controllers[f.key]!.text.trim();
          result[f.key] = t.isEmpty ? null : double.tryParse(t);
          break;
        case FieldType.boolean:
          result[f.key] = _values[f.key] == true;
          break;
        case FieldType.date:
          result[f.key] = _values[f.key];
          break;
        case FieldType.choice:
          result[f.key] = _values[f.key] ?? '';
          break;
        case FieldType.multiChoice:
          result[f.key] = List<String>.from(_values[f.key] as List);
          break;
      }
    }
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.spec.sections;
    final showHeaders = sections.length > 1;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(widget.spec.titleAr),
            if (widget.subtitle != null)
              Text(widget.subtitle!,
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
              onPressed: _save,
              icon: const Icon(Icons.check),
              tooltip: 'حفظ'),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final section in sections) ...[
              if (showHeaders) SectionTitle(section),
              for (final f in widget.spec.fieldsInSection(section))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _buildField(f),
                ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('حفظ'),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildField(FieldSpec f) {
    switch (f.type) {
      case FieldType.text:
        return _textField(f, multiline: false);
      case FieldType.multiline:
        return _textField(f, multiline: true);
      case FieldType.integer:
        return _numberField(f, decimal: false);
      case FieldType.decimal:
        return _numberField(f, decimal: true);
      case FieldType.boolean:
        return _switchField(f);
      case FieldType.date:
        return _dateField(f);
      case FieldType.choice:
        return _choiceField(f);
      case FieldType.multiChoice:
        return _multiChoiceField(f);
    }
  }

  String _labelText(FieldSpec f) => f.required ? '${f.label} *' : f.label;

  Widget _textField(FieldSpec f, {required bool multiline}) {
    return TextFormField(
      controller: _controllers[f.key],
      maxLines: multiline ? 5 : 1,
      minLines: multiline ? 3 : 1,
      textInputAction:
          multiline ? TextInputAction.newline : TextInputAction.next,
      decoration: InputDecoration(
        labelText: _labelText(f),
        helperText: f.help,
        alignLabelWithHint: multiline,
      ),
      validator: f.required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _numberField(FieldSpec f, {required bool decimal}) {
    return TextFormField(
      controller: _controllers[f.key],
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      inputFormatters: [
        if (decimal)
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(
        labelText: _labelText(f),
        helperText: f.help,
      ),
      validator: f.required
          ? (v) => (v == null || v.trim().isEmpty) ? 'هذا الحقل مطلوب' : null
          : null,
    );
  }

  Widget _switchField(FieldSpec f) {
    return SwitchListTile(
      title: Text(f.label),
      subtitle: f.help != null ? Text(f.help!) : null,
      value: _values[f.key] == true,
      activeColor: HaqqunaColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (v) => setState(() => _values[f.key] = v),
    );
  }

  Widget _dateField(FieldSpec f) {
    final v = _values[f.key] as String?;
    final empty = v == null || v.isEmpty;
    return InkWell(
      onTap: () async {
        final initial = _parseDate(v) ?? DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(1920),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _values[f.key] = _fmt(picked));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: _labelText(f),
          helperText: f.help,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          empty ? 'اضغط لاختيار التاريخ' : v,
          style: TextStyle(color: empty ? Colors.grey : null),
        ),
      ),
    );
  }

  Widget _choiceField(FieldSpec f) {
    final current = _values[f.key] as String?;
    final items = <DropdownMenuItem<String>>[];
    final known = <String>{};
    for (final c in f.choices) {
      known.add(c.value);
      items.add(DropdownMenuItem(
        value: c.value,
        child: Text(c.label, overflow: TextOverflow.ellipsis),
      ));
    }
    if (current != null && current.isNotEmpty && !known.contains(current)) {
      items.insert(
          0, DropdownMenuItem(value: current, child: Text(current)));
    }
    return DropdownButtonFormField<String>(
      value: (current == null || current.isEmpty) ? null : current,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: _labelText(f),
        helperText: f.help,
      ),
      items: items,
      onChanged: (v) => setState(() => _values[f.key] = v),
    );
  }

  Widget _multiChoiceField(FieldSpec f) {
    final selected = List<String>.from(_values[f.key] as List);
    return Card(
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        title: Text(_labelText(f)),
        subtitle: Text('${selected.length} مُحدَّد'),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final c in f.choices)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: HaqqunaColors.primary,
              title: Text(c.label),
              value: selected.contains(c.value),
              onChanged: (checked) {
                setState(() {
                  final list = List<String>.from(_values[f.key] as List);
                  if (checked == true) {
                    if (!list.contains(c.value)) list.add(c.value);
                  } else {
                    list.remove(c.value);
                  }
                  _values[f.key] = list;
                });
              },
            ),
        ],
      ),
    );
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  String _fmt(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }
}
