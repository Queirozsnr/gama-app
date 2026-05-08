import 'package:freezed_annotation/freezed_annotation.dart';
import 'auth_state.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    String? token,
    int? userId,
    int? grupoOficinaId,
    List<GrupoItem>? selecioneGrupo,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);
}

@freezed
class SelectGroupResponse with _$SelectGroupResponse {
  const factory SelectGroupResponse({
    required String token,
    required int userId,
    required int grupoOficinaId,
  }) = _SelectGroupResponse;

  factory SelectGroupResponse.fromJson(Map<String, dynamic> json) =>
      _$SelectGroupResponseFromJson(json);
}

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String email,
    required String senha,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class SelectGroupRequest with _$SelectGroupRequest {
  const factory SelectGroupRequest({
    required int userId,
    required int grupoOficinaId,
  }) = _SelectGroupRequest;

  factory SelectGroupRequest.fromJson(Map<String, dynamic> json) =>
      _$SelectGroupRequestFromJson(json);
}
