import 'package:flutter/material.dart';

class ClassDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;

  const ClassDropdown({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'classe',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      initialValue: value,
      items: [
        DropdownMenuItem(value: 'tle_D', child: Text('tle_D')),
        DropdownMenuItem(value: 'tle_A4', child: Text('tle_A4')),
        DropdownMenuItem(value: 'tle_C', child: Text('tle_C')),
        DropdownMenuItem(value: 'pre_D', child: Text('pre_D')),
        DropdownMenuItem(value: 'pre_A4', child: Text('pre_A4')),
        DropdownMenuItem(value: 'pre_C', child: Text('pre_C')),
        DropdownMenuItem(value: 'troisieme', child: Text('troisieme')),
      ],
      onChanged: onChanged,
    );
  }
}
