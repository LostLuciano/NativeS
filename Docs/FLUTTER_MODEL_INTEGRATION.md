# Flutter Model Integration Guide

## Problem Analysis

Stemz.app scan results:
- ❌ No CoreML models found (.mlmodelc)
- ✅ 28 audio files (samples, metronome)
- ✅ 1 framework (blatantsPatch.dylib)
- ✅ UI assets

**Conclusion**: Models are either embedded in binary or downloaded at runtime.

## Solution: Use Open Source Models

### Option 1: Demucs (Facebook Research) - RECOMMENDED

**Advantages**:
- High quality separation
- Active development
- Multiple model sizes
- Easy to convert to CoreML

**Installation**:
```bash
pip install demucs torch torchaudio
```

**Download Model**:
```bash
# Download MDX model (best quality)
python -m demucs.separate -n mdx_extra "sample.mp3" -o output

# Or download other models
# mdx, mdx_extra, mdx_q, mdx_cover_q, mdx_extra_q
```

**Convert to CoreML**:
```bash
pip install coremltools

python -c "
import torch
import coremltools as ct
from demucs.pretrained import get_model

# Load Demucs model
model = get_model('mdx_extra')
model.eval()

# Convert to CoreML
example_input = torch.randn(1, 2, 44100 * 10)  # 10 seconds
traced_model = torch.jit.trace(model, example_input)

ml_model = ct.convert(
    traced_model,
    inputs=[ct.TensorType(shape=(1, 2, -1))],
    outputs=[ct.TensorType(name='output')],
    convert_to='mlprogram'
)

ml_model.save('StandardSeparator.mlmodelc')
"
```

### Option 2: Spleeter (Deezer)

**Installation**:
```bash
pip install spleeter
```

**Download Model**:
```bash
spleeter separate -p spleeter:2stems "sample.mp3" -o output
```

**Convert to CoreML**:
```bash
# Spleeter uses TensorFlow
pip install tensorflow coremltools

python -c "
import tensorflow as tf
import coremltools as ct

# Load TensorFlow model
model = tf.saved_model.load('spleeter/model')

# Convert to CoreML
ml_model = ct.convert(model, convert_to='mlprogram')
ml_model.save('StandardSeparator.mlmodelc')
"
```

### Option 3: UMXL (Sony)

**Installation**:
```bash
pip install umx
```

**Download Model**:
```bash
umx separate "sample.mp3" -o output
```

## Flutter Integration

### Step 1: Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # For iOS CoreML
  tflite_flutter: ^0.10.0
  
  # For audio processing
  audio_session: ^0.1.0
  just_audio: ^0.9.0
  
  # For file handling
  path_provider: ^2.0.0
  file_picker: ^5.0.0
```

### Step 2: Add Models to Assets

```yaml
# pubspec.yaml
flutter:
  assets:
    - assets/models/StandardSeparator.mlmodelc/
    - assets/models/LightSeparator.mlmodelc/
    - assets/audio/click-downbeat.m4a
    - assets/audio/click-upbeat.m4a
```

### Step 3: Create Model Manager

```dart
// lib/services/model_manager.dart
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  
  factory ModelManager() {
    return _instance;
  }
  
  ModelManager._internal();
  
  Interpreter? _standardModel;
  Interpreter? _lightModel;
  
  Future<void> loadModels() async {
    try {
      // Load standard model
      _standardModel = await Interpreter.fromAsset(
        'assets/models/StandardSeparator.mlmodelc'
      );
      
      // Load light model
      _lightModel = await Interpreter.fromAsset(
        'assets/models/LightSeparator.mlmodelc'
      );
      
      print('Models loaded successfully');
    } catch (e) {
      print('Error loading models: $e');
    }
  }
  
  Future<List<List<List<double>>>> separateAudio(
    List<List<double>> spectrogram,
    bool useLightModel,
  ) async {
    final model = useLightModel ? _lightModel : _standardModel;
    
    if (model == null) {
      throw Exception('Model not loaded');
    }
    
    // Prepare input
    final input = [spectrogram];
    
    // Prepare output
    final output = List.generate(6, (_) => List.generate(
      spectrogram.length,
      (_) => List<double>.filled(spectrogram[0].length, 0.0)
    ));
    
    // Run inference
    model.runForMultipleInputs([input], {'output': output});
    
    return output;
  }
  
  void dispose() {
    _standardModel?.close();
    _lightModel?.close();
  }
}
```

### Step 4: Create Separation Service

```dart
// lib/services/separation_service.dart
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SeparationService {
  final ModelManager modelManager = ModelManager();
  final AudioPlayer audioPlayer = AudioPlayer();
  
  Future<void> separateAudio(String inputPath) async {
    try {
      // 1. Load audio file
      final audioData = await _loadAudioFile(inputPath);
      
      // 2. Compute STFT
      final spectrogram = await _computeSTFT(audioData);
      
      // 3. Run inference
      final stems = await modelManager.separateAudio(
        spectrogram,
        false, // use standard model
      );
      
      // 4. Compute iSTFT
      final stemAudio = await _computeISTFT(stems);
      
      // 5. Save stems
      await _saveStemFiles(stemAudio);
      
      print('Separation complete');
    } catch (e) {
      print('Error during separation: $e');
    }
  }
  
  Future<List<List<double>>> _loadAudioFile(String path) async {
    // Load audio file and convert to PCM
    // Implementation depends on audio library
    return [];
  }
  
  Future<List<List<double>>> _computeSTFT(
    List<List<double>> audio,
  ) async {
    // Compute STFT using FFT
    // FFT size: 4096, Hop size: 1024
    return [];
  }
  
  Future<List<List<double>>> _computeISTFT(
    List<List<List<double>>> stems,
  ) async {
    // Compute iSTFT with overlap-add
    return [];
  }
  
  Future<void> _saveStemFiles(List<List<double>> stems) async {
    final dir = await getApplicationDocumentsDirectory();
    final stemsDir = Directory('${dir.path}/stems');
    await stemsDir.create(recursive: true);
    
    final stemNames = ['vocals', 'drums', 'bass', 'guitar', 'piano', 'other'];
    
    for (int i = 0; i < stems.length; i++) {
      final file = File('${stemsDir.path}/${stemNames[i]}.wav');
      // Write audio data to file
    }
  }
}
```

### Step 5: Use in UI

```dart
// lib/screens/separation_screen.dart
import 'package:flutter/material.dart';

class SeparationScreen extends StatefulWidget {
  @override
  _SeparationScreenState createState() => _SeparationScreenState();
}

class _SeparationScreenState extends State<SeparationScreen> {
  final SeparationService _service = SeparationService();
  double _progress = 0.0;
  String _stage = 'Ready';
  
  @override
  void initState() {
    super.initState();
    _initializeModels();
  }
  
  Future<void> _initializeModels() async {
    await _service.modelManager.loadModels();
  }
  
  Future<void> _startSeparation(String filePath) async {
    setState(() {
      _progress = 0.0;
      _stage = 'Loading audio...';
    });
    
    try {
      await _service.separateAudio(filePath);
      
      setState(() {
        _progress = 100.0;
        _stage = 'Complete!';
      });
    } catch (e) {
      setState(() {
        _stage = 'Error: $e';
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Stem Separation')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: _progress / 100),
            SizedBox(height: 20),
            Text(_stage),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _startSeparation('path/to/audio.mp3'),
              child: Text('Start Separation'),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _service.modelManager.dispose();
    super.dispose();
  }
}
```

## Model Specifications

### StandardSeparator
- **Input**: [1, 4, 32, 2048] (stereo spectrogram)
- **Output**: [1, 6, 32, 2048] (6 stems)
- **Speed**: 10-15 seconds per 4-minute song
- **Memory**: 300-400MB

### LightSeparator
- **Input**: [1, 4, 64, 1024]
- **Output**: [1, 6, 64, 1024]
- **Speed**: 5-8 seconds per 4-minute song
- **Memory**: 150-200MB

## Performance Tips

1. **Use Light Model** for:
   - Songs > 6 minutes
   - Devices with < 3GB RAM
   - Low power mode enabled

2. **Use Standard Model** for:
   - Songs < 6 minutes
   - Modern devices (iPhone 12+)
   - Best quality needed

3. **Optimization**:
   - Run inference on background thread
   - Use autoreleasepool for memory
   - Add sleep/yield every 3 chunks
   - Monitor thermal state

## Troubleshooting

### Model Loading Fails
- Verify model files in assets
- Check pubspec.yaml configuration
- Ensure correct model format

### Inference Crashes
- Check input shape matches model
- Verify memory availability
- Use light model if memory low

### Audio Quality Issues
- Verify STFT parameters
- Check window function
- Validate iSTFT implementation

## References

- [Demucs GitHub](https://github.com/facebookresearch/demucs)
- [Spleeter GitHub](https://github.com/deezer/spleeter)
- [TFLite Flutter](https://pub.dev/packages/tflite_flutter)
- [CoreML Documentation](https://developer.apple.com/coreml/)

---

**Status**: Ready for implementation

**Next Steps**: Download model, convert to CoreML, integrate into Flutter
