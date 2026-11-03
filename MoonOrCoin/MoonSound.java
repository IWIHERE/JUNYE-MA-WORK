import java.io.File;
import java.io.IOException;
import javax.sound.sampled.AudioFormat;
import javax.sound.sampled.AudioInputStream;
import javax.sound.sampled.AudioSystem;
import javax.sound.sampled.DataLine;
import javax.sound.sampled.SourceDataLine;

/** Small stereo mixer using Java's built-in audio output, with no Processing library.
 * Audio runs off the drawing thread. One cue per scene; the water bed never restarts.
 * WAVs: 44.1 kHz stereo PCM16. Recorded impact credit: AUDIO_CREDITS.md.
 * Reverse uses the same sample pairs.
 */
public class MoonSound {
  static final int RATE = 44100;
  static final int BLOCK = 256;
  static final AudioFormat FORMAT = new AudioFormat(RATE, 16, 2, true, false);
  static final String[] FILES = {"water.wav", "toss.wav", "impact.wav",
      "moon.wav", "coin.wav"};
  final File folder;
  volatile boolean running = true;
  static final float MASTER_LEVEL = 0.75f;
  volatile Cue requested = new Cue(0, false, System.nanoTime());
  volatile SourceDataLine line;
  final Thread worker;

  static class Cue {
    final int index;
    final boolean reverse;
    final long start;
    Cue(int index, boolean reverse, long start) {
      this.index = index; this.reverse = reverse; this.start = start;
    }
  }

  public MoonSound(String audioDirectory) {
    folder = new File(audioDirectory);
    worker = new Thread(new Runnable() {
      public void run() { play(); }
    }, "MoonOrCoin-audio");
    worker.setDaemon(true);
    worker.start();
  }

  // IDs match the existing sketch. FINISHED and IDLE keep only the quiet bed.
  static Cue cueFor(int scene, boolean moon, long start) {
    int index = 0;
    boolean reverse = false;
    switch (scene) {
      case 1: index = 1; break;
      case 2: index = 2; break;
      case 3: index = moon ? 3 : 4; break;
      case 5: index = moon ? 3 : 4; reverse = true; break;
      case 6: index = 2; reverse = true; break;
      case 7: index = 1; reverse = true; break;
      default: break;
    }
    return new Cue(index, reverse, start);
  }

  public void enterScene(int scene, boolean moon) {
    requested = cueFor(scene, moon, System.nanoTime());
  }

  static float[][] loadBank(File folder) throws Exception {
    float[][] bank = new float[FILES.length][];
    for (int i = 0; i < FILES.length; i++) bank[i] = load(new File(folder, FILES[i]));
    return bank;
  }

  static float[] load(File file) throws Exception {
    try (AudioInputStream stream = AudioSystem.getAudioInputStream(file)) {
      AudioFormat f = stream.getFormat();
      if (f.getSampleRate() != RATE || f.getChannels() != 2 ||
          f.getSampleSizeInBits() != 16 || f.isBigEndian() ||
          !f.getEncoding().equals(AudioFormat.Encoding.PCM_SIGNED)) {
        throw new IOException("Expected 44.1 kHz stereo PCM16 WAV: " + file.getName());
      }
      byte[] bytes = stream.readAllBytes();
      if (bytes.length == 0 || bytes.length % 4 != 0)
        throw new IOException("Empty or incomplete WAV: " + file.getName());
      float[] samples = new float[bytes.length / 2];
      for (int i = 0; i < samples.length; i++) {
        short value = (short)((bytes[2*i] & 255) | (bytes[2*i+1] << 8));
        samples[i] = value / 32768f;
      }
      return samples;
    }
  }

  // Keep left and right together: reverse frames, never individual samples.
  static float cueSample(float[] samples, long frame, int channel, boolean reverse) {
    long length = samples.length / 2;
    if (frame < 0 || frame >= length) return 0f;
    long source = reverse ? length - 1 - frame : frame;
    return samples[(int)source * 2 + channel];
  }

  void play() {
    SourceDataLine output = null;
    try {
      float[][] bank = loadBank(folder);
      if (!running) return;
      output = (SourceDataLine) AudioSystem.getLine(new DataLine.Info(SourceDataLine.class, FORMAT));
      line = output;
      output.open(FORMAT, BLOCK * 4 * 4);
      if (!running) return;
      output.start();
      byte[] pcm = new byte[BLOCK * 4];
      long ambientFrame = 0;
      long cueFrame = 0;
      int ambientLength = bank[0].length / 2;
      Cue active = null;
      float gain = 0f;
      final float smoothing = 1f - (float)Math.exp(-1.0 / (RATE * 0.035));
      while (running) {
        Cue next = requested;
        if (next != active) {
          active = next;
          // If loading was slow, join the current event instead of replaying old sounds.
          cueFrame = Math.max(0L, (long)((System.nanoTime() - active.start) * (RATE / 1e9)));
        }
        float target = MASTER_LEVEL;
        for (int frame = 0; frame < BLOCK; frame++) {
          gain += (target - gain) * smoothing;
          int bed = (int)(ambientFrame % ambientLength) * 2;
          for (int ch = 0; ch < 2; ch++) {
            float sample = bank[0][bed + ch];
            if (active.index > 0)
              sample += cueSample(bank[active.index], cueFrame, ch, active.reverse);
            int value = Math.round(Math.max(-1f, Math.min(1f, sample * gain)) * 32767f);
            int offset = frame * 4 + ch * 2;
            pcm[offset] = (byte)value;
            pcm[offset+1] = (byte)(value >> 8);
          }
          ambientFrame++;
          cueFrame++;
        }
        int offset = 0;
        while (running && offset < pcm.length) {
          int written = output.write(pcm, offset, pcm.length - offset);
          if (written <= 0) break;
          offset += written;
        }
      }
    } catch (Exception error) {
      if (running) System.err.println("Moon or Coin audio unavailable: " + error.getMessage()
        + "\nKeep data/audio beside the sketch; check the system audio output. Visuals continue.");
    } finally {
      if (output != null) {
        try { output.stop(); output.flush(); output.close(); }
        catch (Exception ignored) { }
      }
    }
  }

  /** Called by Processing when the sketch closes. */
  public void dispose() {
    running = false;
    SourceDataLine output = line;
    if (output != null) {
      try { output.stop(); output.flush(); output.close(); }
      catch (Exception ignored) { }
    }
    worker.interrupt();
  }
}
