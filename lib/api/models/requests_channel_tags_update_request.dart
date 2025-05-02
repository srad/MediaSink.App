// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:json_annotation/json_annotation.dart';

part 'requests_channel_tags_update_request.g.dart';

@JsonSerializable()
class RequestsChannelTagsUpdateRequest {
  const RequestsChannelTagsUpdateRequest({
    this.tags,
  });
  
  factory RequestsChannelTagsUpdateRequest.fromJson(Map<String, Object?> json) => _$RequestsChannelTagsUpdateRequestFromJson(json);
  
  final List<String>? tags;

  Map<String, Object?> toJson() => _$RequestsChannelTagsUpdateRequestToJson(this);
}
