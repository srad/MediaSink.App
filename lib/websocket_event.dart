class WebSocketEvent {
  // Channel Events
  static const channelOnline = "channel:online";
  static const channelOffline = "channel:offline";
  static const channelStart = "channel:start";
  static const channelThumbnail = "channel:thumbnail";

  // Job Events
  static const jobCreate = "job:create";
  static const jobStart = "job:start";
  static const jobProgress = "job:progress";
  static const jobDone = "job:done";
  static const jobActivate = "job:activate";
  static const jobDeactivate = "job:deactivate";
  static const jobError = "job:error";
  static const jobPreviewDone = "job:preview:done";
  static const jobDelete = "job:delete";

  // Recording Events
  static const recordingAdd = "recording:add";

  static const heartbeat = "heartbeat";
}