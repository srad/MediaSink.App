// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/helpers_disk_info.dart';
import '../models/helpers_sys_info.dart';

part 'info_client.g.dart';

@RestApi()
abstract class InfoClient {
  factory InfoClient(Dio dio, {String? baseUrl}) = _InfoClient;

  /// Get disk information.
  ///
  /// Get disk information.
  @GET('/info/disk')
  Future<HelpersDiskInfo> getInfoDisk();

  /// Get system metrics.
  ///
  /// Get system metrics.
  ///
  /// [seconds] - Number of seconds to measure.
  @GET('/info/{seconds}')
  Future<HelpersSysInfo> getInfoSeconds({
    @Path('seconds') required int seconds,
  });
}
