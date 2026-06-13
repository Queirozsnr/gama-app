import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../domain/receitas_dashboard.dart';

// ── helpers ───────────────────────────────────────────────────────────────────

String _fmtMoeda(double v) {
  final parts = v.toStringAsFixed(2).split('.');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return 'R\$ $intPart,${parts[1]}';
}

String _fmtData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String _fmtHora(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _formaPag(String? fp) => switch (fp) {
      'Pix' => 'PIX',
      'Dinheiro' => 'Dinheiro',
      'CartaoDebito' => 'Débito',
      'CartaoCredito' => 'Crédito',
      'Transferencia' => 'Transferência',
      _ => fp ?? '—',
    };

const _amber = PdfColor.fromInt(0xFFFF7A1A);
const _ink = PdfColor.fromInt(0xFF1A1A2E);
const _ink3 = PdfColor.fromInt(0xFF9CA3AF);
const _line = PdfColor.fromInt(0xFFE5E7EB);
const _bg = PdfColor.fromInt(0xFFF9FAFB);

pw.Widget pdfSectionTitle(String title) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6, top: 16),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    );

pw.TableRow pdfTableHeader(List<String> cols) => pw.TableRow(
      decoration: const pw.BoxDecoration(color: _ink),
      children: cols
          .map((c) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: pw.Text(
                  c,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ))
          .toList(),
    );

pw.TableRow pdfTableRow(List<String> cells, {bool alt = false}) => pw.TableRow(
      decoration: pw.BoxDecoration(color: alt ? _bg : PdfColors.white),
      children: cells
          .map((c) => pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: pw.Text(
                  c,
                  style: const pw.TextStyle(fontSize: 9, color: _ink),
                ),
              ))
          .toList(),
    );

pw.Widget pdfKpiBox(String label, String value, String sub,
        {PdfColor valueColor = _ink}) =>
    pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: _bg,
          border: pw.Border.all(color: _line),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 8, color: _ink3)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: valueColor,
                )),
            if (sub.isNotEmpty) ...[
              pw.SizedBox(height: 2),
              pw.Text(sub,
                  style: const pw.TextStyle(fontSize: 8, color: _ink3)),
            ],
          ],
        ),
      ),
    );

// ── PDF principal ─────────────────────────────────────────────────────────────

Future<void> imprimirReceitas(
  ReceitasDashboard d,
  DateTime ini,
  DateTime fim,
) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Relatório de Receitas',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Periodo: ${_fmtData(ini)} - ${_fmtData(fim)}',
                    style: const pw.TextStyle(fontSize: 10, color: _ink3),
                  ),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: _amber,
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  'GAMA',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(color: _line),
        ],
      ),
      build: (_) => [
        // KPIs
        pw.Row(
          children: [
            pdfKpiBox('RECEITA BRUTA', _fmtMoeda(d.receitaBruta),
                '${d.totalOs} OS',
                valueColor: _amber),
            pw.SizedBox(width: 10),
            pdfKpiBox('DESPESAS', _fmtMoeda(d.despesas), 'Peças + folha + fixos'),
            pw.SizedBox(width: 10),
            pdfKpiBox('LUCRO LÍQUIDO', _fmtMoeda(d.lucroLiquido), '',
                valueColor: _amber),
            pw.SizedBox(width: 10),
            pdfKpiBox('TICKET MÉDIO', _fmtMoeda(d.ticketMedio),
                '${d.totalOs} OS pagas'),
          ],
        ),

        // Pagamentos recentes
        pdfSectionTitle('Pagamentos Recentes'),
        pw.Table(
          border: pw.TableBorder.all(color: _line, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(3),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pdfTableHeader(['Data/Hora', 'OS', 'Cliente', 'Forma', 'Valor']),
            ...d.pagamentosRecentes.asMap().entries.map((e) {
              final p = e.value;
              return pdfTableRow([
                '${_fmtData(p.dataHora)} ${_fmtHora(p.dataHora)}',
                '#${p.ordemServicoId}',
                p.clienteNome,
                _formaPag(p.formaPagamento),
                _fmtMoeda(p.valor),
              ], alt: e.key.isOdd);
            }),
          ],
        ),

        // Receita por mecânico
        if (d.receitaPorMecanico.isNotEmpty) ...[
          pdfSectionTitle('Receita por Mecânico'),
          pw.Table(
            border: pw.TableBorder.all(color: _line, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pdfTableHeader(['Mecânico', 'OS', 'Ticket Médio', 'Receita']),
              ...d.receitaPorMecanico.asMap().entries.map((e) {
                final m = e.value;
                return pdfTableRow([
                  m.nome,
                  '${m.totalOs}',
                  _fmtMoeda(m.ticketMedio),
                  _fmtMoeda(m.receita),
                ], alt: e.key.isOdd);
              }),
            ],
          ),

          // Lucro por mecânico
          pdfSectionTitle('Meu Lucro por Mecânico'),
          pw.Table(
            border: pw.TableBorder.all(color: _line, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(2),
            },
            children: [
              pdfTableHeader(
                  ['Mecânico', 'Tipo', 'Comissão', 'OS', 'Lucro Líquido']),
              ...d.receitaPorMecanico.asMap().entries.map((e) {
                final m = e.value;
                return pdfTableRow([
                  m.nome,
                  m.tipoRemuneracao,
                  m.porcentagem != null ? '${m.porcentagem}%' : '-',
                  '${m.totalOs}',
                  _fmtMoeda(m.liquidoOwner),
                ], alt: e.key.isOdd);
              }),
            ],
          ),
        ],
      ],
    ),
  );

  final dataStr = '${_fmtData(ini).replaceAll('/', '')}_${_fmtData(fim).replaceAll('/', '')}';
  await Printing.layoutPdf(
    onLayout: (_) async => doc.save(),
    name: 'receitas_$dataStr.pdf',
  );
}
