"""Sound design for Moon or Coin: synthetic ambience plus a recorded coin impact.
Rebuild only: Python 3 + numpy + scipy. Running the Processing artwork needs neither.
Seeded synthesis, quiet stereo water, softened metal, fluid impact, two endings.
Recorded source: engreitz, Freesound 79174, CC Sampling+ 1.0; see AUDIO_CREDITS.md.
"""
from pathlib import Path
import numpy as np
from scipy.signal import butter, sosfilt
from scipy.io import wavfile

SR = 44100
ROOT = Path(__file__).resolve().parents[1]
DEST = ROOT / 'data' / 'audio'
rng = np.random.default_rng(52685)


def clock(seconds):
    return np.arange(round(seconds * SR)) / SR


def noise(n, low, high):
    x = sosfilt(butter(2, [low, high], btype='bandpass', fs=SR, output='sos'), rng.normal(size=n))
    return x / max(1e-9, np.std(x))


def stereo(x, pan=0.0):
    angle = (np.asarray(pan) + 1) * np.pi / 4
    return np.column_stack((x * np.cos(angle), x * np.sin(angle)))


def edges(x, seconds=0.012):
    x = x.copy()
    n = min(round(seconds * SR), len(x) // 2)
    ramp = np.sin(np.linspace(0, np.pi / 2, n)) ** 2
    x[:n] *= ramp[:, None]
    x[-n:] *= ramp[::-1, None]
    return x


def peak(x, target):
    return x * (target / max(1e-9, np.max(np.abs(x))))


def bubble(t, start, frequency, decay, amplitude):
    age = np.maximum(0, t - start)
    # A damped falling resonance, with a soft onset rather than a sharp synth beep.
    phase = 2*np.pi*frequency*(0.77*age + 0.23*0.018*(1-np.exp(-age/0.018)))
    env = (1-np.exp(-age/0.003)) * np.exp(-age/decay) * (t >= start)
    return amplitude * np.sin(phase) * env


def write(name, x):
    pcm = np.rint(x * 32767).astype(np.int16)
    wavfile.write(DEST / name, SR, pcm)
    print(name, 'seconds=', len(x)/SR, 'peak=', round(float(np.max(np.abs(x))), 4),
          'rms=', round(float(np.sqrt(np.mean(x*x))), 4))
    return pcm.astype(float) / 32768


def generate():
    DEST.mkdir(parents=True, exist_ok=True)
    # Periodic Fourier noise has no discontinuous random reset at the loop boundary.
    t = clock(16)
    freqs = np.fft.rfftfreq(len(t), 1/SR)
    envelope = (1 - np.exp(-(freqs/95)**4)) / (1+(freqs/1400)**4)
    channels = []
    for ch in range(2):
        spectrum = (rng.normal(size=len(freqs)) + 1j*rng.normal(size=len(freqs))) * envelope
        stream = np.fft.irfft(spectrum, n=len(t))
        stream /= np.std(stream)
        flow = 0.70 + 0.17*np.sin(2*np.pi*t/16 + ch*.7) + .10*np.sin(2*np.pi*3*t/16+1.2)
        channels.append(stream * flow * .011)
    water = np.column_stack(channels)
    # Submerged micro-ripples, sparse enough to leave silence between details.
    for at in rng.uniform(.4, 14.8, 32):
        water += stereo(bubble(t, at, rng.uniform(350, 1000), .045, .008), rng.uniform(-.65,.65))
    # Very short wrap splice; the main field remains continuously flowing.
    n = 300
    blend = np.linspace(0, 1, n)[:,None]
    water[-n:] = water[-n:]*(1-blend) + water[:n]*blend
    # Match endpoint exactly without silencing the bed.
    water[-n:] += np.linspace(0,1,n)[:,None]*(water[0]-water[-1])
    water = write('water.wav', water)

    t = clock(1.65)
    metal = np.zeros(len(t))
    for frequency, level, decay in [(1250, 1, .14), (2080,.33,.09), (3170,.13,.055)]:
        age = np.maximum(0, t-.045)
        metal += level*np.sin(2*np.pi*frequency*age)*(1-np.exp(-age/.002))*np.exp(-age/decay)
    air = noise(len(t), 220, 1700) * np.sin(np.pi*t/1.65)**2 * .035
    toss = peak(edges(stereo(metal*.23 + air, -.03+.28*t/1.65)), .22)
    toss = write('toss.wav', toss)

    # Impact and tail share the same underlying fluid texture.
    t = clock(5.82)
    pressure = bubble(t, 0, 170, .065, .80)
    spray = noise(len(t), 380, 3600)*(1-np.exp(-t/.009))*np.exp(-t/.12)*.115
    ripple = noise(len(t), 130, 1100)*(1-np.exp(-t/.035))*np.exp(-t/.70)*.036
    surface = stereo(pressure+spray+ripple, .24)
    for at, f, a in [(.055,610,.08),(.125,420,.09),(.225,790,.065),(.36,510,.04),(.50,890,.025),(.79,680,.019)]:
        surface += stereo(bubble(t,at,f,.045,a),rng.uniform(-.25,.45))
    surface = peak(surface,.42)
    split = round(.62*SR)
    tail = surface[split:]

    # Actual recorded coin entering water. No oscillators or pitch/time changes.
    # Source excerpt is 5.378--5.878 s of engreitz's Freesound 79174 preview.
    rate, recorded = wavfile.read(DEST / 'source' / 'coin_water_excerpt.wav')
    assert rate == SR and recorded.ndim == 2 and recorded.shape[1] == 2
    wet = recorded.astype(float) / 32768
    wet = sosfilt(butter(2, [65, 4000], btype='bandpass', fs=SR, output='sos'), wet, axis=0)
    # Retain the irregular wet attack; fade room noise only after the short event.
    fade = round(.11*SR)
    wet[-fade:] *= np.linspace(1,0,fade)[:,None]**2
    wet = edges(wet,.002)
    contact = np.zeros((round(.62*SR),2))
    contact[:len(wet)] = wet
    impact = write('impact.wav', peak(contact,.30))
    # Isolated three-hit preview at the same fixed playback level as the artwork.
    isolated = np.concatenate([np.zeros((round(.3*SR),2))] +
               [part for _ in range(3) for part in (impact, np.zeros((round(.75*SR),2)))])
    wavfile.write(ROOT / 'Impact_Preview.wav',SR,np.rint(isolated*.75*32767).astype(np.int16))

    t = clock(5.20)
    # No melody or victory jingle: a soft, open fifth emerges with the reflection.
    reveal = np.clip((t-.13*5.20)/.85,0,1)
    release = np.clip((5.20-t)/1.4,0,1)
    env = np.sin(reveal*np.pi/2)**2 * np.sin(release*np.pi/2)**2
    shimmer = np.zeros((len(t),2))
    for ch in range(2):
        shimmer[:,ch] = env * (.022*np.sin(2*np.pi*(293.66+ch*.35)*t)
                               + .010*np.sin(2*np.pi*(440+ch*.5)*t)
                               + .003*np.sin(2*np.pi*880*t))
    shimmer += stereo(noise(len(t),500,2000)*env*.0025,0)
    moon = write('moon.wav', edges(tail+shimmer,.02))

    sinking = np.zeros((len(t),2))
    for at,f,amp in [(1.16,650,.06),(1.52,520,.055),(2.04,435,.045),
                     (2.61,340,.034),(3.18,295,.025),(3.70,250,.016)]:
        sinking += stereo(bubble(t,at,f,.075,amp), .23)
    sinkenv = np.sin(np.pi*np.clip((t-.8)/4,0,1))**2
    sinking += stereo(noise(len(t),95,650)*sinkenv*.006,.20)
    coin = write('coin.wav', edges(tail+sinking,.02))

    # A listening preview: Moon forward / reverse, then Coin forward / reverse.
    sections = [np.zeros((SR*2,2))]
    for ending in (moon, coin):
        sections += [toss, impact, ending, np.zeros((SR*2,2)),
                     ending[::-1],impact[::-1],toss[::-1],np.zeros((SR*2,2))]
    preview = np.concatenate(sections)
    preview += water[np.arange(len(preview)) % len(water)]
    preview = edges(preview*.75,.15)
    wavfile.write(ROOT / 'Sound_Preview.wav',SR,np.rint(preview*32767).astype(np.int16))


if __name__ == '__main__':
    generate()
