"""Music and sounds of the Halloween edition (Client/Sounds), all synthesized here with numpy: no samples.

- music_main.ogg: "In the Hall of the Mountain King" (Grieg, 1875, public domain) as a spooky march: pizzicato
  bass, a bone xylophone, a church organ, a ghostly choir and a theremin. A seamless loop.
- music_finale.ogg: the same theme, much faster and louder, for the last minute of a game.
- goal_*.ogg: four goal stingers (Bach's Toccata in D minor on the organ, bells and choir, a theremin wail,
  a skeleton xylophone run). end_organ.ogg: the whole Toccata opening, when the time runs out.
- countdown_tick.ogg / countdown_go.ogg, thunder_*.ogg, owl.ogg, wolf_howl.ogg, bonk_*.ogg.

Usage: python tools/make_sounds.py [output folder, default Client/Sounds]
Needs numpy, scipy and ffmpeg (on the PATH, or its path in the FFMPEG environment variable).
"""
import os
import subprocess
import sys

import numpy as np
from scipy import signal

SR = 44100
RNG = np.random.default_rng(1031)
OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "Client", "Sounds")
FFMPEG = os.environ.get("FFMPEG", "ffmpeg")


def hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def seconds(n):
    return np.arange(int(n * SR)) / SR


def fade(n, attack, release, total=None):
    """Linear attack and release envelope over n samples."""
    t = np.arange(n) / SR
    total = total if total is not None else n / SR
    return np.clip(t / max(attack, 1e-4), 0, 1) * np.clip((total - t) / max(release, 1e-4), 0, 1)


def lowpass(x, cutoff, order=2):
    sos = signal.butter(order, min(cutoff, SR * 0.45), "low", fs=SR, output="sos")
    return signal.sosfilt(sos, x, axis=0)


def highpass(x, cutoff, order=2):
    sos = signal.butter(order, cutoff, "high", fs=SR, output="sos")
    return signal.sosfilt(sos, x, axis=0)


def bandpass(x, low, high, order=2):
    sos = signal.butter(order, (low, min(high, SR * 0.45)), "band", fs=SR, output="sos")
    return signal.sosfilt(sos, x, axis=0)


# --- Instruments: each returns a mono note, its tail included -----------------------------------------------

def organ(f, dur, full=1.0):
    """Church organ: drawbars (16', 8', 4', 2 2/3', 2', 1 1/3', 1') slightly detuned in pairs, a tremulant."""
    n = int((dur + 0.12) * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for ratio, amp in ((0.5, 0.55 * full), (1, 1.0), (2, 0.65), (3, 0.3), (4, 0.4 * full), (6, 0.16 * full), (8, 0.13 * full)):
        if f * ratio > 11000:
            continue
        for detune in (-0.0011, 0.0011):
            out += amp * 0.5 * np.sin(2 * np.pi * f * ratio * (1 + detune) * t + RNG.uniform(0, 2 * np.pi))
    out *= 1 + 0.045 * np.sin(2 * np.pi * 5.4 * t)
    return out * fade(n, 0.02, 0.1) * 0.22


def xylophone(f, dur=None, hardness=1.0):
    """Hard wooden (bony) bars: a few inharmonic partials dying fast, a click on the strike."""
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    out = np.sin(2 * np.pi * f * t) * np.exp(-t / 0.28)
    out += 0.4 * hardness * np.sin(2 * np.pi * f * 3.93 * t) * np.exp(-t / 0.09)
    out += 0.15 * hardness * np.sin(2 * np.pi * f * 9.0 * t) * np.exp(-t / 0.035)
    click = highpass(RNG.standard_normal(n), 2500) * np.exp(-t / 0.004) * 0.25 * hardness
    return (out + click) * 0.5


def pluck(f, dur, bright=1.0, decay=0.9):
    """Plucked string (harpsichord when bright, pizzicato when dark): harmonics dying faster as they rise."""
    n = int((dur + decay) * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for k in range(1, 14):
        if f * k > 12000:
            break
        amp = (1 / k ** (1.6 - 0.6 * bright)) * (1 if k == 1 else bright)
        out += amp * np.sin(2 * np.pi * f * k * t + RNG.uniform(0, 1)) * np.exp(-t * (1 + 0.7 * k) / decay)
    stop = np.clip((dur + 0.05 - t) / 0.06, 0, 1) * 0.85 + 0.15
    return out * stop * fade(n, 0.002, 0.03) * 0.35


def choir(f, dur, vowel="oo", voices=3):
    """A ghostly choir: harmonics shaped by the vowel's formants, a few voices slightly apart, slow swell."""
    formants = {"oo": ((300, 1.0, 90), (870, 0.4, 110), (2240, 0.1, 160)),
                "ah": ((730, 1.0, 110), (1090, 0.6, 120), (2440, 0.25, 170)),
                "oh": ((570, 1.0, 100), (840, 0.5, 110), (2410, 0.12, 160))}[vowel]
    n = int((dur + 0.6) * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for v in range(voices):
        cents = (v - (voices - 1) / 2) * 9
        fv = f * 2 ** (cents / 1200)
        vib = 1 + 0.006 * np.sin(2 * np.pi * (4.8 + 0.4 * v) * t + v)
        phase = 2 * np.pi * np.cumsum(fv * vib) / SR
        for k in range(1, 40):
            fk = fv * k
            if fk > 5000:
                break
            amp = sum(a * np.exp(-((fk - F) / bw) ** 2) for F, a, bw in formants) + 0.02 / k
            out += amp * np.sin(k * phase + RNG.uniform(0, 6.28))
    return out * fade(n, min(0.35, dur * 0.4), 0.5) * 0.09


def theremin(path, vibrato=0.012):
    """path: [(seconds, note)] key points; the pitch glides between them."""
    total = path[-1][0]
    n = int((total + 0.3) * SR)
    t = np.arange(n) / SR
    times = [p[0] for p in path]
    notes = [p[1] for p in path]
    pitch = np.interp(t, times, notes)
    freq = 440 * 2 ** ((pitch - 69) / 12) * (1 + vibrato * np.sin(2 * np.pi * 6.2 * t))
    phase = 2 * np.pi * np.cumsum(freq) / SR
    out = np.sin(phase) + 0.18 * np.sin(2 * phase) + 0.06 * np.sin(3 * phase)
    return out * fade(n, 0.15, 0.4, total + 0.3) * 0.22


def timpani(f, strength=1.0):
    n = int(1.8 * SR)
    t = np.arange(n) / SR
    bend = 1 + 0.06 * np.exp(-t * 25)
    out = np.zeros(n)
    for ratio, amp, tau in ((1, 1.0, 0.9), (1.5, 0.45, 0.5), (1.98, 0.3, 0.35), (2.44, 0.18, 0.25)):
        out += amp * np.sin(2 * np.pi * f * ratio * np.cumsum(bend) / SR) * np.exp(-t / tau)
    out += lowpass(RNG.standard_normal(n), 900) * np.exp(-t / 0.03) * 0.6
    return out * 0.5 * strength


def kick():
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    freq = 48 + 110 * np.exp(-t * 28)
    return np.sin(2 * np.pi * np.cumsum(freq) / SR) * np.exp(-t / 0.18) * 0.9


def snare():
    n = int(0.3 * SR)
    t = np.arange(n) / SR
    body = np.sin(2 * np.pi * 185 * t) * np.exp(-t / 0.05)
    rattle = bandpass(RNG.standard_normal(n), 1500, 8000) * np.exp(-t / 0.11)
    return (body * 0.5 + rattle * 0.6) * 0.6


def hat(open_=False):
    n = int((0.35 if open_ else 0.08) * SR)
    t = np.arange(n) / SR
    return highpass(RNG.standard_normal(n), 7000, 4) * np.exp(-t / (0.12 if open_ else 0.022)) * 0.22


def crash():
    n = int(2.5 * SR)
    t = np.arange(n) / SR
    noise = highpass(RNG.standard_normal(n), 3500, 2)
    ring = sum(np.sin(2 * np.pi * f * t) for f in (3150, 4370, 5210, 6890)) * 0.05
    return (noise + ring) * np.exp(-t / 0.75) * 0.35


def bell(f, length=6.0):
    """Church bell: hum, prime, minor third, fifth, nominal and the upper partials, each with its own decay."""
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for ratio, amp, tau in ((0.5, 0.7, 3.5), (1.0, 1.0, 2.6), (1.2, 0.55, 1.9), (1.5, 0.35, 1.4), (2.0, 0.6, 1.2),
                            (2.51, 0.25, 0.8), (2.66, 0.2, 0.7), (3.01, 0.18, 0.5), (4.16, 0.12, 0.3)):
        beat = 1 + 0.002 * np.sin(2 * np.pi * 0.7 * t)
        out += amp * np.sin(2 * np.pi * f * ratio * beat * t + RNG.uniform(0, 6)) * np.exp(-t / tau)
    strike = bandpass(RNG.standard_normal(n), 800, 5000) * np.exp(-t / 0.01) * 0.4
    return (out + strike) * 0.3


# --- Mixing --------------------------------------------------------------------------------------------------

class Track:
    """A stereo buffer notes are added into; time in beats at a fixed tempo."""

    def __init__(self, beats, bpm, tail=6.0):
        self.bpm = bpm
        self.length = beats * 60 / bpm
        self.buf = np.zeros((int((self.length + tail) * SR), 2))

    def at(self, beat):
        return beat * 60 / self.bpm

    def add(self, sound, beat=None, time=None, gain=1.0, pan=0.0):
        start = int((time if time is not None else self.at(beat)) * SR)
        if start >= len(self.buf):
            return
        sound = sound[:len(self.buf) - start]
        left, right = np.cos((pan + 1) * np.pi / 4), np.sin((pan + 1) * np.pi / 4)
        self.buf[start:start + len(sound), 0] += sound * gain * left * 1.414
        self.buf[start:start + len(sound), 1] += sound * gain * right * 1.414


def impulse_response(length, bright=7000, dark=1200, predelay=0.025):
    n = int(length * SR)
    t = np.arange(n) / SR
    ir = np.zeros((n, 2))
    for ch in range(2):
        noise = RNG.standard_normal(n)
        k = t / length
        ir[:, ch] = (lowpass(noise, bright) * (1 - k) + lowpass(noise, dark) * k) * np.exp(-6.9 * t / length)
    ir = np.vstack([np.zeros((int(predelay * SR), 2)), ir])
    return ir / np.sqrt(np.sum(ir ** 2, axis=0))


def reverb(x, length=2.6, wet=0.25, **kw):
    ir = impulse_response(length, **kw)
    wet_sig = np.stack([signal.fftconvolve(x[:, ch], ir[:, ch]) for ch in range(2)], axis=1)
    out = np.zeros_like(wet_sig)
    out[:len(x)] += x
    return out + wet_sig * wet


def master(x, peak=0.89, drive=1.4):
    x = highpass(x, 28)
    x = x / (np.max(np.abs(x)) + 1e-9)
    x = np.tanh(x * drive) / np.tanh(drive)
    return x * peak


def loop(track, rev_length=2.4, wet=0.22):
    """Seamless loop: everything ringing past the end (notes, reverb) wraps round onto the start."""
    x = reverb(track.buf, rev_length, wet)
    n = int(track.length * SR)
    out = x[:n].copy()
    rest = x[n:]
    while len(rest):
        k = min(n, len(rest))
        out[:k] += rest[:k]
        rest = rest[k:]
    return out


def save(name, x):
    os.makedirs(OUT_DIR, exist_ok=True)
    path = os.path.join(OUT_DIR, name)
    pcm = (np.clip(x, -1, 1) * 32767).astype("<i2")
    if pcm.ndim == 1:
        pcm = np.stack([pcm, pcm], axis=1)
    subprocess.run([FFMPEG, "-y", "-loglevel", "error", "-f", "s16le", "-ar", str(SR), "-ac", "2", "-i", "-",
                    "-c:a", "libvorbis", "-q:a", "5", path], input=pcm.tobytes(), check=True)
    print("%-22s %5.1f s" % (name, len(pcm) / SR))


# --- In the Hall of the Mountain King (Grieg) -----------------------------------------------------------------
# The theme in B minor as (note, eighths); None is a rest. A twice, B a fifth up, then A ending on the tonic

A = [(59, 1), (61, 1), (62, 1), (64, 1), (66, 1), (62, 1), (66, 2),
     (65, 1), (61, 1), (65, 2), (64, 1), (60, 1), (64, 2),
     (59, 1), (61, 1), (62, 1), (64, 1), (66, 1), (62, 1), (66, 1), (71, 1),
     (69, 1), (66, 1), (62, 1), (66, 1), (69, 4)]
B = [(66, 1), (68, 1), (70, 1), (71, 1), (73, 1), (70, 1), (73, 2),
     (74, 1), (70, 1), (74, 2), (73, 1), (70, 1), (73, 2),
     (66, 1), (68, 1), (70, 1), (71, 1), (73, 1), (70, 1), (73, 1), (78, 1),
     (76, 1), (73, 1), (70, 1), (73, 1), (76, 4)]
A_END = A[:-1] + [(71, 2), (None, 2)]
THEME = A + A + B + A_END

# Chords by half bar (root of the bass, chord notes): a creepy chromatic harmony under the tune
Bm, Cs, C, D, Fs, Daug, Fs7 = (35, (59, 62, 66)), (37, (61, 65, 68)), (36, (60, 64, 67)), (38, (62, 66, 69)), \
    (42, (61, 66, 70)), (38, (62, 66, 70)), (42, (64, 66, 70))
CHORDS_A = [Bm, Bm, Cs, C, Bm, Bm, D, Fs]
CHORDS_B = [Fs, Fs, Daug, Fs, Fs, Fs, Fs7, Fs7]
CHORDS_END = [Bm, Bm, Cs, C, Bm, Bm, D, Bm]
CHORDS = CHORDS_A + CHORDS_A + CHORDS_B + CHORDS_END   # 32 half bars = 16 bars


def melody_events(theme, start_beat):
    beat = start_beat
    for note, eighths in theme:
        if note is not None:
            yield beat, note, eighths * 0.5
        beat += eighths * 0.5


def music_main():
    bpm = 132
    tr = Track(beats=128, bpm=bpm)
    eighth = 60 / bpm / 2
    for cycle in range(2):
        base = cycle * 64
        full = cycle == 1
        # Melody: bone xylophone the first time, organ (and xylophone an octave up) the second
        for beat, note, length in melody_events(THEME, base):
            if not full:
                tr.add(xylophone(hz(note + 12)), beat, gain=0.55, pan=-0.2)
                tr.add(pluck(hz(note), length * eighth * 2, bright=1.0, decay=0.6), beat, gain=0.35, pan=0.25)
            else:
                tr.add(organ(hz(note), length * eighth * 2 * 0.92), beat, gain=0.55, pan=0.1)
                tr.add(xylophone(hz(note + 12), hardness=0.8), beat, gain=0.32, pan=-0.35)
        for half, (root, notes) in enumerate(CHORDS):
            beat = base + half * 2
            # Oom-pah: pizzicato root on the beat, a short harpsichord chord on the off beat
            tr.add(pluck(hz(root), 0.25, bright=0.25, decay=0.5), beat, gain=0.9)
            tr.add(pluck(hz(root + 7), 0.25, bright=0.25, decay=0.5), beat + 1, gain=0.6)
            for k, note in enumerate(notes):
                tr.add(pluck(hz(note - 12), 0.12, bright=0.8, decay=0.25), beat + 0.5, gain=0.18, pan=-0.5 + k * 0.4)
                tr.add(pluck(hz(note - 12), 0.12, bright=0.8, decay=0.25), beat + 1.5, gain=0.14, pan=-0.5 + k * 0.4)
            # The choir holds the chords, softly the first time
            if half % 2 == 0:
                for k, note in enumerate(notes):
                    tr.add(choir(hz(note - 12), 4 * 60 / bpm, "ah" if full else "oo"), beat, gain=0.55 if full else 0.35,
                           pan=-0.6 + k * 0.6)
        for bar in range(16):
            beat = base + bar * 4
            if not full:
                if bar % 4 == 0:
                    tr.add(timpani(hz(35)), beat, gain=0.7)
                for k in range(4):
                    tr.add(hat(), beat + k + 0.5, gain=0.5, pan=0.4)
            else:
                tr.add(kick(), beat, gain=0.8)
                tr.add(kick(), beat + 2, gain=0.7)
                tr.add(snare(), beat + 1, gain=0.55, pan=0.1)
                tr.add(snare(), beat + 3, gain=0.6, pan=0.1)
                for k in range(8):
                    tr.add(hat(open_=k == 7), beat + k * 0.5, gain=0.45 if k % 2 else 0.3, pan=0.45)
                if bar % 8 == 0:
                    tr.add(crash(), beat, gain=0.55, pan=-0.3)
        # The theremin floats over the B section the second time
        if full:
            start = tr.at(base + 32)
            bar_s = 4 * 60 / bpm
            tr.add(theremin([(0, 78), (bar_s * 0.9, 78), (bar_s, 82), (bar_s * 1.9, 82), (bar_s * 2, 85), (bar_s * 2.9, 85),
                             (bar_s * 3.2, 88), (bar_s * 3.95, 76)]), time=start, gain=0.5, pan=0.3)
    # Timpani roll into the loop
    for k in range(8):
        tr.add(timpani(hz(42), 0.35 + k * 0.06), 128 - 2 + k * 0.25, gain=0.6)
    save("music_main.ogg", master(loop(tr)))


def music_finale():
    bpm = 168
    tr = Track(beats=128, bpm=bpm)
    eighth = 60 / bpm / 2
    for cycle in range(2):
        base = cycle * 64
        for beat, note, length in melody_events(THEME, base):
            tr.add(organ(hz(note), length * eighth * 2 * 0.9, full=1.3), beat, gain=0.5, pan=0.15)
            tr.add(organ(hz(note + 12), length * eighth * 2 * 0.9), beat, gain=0.28, pan=-0.15)
            tr.add(xylophone(hz(note + 12)), beat, gain=0.35, pan=-0.4)
        for half, (root, notes) in enumerate(CHORDS):
            beat = base + half * 2
            for k in range(4):   # pumping eighth-note bass
                tr.add(pluck(hz(root), 0.18, bright=0.35, decay=0.35), beat + k * 0.5, gain=0.85 if k % 2 == 0 else 0.6)
            for k, note in enumerate(notes):
                tr.add(choir(hz(note - 12), 2 * 60 / bpm, "ah"), beat, gain=0.6, pan=-0.6 + k * 0.6)
            tr.add(organ(hz(root + 12), 2 * 60 / bpm * 0.95, full=1.4), beat, gain=0.25)
        for bar in range(16):
            beat = base + bar * 4
            for k in range(4):
                tr.add(kick(), beat + k, gain=0.85)
            tr.add(snare(), beat + 1, gain=0.65, pan=0.1)
            tr.add(snare(), beat + 3, gain=0.7, pan=0.1)
            for k in range(16):
                tr.add(hat(), beat + k * 0.25, gain=0.3 if k % 2 else 0.42, pan=0.45)
            if bar % 4 == 0:
                tr.add(crash(), beat, gain=0.6, pan=-0.3)
                tr.add(timpani(hz(35), 1.2), beat, gain=0.8)
            if bar % 8 == 7:
                for k in range(8):
                    tr.add(timpani(hz(42), 0.4 + k * 0.08), beat + 2 + k * 0.25, gain=0.7)
        start = tr.at(base + 32)
        bar_s = 4 * 60 / bpm
        tr.add(theremin([(0, 83), (bar_s * 0.5, 90), (bar_s * 1.8, 88), (bar_s * 2.5, 94), (bar_s * 3.6, 78)], vibrato=0.02),
               time=start, gain=0.45, pan=0.35)
    save("music_finale.ogg", master(loop(tr, 2.0, 0.18), peak=0.92, drive=1.8))


# --- Stingers --------------------------------------------------------------------------------------------------

def toccata_phrase(tr, start, octave, full=1.0, gain=0.7):
    """A G A ... G F E D C# D: the opening of Bach's Toccata in D minor, from `start` seconds."""
    notes = [(81, 0.11), (79, 0.11), (81, 0.85), (None, 0.22), (79, 0.1), (77, 0.1), (76, 0.1), (74, 0.1), (73, 0.5),
             (74, 1.4)]
    t = start
    for note, length in notes:
        if note is not None:
            for o in (0, -12):
                tr.add(organ(hz(note + octave + o), length, full=full), time=t, gain=gain * (1 if o == 0 else 0.7))
        t += length
    return t


def stinger(name, build, length, rev=3.2, wet=0.35):
    tr = Track(beats=length * 2, bpm=120, tail=rev + 1)
    build(tr)
    x = reverb(tr.buf, rev, wet)
    n = int((length + rev) * SR)
    x = x[:n] * fade(n, 0.001, rev * 0.6)[:, None]
    save(name, master(x, peak=0.9, drive=1.2))


def goal_toccata(tr):
    t = toccata_phrase(tr, 0.0, 0, full=1.4)
    for note in (38, 50, 53, 57, 62, 65):   # D minor, pedal to the top
        tr.add(organ(hz(note), 2.2, full=1.5), time=t - 1.4, gain=0.45)
    tr.add(bell(hz(50)), time=t - 1.4, gain=0.7)
    tr.add(timpani(hz(38), 1.3), time=t - 1.4, gain=0.8)


def goal_bells(tr):
    for k, note in enumerate((62, 57, 50)):
        tr.add(bell(hz(note)), time=k * 0.7, gain=0.8, pan=(-0.4, 0.4, 0)[k])
    for k, note in enumerate((50, 57, 62, 65, 69)):
        tr.add(choir(hz(note), 3.2, "ah", voices=4), time=0.5, gain=0.9, pan=-0.6 + k * 0.3)
    tr.add(thunder_sound(5.0, crack=1.0)[:, 0], time=0.15, gain=0.6)
    tr.add(timpani(hz(38), 1.3), time=2.1, gain=0.8)


def goal_theremin(tr):
    tr.add(theremin([(0, 62), (0.5, 74), (1.4, 86), (2.4, 81), (3.2, 86), (4.0, 62)], vibrato=0.022), time=0, gain=0.9)
    for note in (38, 50, 53, 56, 59):   # diminished: no resolution, just dread
        tr.add(organ(hz(note), 3.6, full=1.2), time=0.2, gain=0.35)
    for k in range(10):
        tr.add(xylophone(hz(98 - k * 3)), time=2.6 + k * 0.07, gain=0.45, pan=-0.6 + k * 0.12)
    tr.add(crash(), time=0.2, gain=0.6)


def goal_danse(tr):
    run = [62, 65, 69, 74, 77, 81, 86, 89, 93]
    for k, note in enumerate(run + run[::-1][1:]):
        tr.add(xylophone(hz(note), hardness=1.2), time=k * 0.075, gain=0.6, pan=-0.7 + k * 0.08)
    t = len(run) * 2 * 0.075
    for note in (38, 50, 57, 62, 65, 69):
        tr.add(organ(hz(note), 1.8, full=1.4), time=t, gain=0.4)
    tr.add(crash(), time=t, gain=0.7)
    tr.add(timpani(hz(38), 1.4), time=t, gain=0.9)
    for k in range(12):
        tr.add(timpani(hz(45), 0.3 + k * 0.05), time=t + 1.9 + k * 0.08, gain=0.5)
    tr.add(timpani(hz(38), 1.5), time=t + 2.9, gain=1.0)
    tr.add(crash(), time=t + 2.9, gain=0.6)


def end_organ(tr):
    t = toccata_phrase(tr, 0.0, 0, full=1.3)
    t = toccata_phrase(tr, t - 0.6, -12, full=1.5, gain=0.75)
    t = toccata_phrase(tr, t - 0.6, -24, full=1.7, gain=0.8)
    # The diminished seventh climbing up, then the D minor chord with a pedal and a bell
    arp = [49, 52, 55, 58, 61, 64, 67, 70]
    for k, note in enumerate(arp):
        tr.add(organ(hz(note), 3.2 - k * 0.12, full=1.4), time=t - 0.3 + k * 0.12, gain=0.32)
    t += 1.4
    for note in (26, 38, 50, 53, 57, 62, 65, 69, 74):
        tr.add(organ(hz(note), 3.5, full=1.6), time=t, gain=0.36)
    tr.add(bell(hz(38), 7), time=t, gain=0.9)
    tr.add(timpani(hz(38), 1.5), time=t, gain=0.9)


def countdown_tick(tr):
    tr.add(bell(hz(57), 2.5), time=0, gain=0.5)
    n = int(0.06 * SR)
    t = np.arange(n) / SR
    tock = bandpass(RNG.standard_normal(n), 900, 3200) * np.exp(-t / 0.01)
    tr.add(tock, time=0, gain=0.7)


def countdown_go(tr):
    tr.add(bell(hz(50), 4), time=0, gain=0.9)
    for note in (38, 50, 57, 62, 65):
        tr.add(organ(hz(note), 0.9, full=1.4), time=0, gain=0.4)
    tr.add(crash(), time=0, gain=0.5)


# --- Weather and creatures ----------------------------------------------------------------------------------------

def thunder_sound(length, crack=1.0, seed=None):
    rng = np.random.default_rng(seed)
    n = int(length * SR)
    t = np.arange(n) / SR
    out = np.zeros((n, 2))
    for ch in range(2):
        brown = np.cumsum(rng.standard_normal(n))
        brown = highpass(brown, 20)
        rumble = lowpass(brown, 140, 2)
        rumble /= np.max(np.abs(rumble)) + 1e-9
        mid = bandpass(rng.standard_normal(n), 150, 900)
        mid /= np.max(np.abs(mid)) + 1e-9
        # a few rolls of rumble one after the other
        shape = np.zeros(n)
        for k in range(5):
            at = rng.uniform(0.0, length * 0.55) if k else 0.05
            width = rng.uniform(0.4, 1.4)
            shape += rng.uniform(0.5, 1.0) * np.exp(-((t - at - width) / width) ** 2)
        shape *= np.exp(-t / (length * 0.45))
        snap = highpass(rng.standard_normal(n), 1200) * np.exp(-t / 0.06) * crack * 0.7
        out[:, ch] = rumble * shape * 0.9 + mid * shape * 0.35 + snap
    return out * fade(n, 0.003, length * 0.3)[:, None]


def owl():
    tr = Track(beats=8, bpm=60, tail=3)
    for k, (at, length) in enumerate(((0.0, 0.25), (0.45, 0.25), (1.1, 0.9))):
        n = int(length * SR)
        t = np.arange(n) / SR
        f = 390 - 40 * (t / length)
        ph = 2 * np.pi * np.cumsum(f) / SR
        hoot = (np.sin(ph) + 0.12 * np.sin(2 * ph)) * fade(n, 0.06, 0.12)
        hoot += lowpass(RNG.standard_normal(n), 2000) * fade(n, 0.03, 0.1) * 0.03
        tr.add(hoot, time=at, gain=0.6)
    x = reverb(tr.buf, 2.0, 0.4)[:int(4.5 * SR)]
    return master(x, peak=0.7, drive=1.0)


def wolf_howl():
    length = 3.6
    n = int(length * SR)
    t = np.arange(n) / SR
    pitch = np.interp(t, [0, 0.5, 0.9, 2.4, 3.2, 3.6], [52, 64, 67, 66, 58, 55])
    f = 440 * 2 ** ((pitch - 69) / 12) * (1 + 0.012 * np.sin(2 * np.pi * 5.5 * t))
    ph = 2 * np.pi * np.cumsum(f) / SR
    vowel = np.clip(t / 1.2, 0, 1)   # "oo" opening to "ah"
    out = np.zeros(n)
    for k in range(1, 12):
        fk = f * k
        oo = np.exp(-((fk - 320) / 120) ** 2) + 0.4 * np.exp(-((fk - 850) / 150) ** 2)
        ah = np.exp(-((fk - 700) / 160) ** 2) + 0.6 * np.exp(-((fk - 1150) / 180) ** 2)
        out += (oo * (1 - vowel) + ah * vowel + 0.03 / k) * np.sin(k * ph)
    out += bandpass(RNG.standard_normal(n), 400, 3000) * 0.02
    out *= fade(n, 0.25, 0.9)
    tr = Track(beats=8, bpm=60, tail=4)
    tr.add(out, time=0, gain=0.8)
    x = reverb(tr.buf, 3.5, 0.55, dark=900)[:int(7 * SR)]
    return master(x * fade(len(x), 0.001, 2.5)[:, None], peak=0.8, drive=1.0)


def bonk(pitch=1.0):
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    f = (92 + 40 * np.exp(-t * 30)) * pitch
    thump = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.13)
    hollow = np.sin(2 * np.pi * 330 * pitch * t) * np.exp(-t / 0.07) * 0.35
    knock = bandpass(RNG.standard_normal(n), 700, 2600) * np.exp(-t / 0.012) * 0.5
    x = (thump + hollow + knock)
    tr = Track(beats=2, bpm=60, tail=1)
    tr.add(x, time=0)
    return master(reverb(tr.buf, 0.6, 0.12)[:int(0.8 * SR)], peak=0.85, drive=1.5)


if __name__ == "__main__":
    music_main()
    music_finale()
    stinger("goal_toccata.ogg", goal_toccata, 4.6)
    stinger("goal_bells.ogg", goal_bells, 4.5)
    stinger("goal_theremin.ogg", goal_theremin, 4.4)
    stinger("goal_danse.ogg", goal_danse, 5.0)
    stinger("end_organ.ogg", end_organ, 9.5, rev=4.0, wet=0.4)
    stinger("countdown_tick.ogg", countdown_tick, 1.2, rev=1.5, wet=0.3)
    stinger("countdown_go.ogg", countdown_go, 2.0, rev=2.5, wet=0.35)
    for k in range(3):
        x = thunder_sound((7.0, 8.5, 6.0)[k], crack=(1.0, 0.5, 0.8)[k], seed=200 + k)
        save("thunder_%d.ogg" % (k + 1), master(x, peak=0.9, drive=1.6))
    save("owl.ogg", owl())
    save("wolf_howl.ogg", wolf_howl())
    for k, p in enumerate((1.0, 0.85, 1.18)):
        save("bonk_%d.ogg" % (k + 1), bonk(p))
