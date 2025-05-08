class Job {
  final int jobId;
  final int channelId;
  final int recordingId;
  final String channelName;
  final String filename;
  final String task;
  final String status;
  final String filepath;
  final bool active;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final int? pid;
  final String? command;
  final dynamic progress;
  final dynamic info;
  final String? args;
  final String videoUrl;

  Job({
    required this.jobId,
    required this.channelId,
    required this.recordingId,
    required this.channelName,
    required this.filename,
    required this.task,
    required this.status,
    required this.filepath,
    required this.active,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.pid,
    this.command,
    this.progress,
    this.info,
    this.args,
    required this.videoUrl,
  });

  Job copyWith({
    int? jobId,
    int? channelId,
    int? recordingId,
    String? channelName,
    String? filename,
    String? task,
    String? status,
    String? filepath,
    bool? active,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    int? pid,
    String? command,
    dynamic progress,
    dynamic info,
    String? args,
  }) {
    return Job(
      jobId: jobId ?? this.jobId,
      channelId: channelId ?? this.channelId,
      recordingId: recordingId ?? this.recordingId,
      channelName: channelName ?? this.channelName,
      filename: filename ?? this.filename,
      task: task ?? this.task,
      status: status ?? this.status,
      filepath: filepath ?? this.filepath,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      pid: pid ?? this.pid,
      command: command ?? this.command,
      progress: progress ?? this.progress,
      info: info ?? this.info,
      args: args ?? this.args,
      videoUrl: videoUrl,
    );
  }
}
