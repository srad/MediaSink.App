import 'package:flutter/material.dart';

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

  ChannelForm({
    this.channelId,
    required this.channelName,
    required this.displayName,
    required this.skipStart,
    required this.minDuration,
    required this.url,
    required this.tags,
    required this.fav,
    required this.isPaused,
  });
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

  @override
  void initState() {
    super.initState();
    final c = widget.channel;

    _channelNameController = TextEditingController(text: c?.channelName ?? '');
    _displayNameController = TextEditingController(text: c?.displayName ?? '');
    _skipStartController = TextEditingController(text: (c?.skipStart ?? 0).toString());
    _minDurationController = TextEditingController(text: (c?.minDuration ?? 10).toString());
    _urlController = TextEditingController(text: c?.url ?? '');
    _tagsController = TextEditingController(text: c?.tags?.join(', ') ?? '');
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newChannel = ChannelForm(
        channelId: widget.channel?.channelId,
        channelName: _channelNameController.text.trim(),
        displayName: _displayNameController.text.trim(),
        skipStart: int.parse(_skipStartController.text),
        minDuration: int.parse(_minDurationController.text),
        url: _urlController.text.trim(),
        tags: _tagsController.text.split(',').map((e) => e.trim()).toList(),
        fav: _fav,
        isPaused: _isPaused,
      );

      Navigator.pop(context, newChannel); // return channel to caller
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.channel != null;

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
              TextFormField(
                controller: _displayNameController,
                decoration: const InputDecoration(labelText: 'Display Name'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _skipStartController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Skip Start (seconds)'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _minDurationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Minimum Duration (minutes)'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _tagsController,
                decoration: const InputDecoration(labelText: 'Tags (comma-separated)'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              SwitchListTile(
                title: const Text('Favorite'),
                value: _fav,
                onChanged: (v) => setState(() => _fav = v),
              ),
              SwitchListTile(
                title: const Text('Paused'),
                value: _isPaused,
                onChanged: (v) => setState(() => _isPaused = v),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text(isEdit ? 'Update Channel' : 'Create Channel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
