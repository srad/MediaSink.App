import 'package:flutter/material.dart';

class AddChannelScreen extends StatefulWidget {
  const AddChannelScreen({super.key});

  @override
  State<AddChannelScreen> createState() => _AddChannelScreenState();
}

class _AddChannelScreenState extends State<AddChannelScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _skipStartController = TextEditingController();
  final TextEditingController _minDurationController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _minRecDurationController = TextEditingController();

  // Switches
  bool _fav = false;
  bool _isPaused = false;

  @override
  void dispose() {
    _channelNameController.dispose();
    _displayNameController.dispose();
    _skipStartController.dispose();
    _minDurationController.dispose();
    _urlController.dispose();
    _tagsController.dispose();
    _minRecDurationController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      final data = {"channelName": _channelNameController.text, "displayName": _displayNameController.text, "skipStart": int.tryParse(_skipStartController.text) ?? 0, "minDuration": int.tryParse(_minDurationController.text) ?? 0, "url": _urlController.text, "tags": _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(), "fav": _fav, "isPaused": _isPaused, "minimumRecordingDuration": int.tryParse(_minRecDurationController.text) ?? 0};

      print("Form submitted: $data");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Channel data saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Channel')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _channelNameController, decoration: InputDecoration(labelText: 'Channel Name'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              TextFormField(controller: _displayNameController, decoration: InputDecoration(labelText: 'Display Name'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              TextFormField(controller: _skipStartController, decoration: InputDecoration(labelText: 'Skip Start (seconds)'), keyboardType: TextInputType.number),
              TextFormField(controller: _minDurationController, decoration: InputDecoration(labelText: 'Min Duration (minutes)'), keyboardType: TextInputType.number),
              TextFormField(controller: _urlController, decoration: InputDecoration(labelText: 'URL'), validator: (value) => value == null || value.isEmpty ? 'Required' : null),
              TextFormField(controller: _tagsController, decoration: InputDecoration(labelText: 'Tags (comma-separated)')),
              TextFormField(controller: _minRecDurationController, decoration: InputDecoration(labelText: 'Minimum Recording Duration'), keyboardType: TextInputType.number),
              SwitchListTile(title: Text('Favorite'), value: _fav, onChanged: (val) => setState(() => _fav = val)),
              SwitchListTile(title: Text('Is Paused'), value: _isPaused, onChanged: (val) => setState(() => _isPaused = val)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitForm, child: Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
