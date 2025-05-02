// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/database_job.dart';
import '../models/requests_jobs_request.dart';
import '../models/responses_job_worker_status.dart';
import '../models/responses_jobs_response.dart';

part 'jobs_client.g.dart';

@RestApi()
abstract class JobsClient {
  factory JobsClient(Dio dio, {String? baseUrl}) = _JobsClient;

  /// Jobs pagination.
  ///
  /// Allow paging through jobs by providing skip, take, statuses, and sort order.
  ///
  /// [jobsRequest] - Job pagination properties.
  @POST('/jobs/list')
  Future<ResponsesJobsResponse> postJobsList({
    @Body() required RequestsJobsRequest jobsRequest,
  });

  /// Stops the job processing.
  ///
  /// Stops the job processing.
  @POST('/jobs/pause')
  Future<void> postJobsPause();

  /// Start the job processing.
  ///
  /// Start the job processing.
  @POST('/jobs/resume')
  Future<void> postJobsResume();

  /// Interrupt job gracefully.
  ///
  /// Interrupt job gracefully.
  ///
  /// [pid] - Process ID.
  @POST('/jobs/stop/{pid}')
  Future<void> postJobsStopPid({
    @Path('pid') required int pid,
  });

  /// Job worker status.
  ///
  /// Job worker status.
  @GET('/jobs/worker')
  Future<ResponsesJobWorkerStatus> getJobsWorker();

  /// Enqueue a preview job.
  ///
  /// Enqueue a preview job for a video in a channel. For now only preview jobs allowed via REST.
  ///
  /// [id] - Recording item id.
  @POST('/jobs/{id}')
  Future<List<DatabaseJob>> postJobsId({
    @Path('id') required String id,
  });

  /// Interrupt and delete job gracefully.
  ///
  /// Interrupt and delete job gracefully.
  ///
  /// [id] - Job id.
  @DELETE('/jobs/{id}')
  Future<void> deleteJobsId({
    @Path('id') required int id,
  });
}
