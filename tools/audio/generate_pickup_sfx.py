"""Generate the short retro sounds used by the collectible items."""

from __future__ import annotations

import math
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIRECTORY = ROOT / "audio" / "sfx" / "pickups"
SAMPLE_RATE = 22_050


def square_wave(frequency: float, time: float) -> float:
    return 1.0 if math.sin(math.tau * frequency * time) >= 0.0 else -1.0


def write_sound(filename: str, duration: float, sample_function) -> None:
    samples: list[int] = []
    sample_count = round(SAMPLE_RATE * duration)

    for sample_index in range(sample_count):
        time = sample_index / SAMPLE_RATE
        value = max(-1.0, min(1.0, sample_function(time, duration)))
        samples.append(round(value * 32_767))

    output_path = OUTPUT_DIRECTORY / filename
    OUTPUT_DIRECTORY.mkdir(parents=True, exist_ok=True)

    with wave.open(str(output_path), "wb") as output_file:
        output_file.setnchannels(1)
        output_file.setsampwidth(2)
        output_file.setframerate(SAMPLE_RATE)
        output_file.writeframes(struct.pack(f"<{len(samples)}h", *samples))

    print(f"Created {output_path.relative_to(ROOT)} ({duration:.2f}s)")


def coin_sample(time: float, duration: float) -> float:
    frequency = 880.0 if time < duration * 0.45 else 1_320.0
    envelope = (1.0 - time / duration) ** 0.65
    return square_wave(frequency, time) * envelope * 0.20


def heart_sample(time: float, duration: float) -> float:
    notes = (523.25, 659.25, 783.99)
    note_index = min(int(time / (duration / len(notes))), len(notes) - 1)
    frequency = notes[note_index]
    envelope = math.sin(math.pi * time / duration) ** 0.65
    tone = 0.75 * math.sin(math.tau * frequency * time)
    sparkle = 0.25 * square_wave(frequency * 2.0, time)
    return (tone + sparkle) * envelope * 0.22


def main() -> None:
    write_sound("coin_collect.wav", 0.18, coin_sample)
    write_sound("heart_collect.wav", 0.36, heart_sample)


if __name__ == "__main__":
    main()
