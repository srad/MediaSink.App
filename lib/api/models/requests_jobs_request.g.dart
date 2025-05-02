// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'requests_jobs_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RequestsJobsRequest _$RequestsJobsRequestFromJson(Map<String, dynamic> json) =>
    RequestsJobsRequest(
      skip: (json['skip'] as num?)?.toInt(),
      sortOrder:
          json['sortOrder'] == null
              ? null
              : DatabaseJobOrder.fromJson(json['sortOrder'] as String),
      states:
          (json['states'] as List<dynamic>?)
              ?.map((e) => DatabaseJobStatus.fromJson(e as String))
              .toList(),
      take: (json['take'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RequestsJobsRequestToJson(
  RequestsJobsRequest instance,
) => <String, dynamic>{
  'skip': instance.skip,
  'sortOrder': _$DatabaseJobOrderEnumMap[instance.sortOrder],
  'states':
      instance.states?.map((e) => _$DatabaseJobStatusEnumMap[e]!).toList(),
  'take': instance.take,
};

const _$DatabaseJobOrderEnumMap = {
  DatabaseJobOrder.asc: 'ASC',
  DatabaseJobOrder.desc: 'DESC',
  DatabaseJobOrder.$unknown: r'$unknown',
};

const _$DatabaseJobStatusEnumMap = {
  DatabaseJobStatus.completed: 'completed',
  DatabaseJobStatus.open: 'open',
  DatabaseJobStatus.error: 'error',
  DatabaseJobStatus.canceled: 'canceled',
  DatabaseJobStatus.$unknown: r'$unknown',
};
