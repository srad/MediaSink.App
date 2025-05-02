// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/responses_import_info_response.dart';
import '../models/responses_server_info_response.dart';

part 'admin_client.g.dart';

@RestApi()
abstract class AdminClient {
  factory AdminClient(Dio dio, {String? baseUrl}) = _AdminClient;

  /// Returns server version information.
  ///
  /// version information.
  @GET('/admin/import')
  Future<ResponsesImportInfoResponse> getAdminImport();

  /// Run once the import of mp4 files in the recordings folder, which are not yet in the system.
  ///
  /// Return a list of channels.
  @POST('/admin/import')
  Future<void> postAdminImport();

  /// Returns server version information.
  ///
  /// version information.
  @GET('/admin/version')
  Future<ResponsesServerInfoResponse> getAdminVersion();
}
