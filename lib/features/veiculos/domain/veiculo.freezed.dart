// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'veiculo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Veiculo _$VeiculoFromJson(Map<String, dynamic> json) {
  return _Veiculo.fromJson(json);
}

/// @nodoc
mixin _$Veiculo {
  int get id => throw _privateConstructorUsedError;
  int get clienteId => throw _privateConstructorUsedError;
  String get clienteNome => throw _privateConstructorUsedError;
  int get modeloId => throw _privateConstructorUsedError;
  String get modeloNome => throw _privateConstructorUsedError;
  int get marcaId => throw _privateConstructorUsedError;
  String get marcaNome => throw _privateConstructorUsedError;
  String? get placa => throw _privateConstructorUsedError;
  int? get ano => throw _privateConstructorUsedError;
  String? get cor => throw _privateConstructorUsedError;
  String? get combustivel => throw _privateConstructorUsedError;
  int? get quilometragem => throw _privateConstructorUsedError;
  String? get observacoes => throw _privateConstructorUsedError;
  bool get ativo => throw _privateConstructorUsedError;
  DateTime get criadoEm => throw _privateConstructorUsedError;

  /// Serializes this Veiculo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Veiculo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VeiculoCopyWith<Veiculo> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VeiculoCopyWith<$Res> {
  factory $VeiculoCopyWith(Veiculo value, $Res Function(Veiculo) then) =
      _$VeiculoCopyWithImpl<$Res, Veiculo>;
  @useResult
  $Res call({
    int id,
    int clienteId,
    String clienteNome,
    int modeloId,
    String modeloNome,
    int marcaId,
    String marcaNome,
    String? placa,
    int? ano,
    String? cor,
    String? combustivel,
    int? quilometragem,
    String? observacoes,
    bool ativo,
    DateTime criadoEm,
  });
}

/// @nodoc
class _$VeiculoCopyWithImpl<$Res, $Val extends Veiculo>
    implements $VeiculoCopyWith<$Res> {
  _$VeiculoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Veiculo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clienteId = null,
    Object? clienteNome = null,
    Object? modeloId = null,
    Object? modeloNome = null,
    Object? marcaId = null,
    Object? marcaNome = null,
    Object? placa = freezed,
    Object? ano = freezed,
    Object? cor = freezed,
    Object? combustivel = freezed,
    Object? quilometragem = freezed,
    Object? observacoes = freezed,
    Object? ativo = null,
    Object? criadoEm = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as int,
            clienteId: null == clienteId
                ? _value.clienteId
                : clienteId // ignore: cast_nullable_to_non_nullable
                      as int,
            clienteNome: null == clienteNome
                ? _value.clienteNome
                : clienteNome // ignore: cast_nullable_to_non_nullable
                      as String,
            modeloId: null == modeloId
                ? _value.modeloId
                : modeloId // ignore: cast_nullable_to_non_nullable
                      as int,
            modeloNome: null == modeloNome
                ? _value.modeloNome
                : modeloNome // ignore: cast_nullable_to_non_nullable
                      as String,
            marcaId: null == marcaId
                ? _value.marcaId
                : marcaId // ignore: cast_nullable_to_non_nullable
                      as int,
            marcaNome: null == marcaNome
                ? _value.marcaNome
                : marcaNome // ignore: cast_nullable_to_non_nullable
                      as String,
            placa: freezed == placa
                ? _value.placa
                : placa // ignore: cast_nullable_to_non_nullable
                      as String?,
            ano: freezed == ano
                ? _value.ano
                : ano // ignore: cast_nullable_to_non_nullable
                      as int?,
            cor: freezed == cor
                ? _value.cor
                : cor // ignore: cast_nullable_to_non_nullable
                      as String?,
            combustivel: freezed == combustivel
                ? _value.combustivel
                : combustivel // ignore: cast_nullable_to_non_nullable
                      as String?,
            quilometragem: freezed == quilometragem
                ? _value.quilometragem
                : quilometragem // ignore: cast_nullable_to_non_nullable
                      as int?,
            observacoes: freezed == observacoes
                ? _value.observacoes
                : observacoes // ignore: cast_nullable_to_non_nullable
                      as String?,
            ativo: null == ativo
                ? _value.ativo
                : ativo // ignore: cast_nullable_to_non_nullable
                      as bool,
            criadoEm: null == criadoEm
                ? _value.criadoEm
                : criadoEm // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VeiculoImplCopyWith<$Res> implements $VeiculoCopyWith<$Res> {
  factory _$$VeiculoImplCopyWith(
    _$VeiculoImpl value,
    $Res Function(_$VeiculoImpl) then,
  ) = __$$VeiculoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int id,
    int clienteId,
    String clienteNome,
    int modeloId,
    String modeloNome,
    int marcaId,
    String marcaNome,
    String? placa,
    int? ano,
    String? cor,
    String? combustivel,
    int? quilometragem,
    String? observacoes,
    bool ativo,
    DateTime criadoEm,
  });
}

/// @nodoc
class __$$VeiculoImplCopyWithImpl<$Res>
    extends _$VeiculoCopyWithImpl<$Res, _$VeiculoImpl>
    implements _$$VeiculoImplCopyWith<$Res> {
  __$$VeiculoImplCopyWithImpl(
    _$VeiculoImpl _value,
    $Res Function(_$VeiculoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Veiculo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clienteId = null,
    Object? clienteNome = null,
    Object? modeloId = null,
    Object? modeloNome = null,
    Object? marcaId = null,
    Object? marcaNome = null,
    Object? placa = freezed,
    Object? ano = freezed,
    Object? cor = freezed,
    Object? combustivel = freezed,
    Object? quilometragem = freezed,
    Object? observacoes = freezed,
    Object? ativo = null,
    Object? criadoEm = null,
  }) {
    return _then(
      _$VeiculoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as int,
        clienteId: null == clienteId
            ? _value.clienteId
            : clienteId // ignore: cast_nullable_to_non_nullable
                  as int,
        clienteNome: null == clienteNome
            ? _value.clienteNome
            : clienteNome // ignore: cast_nullable_to_non_nullable
                  as String,
        modeloId: null == modeloId
            ? _value.modeloId
            : modeloId // ignore: cast_nullable_to_non_nullable
                  as int,
        modeloNome: null == modeloNome
            ? _value.modeloNome
            : modeloNome // ignore: cast_nullable_to_non_nullable
                  as String,
        marcaId: null == marcaId
            ? _value.marcaId
            : marcaId // ignore: cast_nullable_to_non_nullable
                  as int,
        marcaNome: null == marcaNome
            ? _value.marcaNome
            : marcaNome // ignore: cast_nullable_to_non_nullable
                  as String,
        placa: freezed == placa
            ? _value.placa
            : placa // ignore: cast_nullable_to_non_nullable
                  as String?,
        ano: freezed == ano
            ? _value.ano
            : ano // ignore: cast_nullable_to_non_nullable
                  as int?,
        cor: freezed == cor
            ? _value.cor
            : cor // ignore: cast_nullable_to_non_nullable
                  as String?,
        combustivel: freezed == combustivel
            ? _value.combustivel
            : combustivel // ignore: cast_nullable_to_non_nullable
                  as String?,
        quilometragem: freezed == quilometragem
            ? _value.quilometragem
            : quilometragem // ignore: cast_nullable_to_non_nullable
                  as int?,
        observacoes: freezed == observacoes
            ? _value.observacoes
            : observacoes // ignore: cast_nullable_to_non_nullable
                  as String?,
        ativo: null == ativo
            ? _value.ativo
            : ativo // ignore: cast_nullable_to_non_nullable
                  as bool,
        criadoEm: null == criadoEm
            ? _value.criadoEm
            : criadoEm // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VeiculoImpl implements _Veiculo {
  const _$VeiculoImpl({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    required this.modeloId,
    required this.modeloNome,
    required this.marcaId,
    required this.marcaNome,
    this.placa,
    this.ano,
    this.cor,
    this.combustivel,
    this.quilometragem,
    this.observacoes,
    required this.ativo,
    required this.criadoEm,
  });

  factory _$VeiculoImpl.fromJson(Map<String, dynamic> json) =>
      _$$VeiculoImplFromJson(json);

  @override
  final int id;
  @override
  final int clienteId;
  @override
  final String clienteNome;
  @override
  final int modeloId;
  @override
  final String modeloNome;
  @override
  final int marcaId;
  @override
  final String marcaNome;
  @override
  final String? placa;
  @override
  final int? ano;
  @override
  final String? cor;
  @override
  final String? combustivel;
  @override
  final int? quilometragem;
  @override
  final String? observacoes;
  @override
  final bool ativo;
  @override
  final DateTime criadoEm;

  @override
  String toString() {
    return 'Veiculo(id: $id, clienteId: $clienteId, clienteNome: $clienteNome, modeloId: $modeloId, modeloNome: $modeloNome, marcaId: $marcaId, marcaNome: $marcaNome, placa: $placa, ano: $ano, cor: $cor, combustivel: $combustivel, quilometragem: $quilometragem, observacoes: $observacoes, ativo: $ativo, criadoEm: $criadoEm)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VeiculoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clienteId, clienteId) ||
                other.clienteId == clienteId) &&
            (identical(other.clienteNome, clienteNome) ||
                other.clienteNome == clienteNome) &&
            (identical(other.modeloId, modeloId) ||
                other.modeloId == modeloId) &&
            (identical(other.modeloNome, modeloNome) ||
                other.modeloNome == modeloNome) &&
            (identical(other.marcaId, marcaId) || other.marcaId == marcaId) &&
            (identical(other.marcaNome, marcaNome) ||
                other.marcaNome == marcaNome) &&
            (identical(other.placa, placa) || other.placa == placa) &&
            (identical(other.ano, ano) || other.ano == ano) &&
            (identical(other.cor, cor) || other.cor == cor) &&
            (identical(other.combustivel, combustivel) ||
                other.combustivel == combustivel) &&
            (identical(other.quilometragem, quilometragem) ||
                other.quilometragem == quilometragem) &&
            (identical(other.observacoes, observacoes) ||
                other.observacoes == observacoes) &&
            (identical(other.ativo, ativo) || other.ativo == ativo) &&
            (identical(other.criadoEm, criadoEm) ||
                other.criadoEm == criadoEm));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    clienteId,
    clienteNome,
    modeloId,
    modeloNome,
    marcaId,
    marcaNome,
    placa,
    ano,
    cor,
    combustivel,
    quilometragem,
    observacoes,
    ativo,
    criadoEm,
  );

  /// Create a copy of Veiculo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VeiculoImplCopyWith<_$VeiculoImpl> get copyWith =>
      __$$VeiculoImplCopyWithImpl<_$VeiculoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VeiculoImplToJson(this);
  }
}

abstract class _Veiculo implements Veiculo {
  const factory _Veiculo({
    required final int id,
    required final int clienteId,
    required final String clienteNome,
    required final int modeloId,
    required final String modeloNome,
    required final int marcaId,
    required final String marcaNome,
    final String? placa,
    final int? ano,
    final String? cor,
    final String? combustivel,
    final int? quilometragem,
    final String? observacoes,
    required final bool ativo,
    required final DateTime criadoEm,
  }) = _$VeiculoImpl;

  factory _Veiculo.fromJson(Map<String, dynamic> json) = _$VeiculoImpl.fromJson;

  @override
  int get id;
  @override
  int get clienteId;
  @override
  String get clienteNome;
  @override
  int get modeloId;
  @override
  String get modeloNome;
  @override
  int get marcaId;
  @override
  String get marcaNome;
  @override
  String? get placa;
  @override
  int? get ano;
  @override
  String? get cor;
  @override
  String? get combustivel;
  @override
  int? get quilometragem;
  @override
  String? get observacoes;
  @override
  bool get ativo;
  @override
  DateTime get criadoEm;

  /// Create a copy of Veiculo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VeiculoImplCopyWith<_$VeiculoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
