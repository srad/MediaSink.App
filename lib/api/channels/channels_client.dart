// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/database_channel.dart';
import '../models/database_recording.dart';
import '../models/requests_channel_request.dart';
import '../models/requests_channel_tags_update_request.dart';
import '../models/services_channel_info.dart';

part 'channels_client.g.dart';

@RestApi()
abstract class ChannelsClient {
  factory ChannelsClient(Dio dio, {String? baseUrl}) = _ChannelsClient;

  /// Return a list of channels.
  ///
  /// Return a list of channels.
  @GET('/channels')
  Future<List<ServicesChannelInfo>> getChannels();

  /// Add a new channel.
  ///
  /// Add a new channel.
  ///
  /// [channelRequest] - Channel data.
  @POST('/channels')
  Future<ServicesChannelInfo> postChannels({
    @Body() required RequestsChannelRequest channelRequest,
  });

  /// Return the data of one channel.
  ///
  /// Return the data of one channel.
  ///
  /// [id] - Channel id.
  @GET('/channels/{id}')
  Future<ServicesChannelInfo> getChannelsId({
    @Path('id') required int id,
  });

  /// Delete channel.
  ///
  /// Delete channel with all recordings.
  ///
  /// [id] - List of tags.
  @DELETE('/channels/{id}')
  Future<void> deleteChannelsId({
    @Path('id') required int id,
  });

  /// Update channel data.
  ///
  /// Update channel data.
  ///
  /// [id] - Channel id.
  ///
  /// [channelRequest] - Channel data.
  @PATCH('/channels/{id}')
  Future<DatabaseChannel> patchChannelsId({
    @Path('id') required int id,
    @Body() required RequestsChannelRequest channelRequest,
  });

  /// Mark channel as one of favorites.
  ///
  /// Mark channel as one of favorites.
  ///
  /// [id] - Channel id.
  @PATCH('/channels/{id}/fav')
  Future<void> patchChannelsIdFav({
    @Path('id') required int id,
  });

  /// Pause channel for recording.
  ///
  /// Pause channel for recording.
  ///
  /// [id] - Channel id.
  @POST('/channels/{id}/pause')
  Future<void> postChannelsIdPause({
    @Path('id') required int id,
  });

  /// Tag a channel.
  ///
  /// Delete channel with all recordings.
  ///
  /// [id] - Channel id.
  @POST('/channels/{id}/resume')
  Future<void> postChannelsIdResume({
    @Path('id') required int id,
  });

  /// Tag a channel.
  ///
  /// Tag a channel.
  ///
  /// [channelTagsUpdateRequest] - Channel data.
  ///
  /// [id] - Channel id.
  @PATCH('/channels/{id}/tags')
  Future<void> patchChannelsIdTags({
    @Body() required RequestsChannelTagsUpdateRequest channelTagsUpdateRequest,
    @Path('id') required int id,
  });

  /// Remove channel as one of favorites.
  ///
  /// Remove channel as one of favorites.
  ///
  /// [id] - Channel id.
  @PATCH('/channels/{id}/unfav')
  Future<void> patchChannelsIdUnfav({
    @Path('id') required int id,
  });

  /// Add a new channel.
  ///
  /// Add a new channel.
  ///
  /// [id] - Channel id.
  ///
  /// [file] - Uploaded file chunk.
  @POST('/channels/{id}/upload')
  Future<DatabaseRecording> postChannelsIdUpload({
    @Path('id') required int id,
    @Part(name: 'file') required List<int> file,
  });
}
