"""Generate a short pixel-style crumble for the breakable block."""

from __future__ import annotations

import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "audio" / "sfx" / "environment" / "blocks" / "block_break.wav"
SAMPLE_RATE = 22_050
DURATION = 0.28


def main() -> None:
    random_source = random.Random(41)
    samples: list[int] = []
    smooth_noise = 0.0

    for sample_index in range(round(SAMPLE_RATE * DURATION)):
        time = sample_index / SAMPLE_RATE
        progress = time / DURATION
        envelope = (1.0 - progress) ** 2.2

        raw_noise = random_source.uniform(-1.0, 1.0)
        smooth_noise += 0.32 * (raw_noise - smooth_noise)

        low_crack = math.sin(math.tau * (105.0 - 45.0 * progress) * time)
        impact = 1.0 if time < 0.018 else 0.0
        debris_pulse = 1.0 if int(time * 46.0) % 3 == 0 else 0.42

        value = envelope * (
            0.34 * smooth_noise * debris_pulse
            + 0.13 * low_crack
            + 0.16 * raw_noise * impact
        )
        value = max(-1.0, min(1.0, value))
        samples.append(round(value * 32_767))

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUTPUT), "wb") as output_file:
        output_file.setnchannels(1)
        output_file.setsampwidth(2)
        output_file.setframerate(SAMPLE_RATE)
        output_file.writeframes(struct.pack(f"<{len(samples)}h", *samples))

    print(f"Created {OUTPUT.relative_to(ROOT)} ({DURATION:.2f}s)")


if __name__ == "__main__":
    main()
