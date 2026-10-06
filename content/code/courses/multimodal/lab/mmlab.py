"""mmlab: where the lab's models are, and the four lines each one takes to load.

Every program in the lessons imports what it needs from here, so that a
listing shows what the program DOES with a model rather than the paths to its
files. Nothing in this module changes what a model says: it loads it with the
settings named below and hands it over. Lesson 1 section 07 prints it whole.
"""
import os
import subprocess

import numpy as np
import sherpa_onnx

SHARE = os.environ.get("MM_SHARE", "/opt/multimodal/share")
RATE = 16000


def read_audio(path, rate=RATE):
    """Any file ffmpeg can open, as mono float samples at `rate` per second."""
    raw = subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-i", path, "-f", "f32le",
                          "-ac", "1", "-ar", str(rate), "-"], check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32)


def whisper(size="base", language="", task="transcribe", int8=True):
    """OpenAI's Whisper, exported to ONNX by sherpa-onnx: `tiny` or `base`, int8 unless asked otherwise."""
    d = os.path.join(SHARE, f"sherpa-onnx-whisper-{size}")
    q = ".int8" if int8 else ""
    return sherpa_onnx.OfflineRecognizer.from_whisper(
        encoder=f"{d}/{size}-encoder{q}.onnx", decoder=f"{d}/{size}-decoder{q}.onnx",
        tokens=f"{d}/{size}-tokens.txt", language=language, task=task, num_threads=2)


def transcribe(recognizer, samples, rate=RATE):
    """One stream, one decode: the text and the language Whisper decided it heard."""
    s = recognizer.create_stream()
    s.accept_waveform(rate, samples)
    recognizer.decode_stream(s)
    return s.result.text.strip(), s.result.lang


def piper(name, noise=False):
    """A Piper voice, such as en_US-lessac-medium. noise=False makes it say a text the same way twice."""
    d = os.path.join(SHARE, f"vits-piper-{name}")
    kw = {} if noise else {"noise_scale": 0.0, "noise_scale_w": 0.0}
    model = sherpa_onnx.OfflineTtsVitsModelConfig(
        model=f"{d}/{name}.onnx", tokens=f"{d}/tokens.txt", data_dir=f"{d}/espeak-ng-data", **kw)
    return sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(vits=model, num_threads=2)))


def speech_segments(samples, rate=RATE, min_silence=0.25, min_speech=0.25):
    """Silero VAD over the whole recording: a list of (start, end) in seconds."""
    cfg = sherpa_onnx.VadModelConfig()
    cfg.silero_vad.model = os.path.join(SHARE, "silero_vad.onnx")
    cfg.silero_vad.min_silence_duration = min_silence
    cfg.silero_vad.min_speech_duration = min_speech
    cfg.sample_rate = rate
    vad = sherpa_onnx.VoiceActivityDetector(cfg, buffer_size_in_seconds=len(samples) / rate + 1)
    window = cfg.silero_vad.window_size
    out = []
    for i in range(0, len(samples), window):
        vad.accept_waveform(samples[i:i + window])
        while not vad.empty():
            out.append((vad.front.start / rate, (vad.front.start + len(vad.front.samples)) / rate))
            vad.pop()
    vad.flush()
    while not vad.empty():
        out.append((vad.front.start / rate, (vad.front.start + len(vad.front.samples)) / rate))
        vad.pop()
    return out


def diarizer(threshold=0.5, speakers=-1):
    """pyannote's segmentation 3.0 and 3D-Speaker's ERes2Net embeddings, clustered."""
    seg = sherpa_onnx.OfflineSpeakerSegmentationModelConfig(
        pyannote=sherpa_onnx.OfflineSpeakerSegmentationPyannoteModelConfig(
            model=os.path.join(SHARE, "sherpa-onnx-pyannote-segmentation-3-0", "model.onnx")))
    emb = sherpa_onnx.SpeakerEmbeddingExtractorConfig(
        model=os.path.join(SHARE, "3dspeaker_speech_eres2net_base_sv_zh-cn_3dspeaker_16k.onnx"))
    return sherpa_onnx.OfflineSpeakerDiarization(sherpa_onnx.OfflineSpeakerDiarizationConfig(
        segmentation=seg, embedding=emb,
        clustering=sherpa_onnx.FastClusteringConfig(num_clusters=speakers, threshold=threshold),
        min_duration_on=0.3, min_duration_off=0.5))


def denoiser():
    """GTCRN, a speech enhancement model of 48 thousand parameters."""
    return sherpa_onnx.OfflineSpeechDenoiser(sherpa_onnx.OfflineSpeechDenoiserConfig(
        model=sherpa_onnx.OfflineSpeechDenoiserModelConfig(
            gtcrn=sherpa_onnx.OfflineSpeechDenoiserGtcrnModelConfig(
                model=os.path.join(SHARE, "gtcrn_simple.onnx")))))


def detector(score=0.3):
    """MediaPipe's object detector with EfficientDet-Lite0, trained on the 80 classes of COCO."""
    from mediapipe.tasks.python import BaseOptions
    from mediapipe.tasks.python import vision
    return vision.ObjectDetector.create_from_options(vision.ObjectDetectorOptions(
        base_options=BaseOptions(model_asset_path=os.path.join(SHARE, "efficientdet_lite0.tflite")),
        score_threshold=score))
