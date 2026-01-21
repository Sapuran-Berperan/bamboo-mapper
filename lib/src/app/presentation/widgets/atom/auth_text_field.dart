import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final String label;
  final bool optional;
  final TextInputType type;
  final double width;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    this.hintText = '',
    this.label = '',
    this.optional = false,
    this.type = TextInputType.text,
    this.width = 0.8,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  final _formKey = GlobalKey<FormFieldState>();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width.sw,
      child: TextFormField(
        key: _formKey,
        keyboardType: widget.type,
        controller: widget.controller,
        style: const TextStyle(
          color: Color(0xFF1E1E1E),
          fontSize: 14,
        ),
        decoration: InputDecoration(
          focusColor: Colors.red,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 0.03.sw,
            vertical: 0.015.sh,
          ),
          hintText: widget.hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 14,
          ),
          labelText: null,
          label: RichText(
            text: TextSpan(
              text: widget.label,
              style: const TextStyle(
                color: Color(0xFF616161),
                fontSize: 14,
              ),
              children: [
                if (!widget.optional)
                  const TextSpan(
                    text: ' (*)',
                    style: TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          labelStyle: const TextStyle(
            color: Color(0xFF616161),
            fontSize: 14,
          ),
          filled: true,
          fillColor: const Color(0xFFF5F5F5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: Colors.transparent),
          ),
        ),
        validator: widget.validator,
        onChanged: (value) {
          _formKey.currentState?.validate();
        },
        maxLines: null,
        minLines: 1,
      ),
    );
  }
}
