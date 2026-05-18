import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class APIKeysSettings extends StatefulWidget {
  const APIKeysSettings({super.key});

  @override
  State<APIKeysSettings> createState() => _APIKeysSettingsState();
}

class _APIKeysSettingsState extends State<APIKeysSettings> {
  final FlutterSecureStorage _storage = FlutterSecureStorage();
  
  String _apiKey = '';
  String? _detectedProvider;
  String? _detectedModel;
  String? _detectedEndpoint;
  
  bool _isLoading = true;
  bool _isDetecting = false;
  String? _statusMessage;
  
  // Provider detection configs
  final List<Map<String, dynamic>> _providerConfigs = [
    {
      'name': 'Alibaba/GLM',
      'endpoint': 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
      'models': ['glm-5', 'glm-4', 'qwen-plus'],
      'keyPrefix': 'sk-',
    },
    {
      'name': 'OpenAI',
      'endpoint': 'https://api.openai.com/v1/chat/completions',
      'models': ['gpt-4o-mini', 'gpt-3.5-turbo'],
      'keyPrefix': 'sk-',
    },
    {
      'name': 'Gemini',
      'endpoint': 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent',
      'models': ['gemini-pro'],
      'keyPrefix': '',
    },
    {
      'name': 'Claude',
      'endpoint': 'https://api.anthropic.com/v1/messages',
      'models': ['claude-3-haiku-20240307'],
      'keyPrefix': 'sk-ant-',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _loadKey();
  }
  
  Future<void> _loadKey() async {
    try {
      _apiKey = await _storage.read(key: 'api_key') ?? '';
      _detectedProvider = await _storage.read(key: 'api_provider');
      _detectedModel = await _storage.read(key: 'api_model');
      _detectedEndpoint = await _storage.read(key: 'api_endpoint');
    } catch (e) {
      // Handle error
    }
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _saveKey() async {
    try {
      await _storage.write(key: 'api_key', value: _apiKey);
      if (_detectedProvider != null) {
        await _storage.write(key: 'api_provider', value: _detectedProvider!);
        await _storage.write(key: 'api_model', value: _detectedModel ?? '');
        await _storage.write(key: 'api_endpoint', value: _detectedEndpoint ?? '');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API key saved')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving key: $e')),
      );
    }
  }
  
  /// Smart provider detection - test each provider automatically
  Future<void> _detectProvider() async {
    if (_apiKey.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter an API key first';
      });
      return;
    }
    
    setState(() {
      _isDetecting = true;
      _statusMessage = 'Detecting provider...';
      _detectedProvider = null;
      _detectedModel = null;
      _detectedEndpoint = null;
    });
    
    // Try each provider
    for (final config in _providerConfigs) {
      // Quick prefix check
      final keyPrefix = config['keyPrefix'] as String;
      if (keyPrefix.isNotEmpty && !_apiKey.startsWith(keyPrefix)) {
        continue; // Skip if key doesn't match prefix
      }
      
      setState(() {
        _statusMessage = 'Testing ${config['name']}...';
      });
      
      // Test each model for this provider
      for (final model in (config['models'] as List)) {
        final success = await _testProvider(
          config['endpoint'] as String,
          model as String,
          _apiKey,
          config['name'] as String,
        );
        
        if (success) {
          setState(() {
            _isDetecting = false;
            _detectedProvider = config['name'];
            _detectedModel = model;
            _detectedEndpoint = config['endpoint'];
            _statusMessage = '✓ Detected: ${config['name']} (model: $model)';
          });
          
          // Auto-save on successful detection
          await _saveKey();
          return;
        }
      }
    }
    
    setState(() {
      _isDetecting = false;
      _statusMessage = '❌ Could not detect provider. Check your API key.';
    });
  }
  
  Future<bool> _testProvider(String endpoint, String model, String key, String providerName) async {
    try {
      Map<String, String> headers = {
        'Content-Type': 'application/json',
      };
      
      // Different auth for different providers
      if (providerName == 'Gemini') {
        // Gemini uses key in URL
        final uri = Uri.parse('$endpoint?key=$key');
        final response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode({
            'contents': [{'parts': [{'text': 'hi'}]}],
          }),
        ).timeout(Duration(seconds: 10));
        return response.statusCode == 200;
      } else if (providerName == 'Claude') {
        headers['x-api-key'] = key;
        headers['anthropic-version'] = '2023-06-01';
        final response = await http.post(
          Uri.parse(endpoint),
          headers: headers,
          body: jsonEncode({
            'model': model,
            'max_tokens': 5,
            'messages': [{'role': 'user', 'content': 'hi'}],
          }),
        ).timeout(Duration(seconds: 10));
        return response.statusCode == 200;
      } else {
        // OpenAI/Alibaba style
        headers['Authorization'] = 'Bearer $key';
        final response = await http.post(
          Uri.parse(endpoint),
          headers: headers,
          body: jsonEncode({
            'model': model,
            'messages': [{'role': 'user', 'content': 'hi'}],
            'max_tokens': 5,
          }),
        ).timeout(Duration(seconds: 10));
        return response.statusCode == 200;
      }
    } catch (e) {
      return false;
    }
  }
  
  String _maskKey(String key) {
    if (key.isEmpty) return '';
    if (key.length < 10) return '***';
    return '${key.substring(0, 7)}...${key.substring(key.length - 4)}';
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('API Configuration')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('API Configuration'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _apiKey.isNotEmpty ? _saveKey : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simple instruction
            Text(
              'Enter your API key and the launcher will automatically detect which provider it belongs to.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 16),
            
            // Single API key input
            TextField(
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'sk-...',
                border: OutlineInputBorder(),
                suffixIcon: _apiKey.isNotEmpty 
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _apiKey = '';
                          _detectedProvider = null;
                          _statusMessage = null;
                        });
                      },
                    )
                  : null,
              ),
              onChanged: (value) {
                setState(() {
                  _apiKey = value;
                  // Reset detection when key changes
                  _detectedProvider = null;
                  _statusMessage = null;
                });
              },
              obscureText: true,
            ),
            SizedBox(height: 16),
            
            // Auto-detect button
            ElevatedButton.icon(
              icon: _isDetecting 
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.auto_fix_high),
              label: Text(_isDetecting ? 'Detecting...' : 'Auto-Detect Provider'),
              onPressed: _isDetecting || _apiKey.isEmpty ? null : _detectProvider,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
            
            // Status message
            if (_statusMessage != null)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  _statusMessage!,
                  style: TextStyle(
                    fontSize: 14,
                    color: _statusMessage!.contains('✓') 
                      ? Colors.green 
                      : _statusMessage!.contains('❌') 
                        ? Colors.red 
                        : Colors.grey[600],
                  ),
                ),
              ),
            
            // Show detected info if successful
            if (_detectedProvider != null)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Card(
                  color: Colors.green.withOpacity(0.1),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 8),
                            Text(
                              'Provider Detected',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text('Provider: $_detectedProvider'),
                        Text('Model: $_detectedModel'),
                        SizedBox(height: 4),
                        Text(
                          'Key: ${_maskKey(_apiKey)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 16),
            
            // Saved key info
            Text(
              'Saved Configuration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            
            if (_apiKey.isEmpty)
              Text(
                'No API key saved',
                style: TextStyle(color: Colors.grey),
              )
            else
              ListTile(
                title: Text(_detectedProvider ?? 'Unknown Provider'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Key: ${_maskKey(_apiKey)}'),
                    if (_detectedModel != null) Text('Model: $_detectedModel'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await _storage.delete(key: 'api_key');
                    await _storage.delete(key: 'api_provider');
                    await _storage.delete(key: 'api_model');
                    await _storage.delete(key: 'api_endpoint');
                    setState(() {
                      _apiKey = '';
                      _detectedProvider = null;
                      _detectedModel = null;
                      _detectedEndpoint = null;
                    });
                  },
                ),
            ),
            
            SizedBox(height: 24),
            
            // Help text
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Supported Providers', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• Alibaba/GLM (glm-5, qwen models)'),
                  Text('• OpenAI (gpt-4o-mini, gpt-3.5-turbo)'),
                  Text('• Gemini (gemini-pro)'),
                  Text('• Claude (claude-3-haiku)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
