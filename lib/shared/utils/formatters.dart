import 'package:flutter/services.dart';

// ── Máscara de telefone: (XX) XXXXX-XXXX ou (XX) XXXX-XXXX ───────────────────

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final masked = _maskPhone(digits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  static String _maskPhone(String digits) {
    if (digits.isEmpty) return '';
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (d.length == 11 && i == 7) buf.write('-');
      if (d.length <= 10 && i == 6) buf.write('-');
      buf.write(d[i]);
    }
    return buf.toString();
  }
}

/// Formata uma string raw (só dígitos ou já mascarada) para exibição.
String formatPhone(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return PhoneInputFormatter._maskPhone(digits);
}

// ── Máscara de CNPJ: XX.XXX.XXX/XXXX-XX ─────────────────────────────────────

class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final masked = _maskCnpj(digits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  static String _maskCnpj(String digits) {
    if (digits.isEmpty) return '';
    final d = digits.length > 14 ? digits.substring(0, 14) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('/');
      if (i == 12) buf.write('-');
      buf.write(d[i]);
    }
    return buf.toString();
  }
}

/// Formata uma string raw para exibição de CNPJ.
String formatCnpj(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return CnpjInputFormatter._maskCnpj(digits);
}

// ── Máscara CPF/CNPJ dinâmica ─────────────────────────────────────────────────
// Até 11 dígitos → CPF (XXX.XXX.XXX-XX); acima → CNPJ (XX.XXX.XXX/XXXX-XX)

class CpfCnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final masked = digits.length <= 11 ? _maskCpf(digits) : CnpjInputFormatter._maskCnpj(digits);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  static String _maskCpf(String digits) {
    if (digits.isEmpty) return '';
    final d = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(d[i]);
    }
    return buf.toString();
  }
}

/// Formata CPF ou CNPJ para exibição dependendo do número de dígitos.
String formatCpfCnpj(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  return digits.length <= 11
      ? CpfCnpjInputFormatter._maskCpf(digits)
      : CnpjInputFormatter._maskCnpj(digits);
}

// ── Máscara de placa: ABC-1234 (antiga) ou ABC-1D23 (Mercosul) ───────────────

class PlacaInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final masked = _formatPlaca(newValue.text);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  static String _formatPlaca(String raw) {
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    final d = clean.length > 7 ? clean.substring(0, 7) : clean;
    final buf = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 3) buf.write('-');
      buf.write(d[i]);
    }
    return buf.toString();
  }
}

/// Formata uma placa para exibição (ex: "ABC1234" → "ABC-1234").
String formatPlaca(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '';
  return PlacaInputFormatter._formatPlaca(raw);
}

/// Remove a máscara de placa (ex: "ABC-1234" → "ABC1234").
String stripPlaca(String? v) => v?.replaceAll('-', '').trim().toUpperCase() ?? '';

/// Remove todos os caracteres não numéricos (para enviar ao backend).
String stripMask(String? v) => v?.replaceAll(RegExp(r'\D'), '') ?? '';
