import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ClienteDetalhe {
  const ClienteDetalhe({
    required this.id,
    required this.nome,
    this.email,
    this.telefone,
    this.cpf,
    this.cidade,
    required this.ativo,
    required this.vip,
    required this.criadoEm,
    required this.totalGasto,
    required this.osConcluidas,
    required this.osEmAndamento,
    required this.ticketMedio,
    this.ultimaVisita,
    required this.veiculos,
    required this.ultimasOs,
    required this.proximasAcoes,
    this.notasInternas,
    this.preferencias,
  });

  final int id;
  final String nome;
  final String? email;
  final String? telefone;
  final String? cpf;
  final String? cidade;
  final bool ativo;
  final bool vip;
  final DateTime criadoEm;
  final double totalGasto;
  final int osConcluidas;
  final int osEmAndamento;
  final double ticketMedio;
  final UltimaVisitaResumo? ultimaVisita;
  final List<VeiculoDetalhe> veiculos;
  final List<OsResumoCliente> ultimasOs;
  final List<ProximaAcao> proximasAcoes;
  final String? notasInternas;
  final ClientePreferencias? preferencias;

  factory ClienteDetalhe.fromJson(Map<String, dynamic> json) => ClienteDetalhe(
        id: json['id'] as int,
        nome: json['nome'] as String,
        email: json['email'] as String?,
        telefone: json['telefone'] as String?,
        cpf: json['cpf'] as String?,
        cidade: json['cidade'] as String?,
        ativo: json['ativo'] as bool,
        vip: json['vip'] as bool? ?? false,
        criadoEm: DateTime.parse(json['criadoEm'] as String),
        totalGasto: (json['totalGasto'] as num?)?.toDouble() ?? 0,
        osConcluidas: json['osConcluidas'] as int? ?? 0,
        osEmAndamento: json['osEmAndamento'] as int? ?? 0,
        ticketMedio: (json['ticketMedio'] as num?)?.toDouble() ?? 0,
        ultimaVisita: json['ultimaVisita'] != null
            ? UltimaVisitaResumo.fromJson(json['ultimaVisita'] as Map<String, dynamic>)
            : null,
        veiculos: (json['veiculos'] as List? ?? [])
            .map((e) => VeiculoDetalhe.fromJson(e as Map<String, dynamic>))
            .toList(),
        ultimasOs: (json['ultimasOs'] as List? ?? [])
            .map((e) => OsResumoCliente.fromJson(e as Map<String, dynamic>))
            .toList(),
        proximasAcoes: (json['proximasAcoes'] as List? ?? [])
            .map((e) => ProximaAcao.fromJson(e as Map<String, dynamic>))
            .toList(),
        notasInternas: json['notasInternas'] as String?,
        preferencias: json['preferencias'] != null
            ? ClientePreferencias.fromJson(json['preferencias'] as Map<String, dynamic>)
            : null,
      );
}

// ── Última visita ──────────────────────────────────────────────────────────────

class UltimaVisitaResumo {
  const UltimaVisitaResumo({
    required this.data,
    required this.osId,
    required this.descricao,
  });
  final DateTime data;
  final int osId;
  final String descricao;

  factory UltimaVisitaResumo.fromJson(Map<String, dynamic> json) =>
      UltimaVisitaResumo(
        data: DateTime.parse(json['data'] as String),
        osId: json['osId'] as int,
        descricao: json['descricao'] as String,
      );
}

// ── Veículo enriquecido ────────────────────────────────────────────────────────

enum VeiculoStatus { naOficina, emDia, atrasada }

extension VeiculoStatusX on VeiculoStatus {
  String get label => switch (this) {
        VeiculoStatus.naOficina => 'NA OFICINA',
        VeiculoStatus.emDia     => 'EM DIA',
        VeiculoStatus.atrasada  => 'ATRASADA',
      };

  Color get color => switch (this) {
        VeiculoStatus.naOficina => AppColors.accent,
        VeiculoStatus.emDia     => AppColors.ok,
        VeiculoStatus.atrasada  => AppColors.danger,
      };

  Color get bgColor => switch (this) {
        VeiculoStatus.naOficina => AppColors.accentSoft,
        VeiculoStatus.emDia     => AppColors.okSoft,
        VeiculoStatus.atrasada  => AppColors.dangerSoft,
      };

  static VeiculoStatus fromString(String s) {
    final key = s.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    return switch (key) {
      'naoficina' => VeiculoStatus.naOficina,
      'emdia'     => VeiculoStatus.emDia,
      _           => VeiculoStatus.atrasada,
    };
  }
}

class VeiculoDetalhe {
  const VeiculoDetalhe({
    required this.id,
    this.placa,
    required this.modeloNome,
    this.cor,
    this.ano,
    this.odometro,
    this.proxRevisaoKm,
    required this.status,
  });

  final int id;
  final String? placa;
  final String modeloNome;
  final String? cor;
  final int? ano;
  final int? odometro;
  final int? proxRevisaoKm;
  final VeiculoStatus status;

  factory VeiculoDetalhe.fromJson(Map<String, dynamic> json) => VeiculoDetalhe(
        id: json['id'] as int,
        placa: json['placa'] as String?,
        modeloNome: json['modeloNome'] as String,
        cor: json['cor'] as String?,
        ano: json['ano'] as int?,
        odometro: json['odometro'] as int?,
        proxRevisaoKm: json['proxRevisaoKm'] as int?,
        status: VeiculoStatusX.fromString(json['status'] as String? ?? ''),
      );
}

// ── OS resumida ────────────────────────────────────────────────────────────────

class OsResumoCliente {
  const OsResumoCliente({
    required this.id,
    required this.status,
    this.descricao,
    this.veiculoPlaca,
    this.veiculoDescricao,
    this.mecanicoNome,
    required this.total,
    required this.data,
  });

  final int id;
  final String status;
  final String? descricao;
  final String? veiculoPlaca;
  final String? veiculoDescricao;
  final String? mecanicoNome;
  final double total;
  final DateTime data;

  factory OsResumoCliente.fromJson(Map<String, dynamic> json) => OsResumoCliente(
        id: json['id'] as int,
        status: json['status'] as String,
        descricao: json['descricao'] as String?,
        veiculoPlaca: json['veiculoPlaca'] as String?,
        veiculoDescricao: json['veiculoDescricao'] as String?,
        mecanicoNome: json['mecanicoNome'] as String?,
        total: (json['total'] as num).toDouble(),
        data: DateTime.parse(json['data'] as String),
      );
}

// ── Próximas ações ─────────────────────────────────────────────────────────────

enum ProximaAcaoTipo { revisao, orcamento, retorno, outro }

class ProximaAcao {
  const ProximaAcao({
    required this.descricao,
    this.detalhe,
    required this.tipo,
  });

  final String descricao;
  final String? detalhe;
  final ProximaAcaoTipo tipo;

  factory ProximaAcao.fromJson(Map<String, dynamic> json) => ProximaAcao(
        descricao: json['descricao'] as String,
        detalhe: json['detalhe'] as String?,
        tipo: switch ((json['tipo'] as String?)?.toLowerCase()) {
          'revisao'   => ProximaAcaoTipo.revisao,
          'orcamento' => ProximaAcaoTipo.orcamento,
          'retorno'   => ProximaAcaoTipo.retorno,
          _           => ProximaAcaoTipo.outro,
        },
      );
}

// ── Preferências ───────────────────────────────────────────────────────────────

class ClientePreferencias {
  const ClientePreferencias({
    this.formaPagamento,
    this.canalPreferido,
    required this.recebeLembretes,
  });

  final String? formaPagamento;
  final String? canalPreferido;
  final bool recebeLembretes;

  factory ClientePreferencias.fromJson(Map<String, dynamic> json) =>
      ClientePreferencias(
        formaPagamento: json['formaPagamento'] as String?,
        canalPreferido: json['canalPreferido'] as String?,
        recebeLembretes: json['recebeLembretes'] as bool? ?? false,
      );
}
