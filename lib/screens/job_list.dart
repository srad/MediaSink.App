import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/models/job.dart';
import 'package:mediasink_app/patterns/value_listenable_builder_2.dart';
import 'package:mediasink_app/factories/rest_client_factory.dart';
import 'package:mediasink_app/screens/channel_details.dart';
import 'package:mediasink_app/screens/video_player.dart';
import 'package:mediasink_app/factories/simple_http_client_factory.dart';
import 'package:mediasink_app/widgets/pause_button.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class JobScreen extends StatefulWidget {
  const JobScreen({super.key});

  @override
  _JobScreenState createState() => _JobScreenState();
}

enum JobState { completed, open, error, canceled }

class _JobScreenState extends State<JobScreen> {
  final ValueNotifier<bool> _isJobWorkerProcessing = ValueNotifier(false);
  final ValueNotifier<List<Job>> _jobsNotifier = ValueNotifier([]);
  final ValueNotifier<JobState> _statusFilterNotifier = ValueNotifier(JobState.open);
  bool _isLoading = true;
  final List<String> statusOptions = JobState.values.map((x) => x.name).toList();
  String? _serverUrl;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) => _loadJobs());
    _timer = Timer.periodic(Duration(seconds: 10), (timer) async {
      _isJobWorkerProcessing.value = await _fetchWorkerState();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _serverUrl = prefs.getString('serverUrl');
  }

  Future<void> _loadJobs() async {
    _isLoading = true;
    try {
      _jobsNotifier.value = await _fetchJobs();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showError('$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<bool> _fetchWorkerState() async {
    final factory = context.read<RestClientFactory>();
    final client = await factory.create();
    final worker = await client?.jobs.getJobsWorker();
    return worker?.isProcessing ?? false;
  }

  Future<List<Job>> _fetchJobs() async {
    final client = await SimpleHttpClientFactory.create();

    final response = await client.post(
      '/jobs/list',
      data: {
        'skip': 0,
        'sortOrder': DatabaseJobOrder.desc.name,
        'states': [_statusFilterNotifier.value.name],
        'take': 50, //
      },
    );

    if (response.statusCode == 200) {
      final ResponsesJobsResponse data = ResponsesJobsResponse.fromJson(response.data);

      final jobs =
          (data.jobs ?? [])
              .map(
                (job) => Job(
                  jobId: job.jobId!,
                  channelId: job.channelId!,
                  recordingId: job.recordingId!,
                  channelName: job.channelName!,
                  filename: job.filename!,
                  task: job.task!.name,
                  status: job.status!.name,
                  filepath: job.filepath!,
                  active: job.active!,
                  videoUrl: '$_serverUrl${job.filepath}',
                  createdAt: DateTime.parse(job.createdAt!), //
                ),
              )
              .toList();

      return jobs;
    }
    return [];
  }

  Future<void> deleteJob(int jobId) async {
    try {
      final factory = context.read<RestClientFactory>();
      final client = await factory.create();
      await client?.jobs.deleteJobsId(id: jobId);
      _jobsNotifier.value.removeWhere((j) => j.jobId == jobId);
      if (mounted) ScaffoldMessenger.of(context).showOk('Job deleted');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showError('$e');
    }
  }

  bool isJobInFilter(Job job, JobState filter) => switch (filter) {
    'Open' => job.status.toLowerCase() == 'running' || job.status.toLowerCase() == 'queued',
    'Completed' => job.status.toLowerCase() == 'completed',
    'Canceled' => job.status.toLowerCase() == 'canceled',
    'Errors' => job.status.toLowerCase() == 'error' || job.status.toLowerCase() == 'failed',
    _ => true, // 'All'
  };

  DataRow jobRow(Job job) {
    return DataRow(
      cells: [
        DataCell(
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => VideoPlayerScreen(title: job.channelName, videoUrl: job.videoUrl)));
            }, //
            child: Row(
              children: [
                Text(job.filename, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
                const Spacer(),
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChannelDetailsScreen(channelId: job.channelId, title: job.channelName)));
                  },
                  icon: Icon(Icons.grid_view_rounded),
                ),
              ],
            ),
          ),
        ),
        DataCell(Text(job.task)),
        DataCell(Text(timeago.format(job.createdAt))),
        DataCell(Text(job.startedAt != null ? timeago.format(job.startedAt!) : '-')),
        DataCell(Text(job.completedAt != null ? timeago.format(job.completedAt!) : '-')),
        DataCell(IconButton(icon: Icon(Icons.delete, color: Colors.red), onPressed: () => deleteJob(job.jobId))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jobs'), actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _fetchJobs)]),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: DropdownButtonFormField<JobState>(
              value: _statusFilterNotifier.value,
              isDense: true,
              decoration: const InputDecoration(labelText: 'Job state', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
              items: JobState.values.map((status) => DropdownMenuItem(value: status, child: Text(status.name))).toList(),
              onChanged: (value) {
                if (value != null) {
                  _statusFilterNotifier.value = value;
                  _loadJobs();
                }
              },
            ),
          ),
          Expanded(
            child: ValueListenableBuilder2<List<Job>, JobState>(
              first: _jobsNotifier,
              second: _statusFilterNotifier,
              builder: (context, jobs, filter, _) {
                if (_isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (jobs.isEmpty) {
                  return const Center(child: Text("No jobs"));
                }

                final filteredJobs = jobs.where((job) => isJobInFilter(job, filter)).toList();

                if (filteredJobs.isEmpty) {
                  return Center(child: Text('No jobs match this filter.'));
                }

                return InteractiveViewer(
                  constrained: false,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text('Video')),
                      DataColumn(label: Text('Task')),
                      DataColumn(label: Text('Created')),
                      DataColumn(label: Text('Started')),
                      DataColumn(label: Text('Completed')),
                      DataColumn(label: Text('Delete')), //
                    ],
                    rows: filteredJobs.map(jobRow).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey.shade200,
        height: 70,
        child: Row(
          children: [
            _isLoading ? Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator())) : IconButton(onPressed: _loadJobs, icon: Icon(Icons.refresh_rounded), iconSize: 28),
            const Spacer(),
            Text(_isJobWorkerProcessing.value ? 'Resume job worker' : 'Pause job worker', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 5),
            ValueListenableBuilder<bool>(
              builder: (context, value, child) => PauseButton(isPaused: !value, onPressed: () => _togglePause(), iconSize: 32),
              valueListenable: _isJobWorkerProcessing, //
            ),
          ], //
        ),
      ),
    );
  }

  Future _togglePause() async {
    _isJobWorkerProcessing.value = !_isJobWorkerProcessing.value;
  }
}
