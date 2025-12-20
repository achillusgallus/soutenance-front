import 'package:flutter/material.dart';

class ClassDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?>? onChanged;

  const ClassDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Classe',
        prefixIcon: const Icon(
          Icons.school_outlined,
          color: Colors.blueAccent,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
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
