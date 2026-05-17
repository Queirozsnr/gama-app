import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/network/api_constants.dart';
import '../../oficinas/domain/oficina_model.dart';
import '../domain/item_os.dart';
import '../domain/ordem_servico_detalhe.dart';

Future<void> imprimirOs(OrdemServicoDetalhe os, OficinaModel? oficina) async {
  await Printing.layoutPdf(
    onLayout: (format) async => _buildPdf(format, os, oficina),
    name: 'OS-${os.id.toString().padLeft(6, '0')}',
  );
}

// ─── Build ────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildPdf(
  PdfPageFormat format,
  OrdemServicoDetalhe os,
  OficinaModel? oficina,
) async {
  final fontRegular = await PdfGoogleFonts.interRegular();
  final fontBold = await PdfGoogleFonts.interBold();
  final fontItalic = await PdfGoogleFonts.interItalic();
  final theme = pw.ThemeData.withFont(
    base: fontRegular,
    bold: fontBold,
    italic: fontItalic,
  );

  final doc = pw.Document();
  final color = _hexColor(oficina?.corPadrao) ?? PdfColors.blueGrey800;

  pw.MemoryImage? logo;
  final logoUrl = oficina?.logoUrl;
  if (logoUrl != null) {
    try {
      final res = await Dio().get<List<int>>(
        '$kBaseUrl$logoUrl',
        options: Options(responseType: ResponseType.bytes),
      );
      if (res.data != null) {
        logo = pw.MemoryImage(Uint8List.fromList(res.data!));
      }
    } catch (_) {}
  }

  final servicos = os.itens.where((i) => !i.isPeca).toList();
  final pecas = os.itens.where((i) => i.isPeca).toList();

  doc.addPage(pw.MultiPage(
    pageFormat: format,
    theme: theme,
    margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 28),
    header: (ctx) => _header(oficina, logo, color),
    footer: (ctx) => _footer(ctx, oficina, color),
    build: (ctx) => [
      _titleBand(os, color),
      pw.SizedBox(height: 10),
      _clientBlock(os, color),
      pw.SizedBox(height: 10),
      _sectionHeader('Informações básicas', color),
      pw.SizedBox(height: 6),
      _basicInfoGrid(os),
      pw.SizedBox(height: 10),
      if (servicos.isNotEmpty) ...[
        _sectionHeader('Serviços', color),
        pw.SizedBox(height: 6),
        _itemsTable(servicos, color),
        pw.SizedBox(height: 10),
      ],
      if (pecas.isNotEmpty) ...[
        _sectionHeader('Peças / Materiais', color),
        pw.SizedBox(height: 6),
        _itemsTable(pecas, color),
        pw.SizedBox(height: 10),
      ],
      _totals(os, color),
      pw.SizedBox(height: 10),
      if (os.formaPagamento != null || (os.observacoes?.isNotEmpty ?? false)) ...[
        _sectionHeader('Pagamento', color),
        pw.SizedBox(height: 6),
        _paymentContent(os),
        pw.SizedBox(height: 10),
      ],
      pw.SizedBox(height: 28),
      _signatures(os.clienteNome, color),
      pw.SizedBox(height: 20),
      _thankYou(),
    ],
  ));

  return doc.save();
}

// ─── Header (every page) ─────────────────────────────────────────────────────

pw.Widget _header(OficinaModel? oficina, pw.MemoryImage? logo, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      if (logo != null) ...[
        pw.Center(
          child: pw.Container(
            width: 80,
            height: 80,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
        ),
        pw.SizedBox(height: 4),
      ],
      pw.Center(
        child: pw.Text(
          oficina?.nome ?? 'Oficina',
          style: pw.TextStyle(
            fontSize: 15,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ),
      if (oficina?.endereco.isNotEmpty ?? false)
        pw.Center(
          child: pw.Text(
            oficina!.endereco,
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      pw.SizedBox(height: 8),
    ],
  );
}

// ─── Footer (every page) ─────────────────────────────────────────────────────

pw.Widget _footer(pw.Context ctx, OficinaModel? oficina, PdfColor color) {
  final grey =
      pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700);
  final bold = pw.TextStyle(
      fontSize: 7.5,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey800);

  // Ícone FontAwesome Brands (Instagram, WhatsApp)
  // Círculo genérico (fallback ou telefone/email)
  pw.Widget dotIcon(String letter, PdfColor bg) => pw.Container(
        width: 10,
        height: 10,
        decoration: pw.BoxDecoration(color: bg, shape: pw.BoxShape.circle),
        alignment: pw.Alignment.center,
        child: pw.Text(
          letter,
          style: pw.TextStyle(
              fontSize: 5.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white),
        ),
      );

  pw.Widget row(pw.Widget icon, String text,
      {String? url, PdfColor? textColor}) {
    final content = pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        icon,
        pw.SizedBox(width: 3),
        pw.Text(text,
            style: pw.TextStyle(
                fontSize: 7.5, color: textColor ?? PdfColors.grey700)),
      ],
    );
    return url != null ? pw.UrlLink(destination: url, child: content) : content;
  }

  return pw.Column(children: [
    pw.Divider(color: PdfColors.grey400, thickness: 0.5),
    pw.SizedBox(height: 4),
    pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (oficina != null) pw.Text(oficina.nome, style: bold),
              if (oficina?.cnpj != null)
                pw.Text('CNPJ: ${oficina!.cnpj!}', style: grey),
              if (oficina?.endereco.isNotEmpty ?? false)
                pw.Text(oficina!.endereco, style: grey),
              if (oficina?.instagram != null) ...[
                pw.SizedBox(height: 2),
                row(
                  dotIcon('@', color),
                  '@${oficina!.instagram!}',
                  url: 'https://instagram.com/${oficina.instagram}',
                  textColor: color,
                ),
              ],
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            if (oficina?.email != null)
              row(
                dotIcon('E', color),
                oficina!.email!,
                url: 'mailto:${oficina.email}',
                textColor: color,
              ),
            if (oficina != null && oficina.telefone.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              row(dotIcon('T', PdfColors.grey500), oficina.telefone),
            ],
            if (oficina?.telefone2 != null) ...[
              pw.SizedBox(height: 2),
              row(dotIcon('T', PdfColors.grey500), oficina!.telefone2!),
            ],
            if (oficina?.whatsapp != null) ...[
              pw.SizedBox(height: 2),
              row(
                dotIcon('W', color),
                oficina!.whatsapp!,
                url:
                    'https://wa.me/${oficina.whatsapp!.replaceAll(RegExp(r'\D'), '')}',
                textColor: color,
              ),
            ],
            pw.SizedBox(height: 4),
            pw.Text(
              'Página ${ctx.pageNumber}/${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    ),
  ]);
}

// ─── Title band ───────────────────────────────────────────────────────────────

pw.Widget _titleBand(OrdemServicoDetalhe os, PdfColor color) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    color: color,
    child: pw.Text(
      'Orçamento ${os.id.toString().padLeft(3, '0')}-${os.dataEntrada.year}',
      style: pw.TextStyle(
        color: PdfColors.white,
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );
}

// ─── Client block ─────────────────────────────────────────────────────────────

pw.Widget _clientBlock(OrdemServicoDetalhe os, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(
            text: 'Cliente: ',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
          pw.TextSpan(
            text: os.clienteNome,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ]),
      ),
      if (os.clienteTelefone != null) ...[
        pw.SizedBox(height: 2),
        pw.Text(
          os.clienteTelefone!,
          style: pw.TextStyle(fontSize: 8.5, color: color),
        ),
      ],
    ],
  );
}

// ─── Section header ───────────────────────────────────────────────────────────

pw.Widget _sectionHeader(String text, PdfColor color) {
  return pw.Container(
    width: double.infinity,
    color: PdfColors.grey200,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    ),
  );
}

// ─── Basic info grid ──────────────────────────────────────────────────────────

pw.Widget _basicInfoGrid(OrdemServicoDetalhe os) {
  final pairs = <(String, String)>[
    ('Data de entrada', _fmtDate(os.dataEntrada)),
    ('Veículo', os.veiculoDescricao),
    if (os.previsaoEntrega != null)
      ('Previsão de entrega', _fmtDate(os.previsaoEntrega)),
    if (os.veiculoPlaca != null) ('Placa', os.veiculoPlaca!),
  ];

  // two-column layout
  final rows = <pw.Widget>[];
  for (var i = 0; i < pairs.length; i += 2) {
    rows.add(
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(child: _infoCell(pairs[i].$1, pairs[i].$2)),
          if (i + 1 < pairs.length)
            pw.Expanded(child: _infoCell(pairs[i + 1].$1, pairs[i + 1].$2))
          else
            pw.Expanded(child: pw.SizedBox()),
        ],
      ),
    );
    rows.add(pw.SizedBox(height: 5));
  }
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: rows,
  );
}

pw.Widget _infoCell(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey700,
        ),
      ),
      pw.Text(value, style: pw.TextStyle(fontSize: 8.5)),
    ],
  );
}

// ─── Items table ──────────────────────────────────────────────────────────────

pw.Widget _itemsTable(List<ItemOs> itens, PdfColor color) {
  pw.Widget hCell(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700),
        textAlign: align,
      ),
    );
  }

  pw.Widget cell(String text,
      {pw.TextAlign align = pw.TextAlign.left, bool bold = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder(
      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
      horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
    ),
    columnWidths: const {
      0: pw.FlexColumnWidth(5),
      1: pw.FixedColumnWidth(52),
      2: pw.FixedColumnWidth(72),
      3: pw.FixedColumnWidth(36),
      4: pw.FixedColumnWidth(72),
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
        children: [
          hCell('Descrição'),
          hCell('Unidade', align: pw.TextAlign.center),
          hCell('Preço unitário', align: pw.TextAlign.right),
          hCell('Qtd.', align: pw.TextAlign.center),
          hCell('Preço', align: pw.TextAlign.right),
        ],
      ),
      ...itens.map((item) {
        final qtd = item.quantidade == item.quantidade.roundToDouble()
            ? item.quantidade.toInt().toString()
            : item.quantidade.toStringAsFixed(2);
        return pw.TableRow(children: [
          cell(item.descricao, bold: true),
          cell('un', align: pw.TextAlign.center),
          cell(_fmt(item.valorUnitario), align: pw.TextAlign.right),
          cell(qtd, align: pw.TextAlign.center),
          cell(_fmt(item.subtotal), align: pw.TextAlign.right),
        ]);
      }),
    ],
  );
}

// ─── Totals ───────────────────────────────────────────────────────────────────

pw.Widget _totals(OrdemServicoDetalhe os, PdfColor color) {
  final rows = <pw.Widget>[];

  void addRow(String label, String value, {bool isTotal = false}) {
    rows.add(
      pw.Container(
        color: isTotal ? color : null,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: isTotal ? 10 : 8.5,
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isTotal ? PdfColors.white : PdfColors.grey700,
              ),
            ),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isTotal ? 10 : 8.5,
                fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isTotal ? PdfColors.white : PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (os.totalServicos > 0) addRow('Serviços', _fmt(os.totalServicos));
  if (os.totalPecas > 0) addRow('Peças', _fmt(os.totalPecas));
  for (final d in os.descontos) {
    addRow(d.descricao, '- ${_fmt(d.valor)}');
  }
  addRow('Total', _fmt(os.total), isTotal: true);

  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Container(
      width: 220,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Column(children: rows),
    ),
  );
}

// ─── Payment / Observations ───────────────────────────────────────────────────

pw.Widget _paymentContent(OrdemServicoDetalhe os) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (os.formaPagamento != null)
        pw.Text(os.formaPagamento!, style: pw.TextStyle(fontSize: 8.5)),
      if (os.observacoes?.isNotEmpty ?? false) ...[
        if (os.formaPagamento != null) pw.SizedBox(height: 4),
        pw.Text('Observações:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
        pw.Text(os.observacoes!, style: pw.TextStyle(fontSize: 8.5)),
      ],
    ],
  );
}

// ─── Signatures ───────────────────────────────────────────────────────────────

pw.Widget _signatures(String clienteNome, PdfColor color) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
    children: [
      _sigLine('Responsável pela oficina', color),
      _sigLine(clienteNome, color),
    ],
  );
}

pw.Widget _sigLine(String label, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Container(width: 180, height: 0.5, color: PdfColors.grey600),
      pw.SizedBox(height: 4),
      pw.Text(
        label,
        style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
      ),
    ],
  );
}

// ─── Thank you ────────────────────────────────────────────────────────────────

pw.Widget _thankYou() {
  final now = DateTime.now();
  final date = '${now.day.toString().padLeft(2, '0')}/'
      '${now.month.toString().padLeft(2, '0')}/'
      '${now.year}';
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Center(
        child: pw.Text(
          'OBRIGADO PELA PREFERÊNCIA.',
          style: pw.TextStyle(
            fontSize: 9,
            fontStyle: pw.FontStyle.italic,
            color: PdfColors.grey600,
          ),
        ),
      ),
      pw.SizedBox(height: 6),
      pw.Center(
        child: pw.Text(
          date,
          style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        ),
      ),
    ],
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return 'R\$ $intPart,${parts[1]}';
}

String _fmtDate(DateTime? d) {
  if (d == null) return '-';
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

PdfColor? _hexColor(String? hex) {
  if (hex == null) return null;
  final h = hex.startsWith('#') ? hex.substring(1) : hex;
  if (h.length != 6) return null;
  try {
    return PdfColor(
      int.parse(h.substring(0, 2), radix: 16) / 255,
      int.parse(h.substring(2, 4), radix: 16) / 255,
      int.parse(h.substring(4, 6), radix: 16) / 255,
    );
  } catch (_) {
    return null;
  }
}
