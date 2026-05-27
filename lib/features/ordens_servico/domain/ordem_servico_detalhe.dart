import 'desconto_os.dart';
import 'item_os.dart';
import 'os_mecanico.dart';
import 'os_midia.dart';

class OrdemServicoDetalhe {
  const OrdemServicoDetalhe({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    this.clienteTelefone,
    required this.veiculoId,
    required this.veiculoDescricao,
    this.veiculoPlaca,
    this.veiculoCor,
    required this.status,
    this.formaPagamento,
    this.observacoes,
    required this.dataEntrada,
    this.previsaoEntrega,
    this.dataConclusao,
    required this.criadoPorNome,
    required this.mecanicos,
    required this.itens,
    required this.descontos,
    required this.midias,
    required this.totalServicos,
    required this.totalPecas,
    required this.totalDescontos,
    required this.total,
  });

  final int id;
  final int clienteId;
  final String clienteNome;
  final String? clienteTelefone;
  final int veiculoId;
  final String veiculoDescricao;
  final String? veiculoPlaca;
  final String? veiculoCor;
  final String status;
  final String? formaPagamento;
  final String? observacoes;
  final DateTime dataEntrada;
  final DateTime? previsaoEntrega;
  final DateTime? dataConclusao;
  final String criadoPorNome;
  final List<OsMecanico> mecanicos;
  final List<ItemOs> itens;
  final List<DescontoOs> descontos;
  final List<OsMidia> midias;
  final double totalServicos;
  final double totalPecas;
  final double totalDescontos;
  final double total;

  factory OrdemServicoDetalhe.fromJson(Map<String, dynamic> json) =>
      OrdemServicoDetalhe(
        id: json['id'] as int,
        clienteId: json['clienteId'] as int,
        clienteNome: json['clienteNome'] as String,
        clienteTelefone: json['clienteTelefone'] as String?,
        veiculoId: json['veiculoId'] as int,
        veiculoDescricao: json['veiculoDescricao'] as String,
        veiculoPlaca: json['veiculoPlaca'] as String?,
        veiculoCor: json['veiculoCor'] as String?,
        status: json['status'] as String,
        formaPagamento: json['formaPagamento'] as String?,
        observacoes: json['observacoes'] as String?,
        dataEntrada: DateTime.parse(json['dataEntrada'] as String),
        previsaoEntrega: json['previsaoEntrega'] != null
            ? DateTime.parse(json['previsaoEntrega'] as String)
            : null,
        dataConclusao: json['dataConclusao'] != null
            ? DateTime.parse(json['dataConclusao'] as String)
            : null,
        criadoPorNome: json['criadoPorNome'] as String,
        mecanicos: (json['mecanicos'] as List)
            .map((e) => OsMecanico.fromJson(e as Map<String, dynamic>))
            .toList(),
        itens: (json['itens'] as List)
            .map((e) => ItemOs.fromJson(e as Map<String, dynamic>))
            .toList(),
        descontos: (json['descontos'] as List)
            .map((e) => DescontoOs.fromJson(e as Map<String, dynamic>))
            .toList(),
        midias: (json['midias'] as List? ?? [])
            .map((e) => OsMidia.fromJson(e as Map<String, dynamic>))
            .toList(),
        totalServicos: (json['totalServicos'] as num).toDouble(),
        totalPecas: (json['totalPecas'] as num).toDouble(),
        totalDescontos: (json['totalDescontos'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}
