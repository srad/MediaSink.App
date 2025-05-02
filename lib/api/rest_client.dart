// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';

import 'admin/admin_client.dart';
import 'auth/auth_client.dart';
import 'channels/channels_client.dart';
import 'info/info_client.dart';
import 'jobs/jobs_client.dart';
import 'processes/processes_client.dart';
import 'recorder/recorder_client.dart';
import 'recordings/recordings_client.dart';
import 'user/user_client.dart';

class RestClient {
  RestClient(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '';

  AdminClient? _admin;
  AuthClient? _auth;
  ChannelsClient? _channels;
  InfoClient? _info;
  JobsClient? _jobs;
  ProcessesClient? _processes;
  RecorderClient? _recorder;
  RecordingsClient? _recordings;
  UserClient? _user;

  AdminClient get admin => _admin ??= AdminClient(_dio, baseUrl: _baseUrl);

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  ChannelsClient get channels => _channels ??= ChannelsClient(_dio, baseUrl: _baseUrl);

  InfoClient get info => _info ??= InfoClient(_dio, baseUrl: _baseUrl);

  JobsClient get jobs => _jobs ??= JobsClient(_dio, baseUrl: _baseUrl);

  ProcessesClient get processes => _processes ??= ProcessesClient(_dio, baseUrl: _baseUrl);

  RecorderClient get recorder => _recorder ??= RecorderClient(_dio, baseUrl: _baseUrl);

  RecordingsClient get recordings => _recordings ??= RecordingsClient(_dio, baseUrl: _baseUrl);

  UserClient get user => _user ??= UserClient(_dio, baseUrl: _baseUrl);
}
