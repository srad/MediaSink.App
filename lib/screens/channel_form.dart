import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mediasink_app/api/export.dart';
import 'package:mediasink_app/rest_client_factory.dart';
import 'package:mediasink_app/utils/utils.dart';
import 'package:mediasink_app/utils/validators.dart';
import 'package:mediasink_app/widgets/snack_utils.dart';

class ChannelForm {
  int? channelId;
  String channelName;
  String displayName;
  int skipStart;
  int minDuration;
  String url;
  List<String>? tags;
  bool fav;
  bool isPaused;

  ChannelForm({this.channelId, required this.channelName, required this.displayName, required this.skipStart, required this.minDuration, required this.url, required this.tags, required this.fav, required this.isPaused});
}

class ChannelFormScreen extends StatefulWidget {
  final ChannelForm? channel;

  const ChannelFormScreen({super.key, this.channel});

  @override
  State<ChannelFormScreen> createState() => _ChannelFormScreenState();
}

class _ChannelFormScreenState extends State<ChannelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _channelNameController;
  late TextEditingController _displayNameController;
  late TextEditingController _skipStartController;
  late TextEditingController _minDurationController;
  late TextEditingController _urlController;
  late TextEditingController _tagsController;
  bool _fav = false;
  bool _isPaused = false;
  bool _saving = false;

  bool get isEdit => widget.channel != null;

  @override
  void initState() {
    super.initState();
    final c = widget.channel;

    _channelNameController = TextEditingController(text: c?.channelName ?? '');
    _displayNameController = TextEditingController(text: c?.displayName ?? '');
    _skipStartController = TextEditingController(text: (c?.skipStart ?? 0).toString());
    _minDurationController = TextEditingController(text: (c?.minDuration ?? 10).toString());
    _urlController = TextEditingController(text: c?.url ?? '');
    _tagsController = TextEditingController(text: c?.tags?.join(',') ?? '');
    _fav = c?.fav ?? false;
    _isPaused = c?.isPaused ?? false;
  }

  @override
  void dispose() {
    _channelNameController.dispose();
    _displayNameController.dispose();
    _skipStartController.dispose();
    _minDurationController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      setState(() {
        _saving = true;
      });
      if (_formKey.currentState!.validate()) {
        final channelData = RequestsChannelRequest(
            channelName: _channelNameController.text.trim(),
            displayName: _displayNameController.text.trim(),
            skipStart: int.parse(_skipStartController.text),
            minDuration: int.parse(_minDurationController.text),
            url: _urlController.text.trim(),
            tags: _tagsController.text.trim().isNotEmpty ? _tagsController.text.split(',').map((e) => e.trim()).toList() : null,
            fav: _fav,
            isPaused: _isPaused,//
        );

        if (isEdit) {
          // Edit
          final client = await RestClientFactory.create();
          final newChannel = await client.channels.patchChannelsId(id: widget.channel!.channelId!, channelRequest: channelData);
          if (mounted) messenger.showOk('Saved');
          if (mounted) Navigator.pop(context, newChannel); // return channel to caller
        } else {
          // Create
          final client = await RestClientFactory.create();
          final channelInfo = await client.channels.postChannels(channelRequest: channelData);
          if (mounted) messenger.showOk('Saved');
          if (mounted) Navigator.pop(context, channelInfo); // return channel to caller
        }
      }
    } catch (e) {
      if (mounted) messenger.showError(e.toString());
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Channel' : 'New Channel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _channelNameController,
                decoration: const InputDecoration(labelText: 'Channel Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final regex = RegExp(r'^[a-zA-Z0-9_]+$');
                  if (!regex.hasMatch(value)) return 'Only letters, numbers, and underscores allowed';
                  return null;
                },
              ),
              TextFormField(controller: _displayNameController, decoration: const InputDecoration(labelText: 'Display Name'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              TextFormField(controller: _skipStartController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Skip Start of recording for (seconds)'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              TextFormField(controller: _minDurationController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minimum Duration (minutes)'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),

              TextFormField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: 'Stream URL',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.paste_rounded),
                    tooltip: 'Paste',
                    onPressed: () async {
                      final clipboardData = await Clipboard.getData('text/plain');
                      if (clipboardData != null && clipboardData.text != null) {
                        _urlController.text = clipboardData.text!;
                        if (_channelNameController.text.isEmpty) {
                          final extracted = extractLongestAlphanumUnderscore(clipboardData.text!);
                          _channelNameController.text = extracted;
                          if (_displayNameController.text.isEmpty) {
                            _displayNameController.text = extracted;
                          }
                        }
                      }
                    },
                  ),
                ),
                validator: (value) => validateUrl(value),
              ),
              TextFormField(controller: _tagsController, decoration: const InputDecoration(labelText: 'Tags (comma-separated)'), validator: (value) => tagValidator(value)),
              SwitchListTile(title: const Text('Favorite'), value: _fav, onChanged: (v) => setState(() => _fav = v)),
              SwitchListTile(title: const Text('Paused'), value: _isPaused, onChanged: (v) => setState(() => _isPaused = v)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : _submit, // Disable button if saving
                child:
                    _saving
                        ? SizedBox(height: 10, width: 10, child: CircularProgressIndicator()) // Show progress indicator
                        : Text(isEdit ? 'Update Channel' : 'Create Channel'), // Show text otherwise
              ),
            ],
          ),
        ),
      ),
    );
  }
}
