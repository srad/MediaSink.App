// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/responses_recording_status_response.dart';

part 'recorder_client.g.dart';

@RestApi()
abstract class RecorderClient {
  factory RecorderClient(Dio dio, {String? baseUrl}) = _RecorderClient;

  /// Return if server is current recording.
  ///
  /// Return if server is current recording.
  @GET('/recorder')
  Future<ResponsesRecordingStatusResponse> getRecorder();

  /// StopRecorder server recording
  @POST('/recorder/pause')
  Future<void> postRecorderPause();

  /// StartRecorder server recording
  @POST('/recorder/resume')
  Future<void> postRecorderResume();
}
