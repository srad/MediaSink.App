// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:json_annotation/json_annotation.dart';

part 'responses_login_response.g.dart';

@JsonSerializable()
class ResponsesLoginResponse {
  const ResponsesLoginResponse({
    this.token,
  });
  
  factory ResponsesLoginResponse.fromJson(Map<String, Object?> json) => _$ResponsesLoginResponseFromJson(json);
  
  final String? token;

  Map<String, Object?> toJson() => _$ResponsesLoginResponseToJson(this);
}
