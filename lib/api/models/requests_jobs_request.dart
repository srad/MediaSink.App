// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:json_annotation/json_annotation.dart';

import 'database_job_order.dart';
import 'database_job_status.dart';

part 'requests_jobs_request.g.dart';

@JsonSerializable()
class RequestsJobsRequest {
  const RequestsJobsRequest({
    this.skip,
    this.sortOrder,
    this.states,
    this.take,
  });
  
  factory RequestsJobsRequest.fromJson(Map<String, Object?> json) => _$RequestsJobsRequestFromJson(json);
  
  final int? skip;
  final DatabaseJobOrder? sortOrder;
  final List<DatabaseJobStatus>? states;
  final int? take;

  Map<String, Object?> toJson() => _$RequestsJobsRequestToJson(this);
}
