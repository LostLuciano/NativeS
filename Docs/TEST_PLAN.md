# Test Plan - MusicStemNative

## Test Categories

### 1. Separation Speed Test

**Objective**: Verify separation completes within target time

**Test Case 1.1: 4-minute song**
- Input: 4-minute stereo audio, 44.1kHz, 20MB
- Expected: Separation completes in 20-30 seconds
- Metrics:
  - STFT time: < 2s
  - Inference time: < 15s
  - iSTFT time: < 3s
  - Write time: < 2s

**Test Case 1.2: 10-minute song**
- Input: 10-minute stereo audio
- Expected: Uses light model, completes in 40-60 seconds
- Verify: Model routing policy selects light model

**Test Case 1.3: Low RAM device**
- Input: 4-minute song on device with < 3.5GB RAM
- Expected: Uses light model automatically
- Verify: Model selection logs show light model used

### 2. Output Quality Test

**Objective**: Verify separated stems are valid and usable

**Test Case 2.1: Duration matching**
- Input: 4-minute song
- Expected: Each stem duration within ±1.5 seconds of original
- Verify: Check analysis.json duration field

**Test Case 2.2: No clipping**
- Input: Various audio levels
- Expected: Peak level < 0.98 in all stems
- Verify: Limiter prevents clipping

**Test Case 2.3: No silence**
- Input: Normal music
- Expected: RMS > 0.0001 for all stems
- Verify: Validation rejects silent stems

**Test Case 2.4: Stereo preservation**
- Input: Stereo audio
- Expected: Stems maintain stereo image
- Verify: Listen to stems, verify L/R separation

### 3. Mixer Sync Test

**Objective**: Verify multitrack playback stays synchronized

**Test Case 3.1: Play all stems**
- Action: Load project, tap play
- Expected: All stems start together
- Verify: No audible delay between stems

**Test Case 3.2: Seek synchronization**
- Action: Seek to 1:30, then 3:00
- Expected: All stems seek to same position
- Verify: No audible glitch or desync

**Test Case 3.3: Mute/Solo**
- Action: Mute vocals, then solo drums
- Expected: Instant response, no audio glitch
- Verify: Volume changes immediately

**Test Case 3.4: Loop A/B**
- Action: Set loop points, enable loop
- Expected: Seamless loop, no click
- Verify: Listen for artifacts at loop boundary

### 4. CPU Safety Test

**Objective**: Verify no watchdog crashes or thermal issues

**Test Case 4.1: No cpu_resource_fatal**
- Action: Separate 4-minute song
- Expected: No crash, no watchdog timeout
- Verify: App stays responsive, no force quit

**Test Case 4.2: Memory pressure**
- Action: Separate multiple songs in sequence
- Expected: Memory released between jobs
- Verify: Memory usage returns to baseline

**Test Case 4.3: Thermal throttling**
- Action: Separate song on warm device
- Expected: Graceful degradation, no crash
- Verify: Thermal state monitored, light model used if needed

**Test Case 4.4: Low power mode**
- Action: Enable low power mode, separate song
- Expected: Uses light model, completes successfully
- Verify: Model routing respects low power mode

### 5. UI/UX Test

**Test Case 5.1: Import flow**
- Action: Tap Import, select audio file
- Expected: File info displays correctly
- Verify: Duration, sample rate, channels shown

**Test Case 5.2: Progress display**
- Action: Start separation
- Expected: Progress ring animates, stage updates
- Verify: Progress reaches 100%, stage shows "Complete"

**Test Case 5.3: Cancel job**
- Action: Start separation, tap Cancel
- Expected: Job stops, returns to import
- Verify: No partial stems left behind

**Test Case 5.4: Settings**
- Action: Change buffer size, sample rate
- Expected: Settings persist
- Verify: Reload app, settings retained

### 6. Error Handling Test

**Test Case 6.1: Invalid audio file**
- Input: Non-audio file (e.g., .txt)
- Expected: Error alert shown
- Verify: User can retry with valid file

**Test Case 6.2: Insufficient storage**
- Action: Fill device storage, try separation
- Expected: Error alert, graceful failure
- Verify: No partial files left

**Test Case 6.3: Model loading failure**
- Action: Delete model file, try separation
- Expected: Error alert or fallback
- Verify: Appropriate error message

**Test Case 6.4: Audio engine failure**
- Action: Interrupt audio session, try playback
- Expected: Graceful recovery
- Verify: Can resume playback after interruption

## Performance Benchmarks

### Target Metrics

| Metric | Target | Acceptable |
|--------|--------|-----------|
| Separation time (4min) | 25s | < 40s |
| Memory peak | 400MB | < 600MB |
| CPU usage | 60% | < 80% |
| Thermal state | Normal | < Serious |
| Mixer latency | < 50ms | < 100ms |

### Device Targets

- iPhone 13 Pro (baseline)
- iPhone 12 (mid-range)
- iPhone SE (low-end)
- iPad Pro (high-end)

## Test Execution

### Manual Testing

```bash
# Run on device
1. Build and install via Xcode
2. Execute test cases manually
3. Log results in TEST_RESULTS.md
```

### Automated Testing

```bash
# Unit tests
xcodebuild test -project MusicStemNative.xcodeproj -scheme MusicStemNative

# Performance tests
xcodebuild test -project MusicStemNative.xcodeproj -scheme MusicStemNativePerformance
```

## Test Results Template

```markdown
# Test Results - [Date]

## Device: [Model] - iOS [Version]

### Separation Speed Test
- [ ] Test 1.1: PASS/FAIL - [Time]
- [ ] Test 1.2: PASS/FAIL - [Time]
- [ ] Test 1.3: PASS/FAIL - [Time]

### Output Quality Test
- [ ] Test 2.1: PASS/FAIL
- [ ] Test 2.2: PASS/FAIL
- [ ] Test 2.3: PASS/FAIL
- [ ] Test 2.4: PASS/FAIL

### Mixer Sync Test
- [ ] Test 3.1: PASS/FAIL
- [ ] Test 3.2: PASS/FAIL
- [ ] Test 3.3: PASS/FAIL
- [ ] Test 3.4: PASS/FAIL

### CPU Safety Test
- [ ] Test 4.1: PASS/FAIL
- [ ] Test 4.2: PASS/FAIL
- [ ] Test 4.3: PASS/FAIL
- [ ] Test 4.4: PASS/FAIL

### UI/UX Test
- [ ] Test 5.1: PASS/FAIL
- [ ] Test 5.2: PASS/FAIL
- [ ] Test 5.3: PASS/FAIL
- [ ] Test 5.4: PASS/FAIL

### Error Handling Test
- [ ] Test 6.1: PASS/FAIL
- [ ] Test 6.2: PASS/FAIL
- [ ] Test 6.3: PASS/FAIL
- [ ] Test 6.4: PASS/FAIL

## Summary
- Total: [X] tests
- Passed: [X]
- Failed: [X]
- Notes: [...]
```
