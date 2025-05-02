// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:json_annotation/json_annotation.dart';

import 'database_job.dart';

part 'responses_jobs_response.g.dart';

@JsonSerializable()
class ResponsesJobsResponse {
  const ResponsesJobsResponse({
    this.jobs,
    this.skip,
    this.take,
    this.totalCount,
  });
  
  factory ResponsesJobsResponse.fromJson(Map<String, Object?> json) => _$ResponsesJobsResponseFromJson(json);
  
  final List<DatabaseJob>? jobs;
  final int? skip;
  final int? take;
  final int? totalCount;

  Map<String, Object?> toJson() => _$ResponsesJobsResponseToJson(this);
}
