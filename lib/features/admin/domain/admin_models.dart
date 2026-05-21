class GrupoAdminItem {
  const GrupoAdminItem({
    required this.id,
    required this.nome,
    required this.email,
    required this.plano,
    required this.planoExpiraEm,
    required this.ativo,
    required this.totalOficinas,
    required this.totalUsuarios,
    this.userId,
    this.nomeUsuario,
  });

  final int id;
  final String nome;
  final String email;
  final String plano;
  final DateTime planoExpiraEm;
  final bool ativo;
  final int totalOficinas;
  final int totalUsuarios;
  final int? userId;
  final String? nomeUsuario;

  factory GrupoAdminItem.fromJson(Map<String, dynamic> json) => GrupoAdminItem(
        id: (json['id'] as num).toInt(),
        nome: json['nome'] as String,
        email: json['email'] as String,
        plano: json['plano'] as String,
        planoExpiraEm: DateTime.parse(json['planoExpiraEm'] as String),
        ativo: json['ativo'] as bool,
        totalOficinas: (json['totalOficinas'] as num).toInt(),
        totalUsuarios: (json['totalUsuarios'] as num).toInt(),
        userId: json['userId'] != null ? (json['userId'] as num).toInt() : null,
        nomeUsuario: json['nomeUsuario'] as String?,
      );
}
