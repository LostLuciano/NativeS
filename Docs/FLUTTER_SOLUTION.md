# Flutter Project Solution - Model Integration

## 🎯 Masalah Anda

Flutter project tidak berjalan lancar karena **model CoreML tidak tersedia**.

## ✅ Solusi

Gunakan model open source yang sudah siap pakai dan convert ke CoreML.

## 📋 Step-by-Step Guide

### Step 1: Download Model (Windows)

```bash
# Install dependencies
pip install demucs torch torchaudio

# Download model
python -m demucs.separate -n mdx_extra "sample.mp3" -o output
```

**Atau gunakan Spleeter**:
```bash
pip install spleeter
spleeter separate -p spleeter:2stems "sample.mp3" -o output
```

### Step 2: Convert to CoreML

```bash
pip install coremltools

# Buat file convert_model.py
```

**convert_model.py**:
```python
import torch
import coremltools as ct
from demucs.pretrained import get_model

# Load model
model = get_model('mdx_extra')
model.eval()

# Create example input
example_input = torch.randn(1, 2, 44100 * 10)

# Trace model
traced = torch.jit.trace(model, example_input)

# Convert to CoreML
ml_model = ct.convert(
    traced,
    inputs=[ct.TensorType(shape=(1, 2, -1), name='input')],
    outputs=[ct.TensorType(name='output')],
    convert_to='mlprogram'
)

# Save
ml_model.save('StandardSeparator.mlmodelc')
print("✅ Model saved: StandardSeparator.mlmodelc")
```

**Jalankan**:
```bash
python convert_model.py
```

### Step 3: Copy Model ke Flutter Project

```bash
# Copy ke Flutter assets
cp StandardSeparator.mlmodelc D:\IPA Project\a\flutter_appcoba\assets\models\

# Atau untuk light model
cp LightSeparator.mlmodelc D:\IPA Project\a\flutter_appcoba\assets\models\
```

### Step 4: Update pubspec.yaml

```yaml
flutter:
  assets:
    - assets/models/StandardSeparator.mlmodelc/
    - assets/models/LightSeparator.mlmodelc/
    - assets/audio/click-downbeat.m4a
    - assets/audio/click-upbeat.m4a

dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.10.0
  just_audio: ^0.9.0
  path_provider: ^2.0.0
  file_picker: ^5.0.0
```

### Step 5: Implement Model Manager

Lihat **FLUTTER_MODEL_INTEGRATION.md** untuk kode lengkap.

## 🚀 Quick Start (30 Menit)

1. **Download Demucs** (5 min)
   ```bash
   pip install demucs
   ```

2. **Convert Model** (10 min)
   ```bash
   python convert_model.py
   ```

3. **Copy ke Flutter** (2 min)
   ```bash
   cp StandardSeparator.mlmodelc assets/models/
   ```

4. **Update pubspec.yaml** (3 min)
   ```yaml
   assets:
     - assets/models/StandardSeparator.mlmodelc/
   ```

5. **Implement Model Manager** (10 min)
   - Copy code dari FLUTTER_MODEL_INTEGRATION.md
   - Update UI untuk use model

## 📊 Model Comparison

| Model | Quality | Speed | Size | Best For |
|-------|---------|-------|------|----------|
| Demucs MDX | Very High | 10-15s | 500MB | Best quality |
| Demucs MDX Extra | Excellent | 15-20s | 800MB | Professional |
| Spleeter 2stems | Good | 8-12s | 300MB | Fast |
| Spleeter 4stems | Better | 12-18s | 400MB | Balanced |

## ⚠️ Important Notes

1. **Model Size**: Demucs MDX ~500MB, pastikan storage cukup
2. **Memory**: Butuh 300-400MB RAM saat inference
3. **Speed**: Tergantung device, 10-30 detik untuk 4 menit lagu
4. **iOS Only**: CoreML hanya untuk iOS, Android perlu TensorFlow Lite

## 🔧 Troubleshooting

### Model tidak load
```dart
// Debug
print('Model path: ${await getApplicationDocumentsDirectory()}');
print('Assets: ${await rootBundle.loadString('assets/models/...')}');
```

### Inference crash
- Gunakan light model
- Kurangi batch size
- Monitor memory

### Audio quality buruk
- Verify STFT parameters
- Check window function
- Validate iSTFT

## 📚 Resources

- **Demucs**: https://github.com/facebookresearch/demucs
- **Spleeter**: https://github.com/deezer/spleeter
- **TFLite Flutter**: https://pub.dev/packages/tflite_flutter
- **Full Guide**: See FLUTTER_MODEL_INTEGRATION.md

## ✅ Checklist

- [ ] Download Demucs
- [ ] Convert model to CoreML
- [ ] Copy model to Flutter assets
- [ ] Update pubspec.yaml
- [ ] Implement ModelManager
- [ ] Test on simulator
- [ ] Test on device
- [ ] Optimize performance

## 🎯 Next Steps

1. **Download Model** (30 min)
   ```bash
   pip install demucs
   python convert_model.py
   ```

2. **Integrate to Flutter** (1 hour)
   - Copy model
   - Update pubspec.yaml
   - Implement ModelManager

3. **Test** (30 min)
   - Test on simulator
   - Test on device
   - Verify audio quality

**Total Time**: ~2 hours untuk siap jalan

---

**Status**: Ready to implement

**Estimated Completion**: 2 hours

**Support**: See FLUTTER_MODEL_INTEGRATION.md for detailed code
