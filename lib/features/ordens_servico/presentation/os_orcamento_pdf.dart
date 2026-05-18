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
    onLayout: (format) async => _buildPdf(format, os, oficina, isRecibo: false),
    name: 'OS-${os.id.toString().padLeft(6, '0')}',
  );
}

Future<void> gerarRecibo(OrdemServicoDetalhe os, OficinaModel? oficina) async {
  await Printing.layoutPdf(
    onLayout: (format) async => _buildRecibo(format, os, oficina),
    name: 'Recibo-OS-${os.id.toString().padLeft(6, '0')}',
  );
}

// ─── Build ────────────────────────────────────────────────────────────────────

Future<Uint8List> _buildPdf(
  PdfPageFormat format,
  OrdemServicoDetalhe os,
  OficinaModel? oficina, {
  required bool isRecibo,
}) async {
  final isPago = os.status == 'Entregue';
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
      _titleBand(os, color, isRecibo: isRecibo, isPago: isPago),
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
      _totals(os, color, isPago: isPago),
      pw.SizedBox(height: 10),
      if (isRecibo || os.formaPagamento != null || (os.observacoes?.isNotEmpty ?? false)) ...[
        _sectionHeader(isRecibo ? 'Pagamento' : 'Pagamento', color),
        pw.SizedBox(height: 6),
        _paymentContent(os, isRecibo: isRecibo),
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

// ─── Recibo ───────────────────────────────────────────────────────────────────

Future<Uint8List> _buildRecibo(
  PdfPageFormat format,
  OrdemServicoDetalhe os,
  OficinaModel? oficina,
) async {
  final isPago = os.status == 'Entregue';
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

  doc.addPage(pw.MultiPage(
    pageFormat: format,
    theme: theme,
    margin: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 28),
    header: (ctx) => _header(oficina, logo, color),
    footer: (ctx) => _footer(ctx, oficina, color),
    build: (ctx) => [
      _reciboTitle(os, color),
      pw.SizedBox(height: 18),
      _reciboClienteBox(os),
      pw.SizedBox(height: 14),
      _reciboValorBox(os, color, isPago),
      pw.SizedBox(height: 18),
      _reciboItens(os, color),
      pw.SizedBox(height: 14),
      _reciboInfoPagamento(os),
      pw.SizedBox(height: 24),
      if (isPago) ...[
        _pagoBadge(),
        pw.SizedBox(height: 24),
      ],
      _signatures(os.clienteNome, color),
      pw.SizedBox(height: 18),
      _thankYou(),
    ],
  ));

  return doc.save();
}

pw.Widget _reciboTitle(OrdemServicoDetalhe os, PdfColor color) {
  final numero = os.id.toString().padLeft(6, '0');
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.center,
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Divider(color: color, thickness: 1.5),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14),
            child: pw.Text(
              'RECIBO DE PAGAMENTO',
              style: pw.TextStyle(
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Divider(color: color, thickness: 1.5),
          ),
        ],
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        'N${String.fromCharCode(0xBA)} $numero',
        style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
      ),
    ],
  );
}

pw.Widget _reciboClienteBox(OrdemServicoDetalhe os) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey50,
      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
              text: 'Recebi do(a) Sr.(a):  ',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.TextSpan(
              text: os.clienteNome,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ]),
        ),
        if (os.clienteTelefone != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            'Telefone: ${os.clienteTelefone}',
            style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
          ),
        ],
        pw.SizedBox(height: 6),
        pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
              text: 'Veículo:  ',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.TextSpan(
              text: os.veiculoDescricao,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            ),
            if (os.veiculoPlaca != null)
              pw.TextSpan(
                text: '    Placa: ${os.veiculoPlaca}',
                style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
              ),
          ]),
        ),
      ],
    ),
  );
}

pw.Widget _reciboValorBox(
    OrdemServicoDetalhe os, PdfColor color, bool isPago) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(vertical: 20, horizontal: 24),
    decoration: pw.BoxDecoration(
      color: color,
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          isPago ? 'VALOR PAGO' : 'VALOR TOTAL',
          style: pw.TextStyle(fontSize: 9, color: PdfColors.white),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          _fmt(os.total),
          style: pw.TextStyle(
            fontSize: 28,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
        if (os.totalServicos > 0 && os.totalPecas > 0) ...[
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              _valorTag('Serviços: ${_fmt(os.totalServicos)}'),
              pw.SizedBox(width: 12),
              _valorTag('Peças: ${_fmt(os.totalPecas)}'),
            ],
          ),
        ],
      ],
    ),
  );
}

pw.Widget _valorTag(String text) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.white, width: 0.8),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(fontSize: 8, color: PdfColors.white),
    ),
  );
}

pw.Widget _reciboItens(OrdemServicoDetalhe os, PdfColor color) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Referente a:',
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.grey600,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: pw.BorderSide(color: color, width: 3),
          ),
        ),
        padding: const pw.EdgeInsets.only(left: 12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: os.itens.map((item) {
            final qtdStr = item.quantidade == item.quantidade.roundToDouble()
                ? '${item.quantidade.toInt()}x'
                : '${item.quantidade.toStringAsFixed(2)}x';
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      '$qtdStr  ${item.descricao}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ),
                  pw.Text(
                    _fmt(item.subtotal),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      if (os.descontos.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        ...os.descontos.map(
          (d) => pw.Padding(
            padding: const pw.EdgeInsets.only(left: 15, bottom: 4),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  d.descricao,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  '- ${_fmt(d.valor)}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColors.red800),
                ),
              ],
            ),
          ),
        ),
      ],
    ],
  );
}

pw.Widget _reciboInfoPagamento(OrdemServicoDetalhe os) {
  final items = <(String, String)>[];
  if (os.formaPagamento != null) {
    items.add(('Forma de pagamento', os.formaPagamento!));
  }
  if (os.dataConclusao != null) {
    items.add(('Data de pagamento', _fmtDate(os.dataConclusao)));
  } else {
    items.add(('Data de emissão', _fmtDate(DateTime.now())));
  }

  return pw.Row(
    children: items.map((pair) {
      return pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              pair.$1,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              pair.$2,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

pw.Widget _pagoBadge() {
  return pw.Center(
    child: pw.Transform.rotate(
      angle: -0.25,
      child: pw.Container(
        padding:
            const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.green800, width: 3),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Text(
          'PAGO',
          style: pw.TextStyle(
            fontSize: 34,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green800,
          ),
        ),
      ),
    ),
  );
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

pw.Widget _titleBand(
  OrdemServicoDetalhe os,
  PdfColor color, {
  bool isRecibo = false,
  bool isPago = false,
}) {
  final titulo = isRecibo
      ? 'Recibo de Servicos  —  OS No ${os.id.toString().padLeft(3, '0')}-${os.dataEntrada.year}'
      : 'Orcamento ${os.id.toString().padLeft(3, '0')}-${os.dataEntrada.year}';

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    color: color,
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          titulo,
          style: pw.TextStyle(
            color: PdfColors.white,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        if (isPago)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'PAGO',
              style: pw.TextStyle(
                color: PdfColors.green800,
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
      ],
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

pw.Widget _totals(OrdemServicoDetalhe os, PdfColor color, {bool isPago = false}) {
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
  addRow(isPago ? 'Total Pago' : 'Total', _fmt(os.total), isTotal: true);

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

pw.Widget _paymentContent(OrdemServicoDetalhe os, {bool isRecibo = false}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      if (os.formaPagamento != null)
        pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
              text: 'Forma de pagamento: ',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: os.formaPagamento!,
              style: pw.TextStyle(fontSize: 8.5),
            ),
          ]),
        ),
      if (isRecibo && os.dataConclusao != null) ...[
        pw.SizedBox(height: 4),
        pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
              text: 'Data de conclusao: ',
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(
              text: _fmtDate(os.dataConclusao),
              style: pw.TextStyle(fontSize: 8.5),
            ),
          ]),
        ),
      ],
      if (os.observacoes?.isNotEmpty ?? false) ...[
        pw.SizedBox(height: 4),
        pw.Text('Observacoes:', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
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
