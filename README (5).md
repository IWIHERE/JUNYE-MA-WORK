# Moon or Coin?

**Junye Ma · 25152202 · Tutorial 09**  
**52685 Creative Coding · Assessment 2 · Spring 2026**

## About the project

*Moon or Coin?* is an interactive animation made in Processing 4. A coin is tossed above a dark water surface and reveals one of two endings: the Moon dissolves into its reflection, while the Coin sinks beneath the water. The floating title breaks apart as the ripples reach it.

The central visual rule is that the ripple causes each transformation. Movement, fragmentation and fading follow the expanding wave, giving the scene a connected rhythm. After an ending, the viewer can rewind the sequence and toss again. Thin lines, a restrained colour palette and quiet water sounds create a slow, reflective atmosphere.

## Requirements

- Processing 4, using **Java Mode**.
- The complete project folder, including `MoonSound.java` and `data/audio/`.
- Speakers or headphones for the sound.

The sketch uses Processing's P2D renderer at 1280 × 720, with a target frame rate of 60 fps. Audio playback uses Java's built-in sound API. No additional Processing libraries or Python installation are needed to run the artwork.

## How to run

1. Download and extract the complete repository.
2. Locate the sketch folder. It must be named `MoonOrCoin`, and its main file must be named `MoonOrCoin.pde`. If GitHub adds a suffix such as `-main` to the folder containing the sketch, rename that folder to `MoonOrCoin`.
3. Keep `MoonSound.java` and the `data` folder beside `MoonOrCoin.pde`.
4. Open `MoonOrCoin.pde` in Processing 4, select **Java Mode**, and click **Run**.
5. Click inside the artwork window to begin.

## Controls

| Input | Action |
| --- | --- |
| Mouse click, Space or Enter | Toss when the scene is ready. After an ending finishes, use the same input to rewind. |
| M | Select Moon for the first toss as a preview. |
| C | Select Coin for the first toss as a preview. |
| Stop and run the sketch again | Reset the sequence and begin with a new first toss. |

Wait until the rewind has finished, then click or press Space again to make the next toss. Inputs during an animation are ignored so that the sequence is not interrupted.

The first normal toss has a 50/50 chance of Moon or Coin. Every subsequent toss produces the opposite result, allowing both endings to be experienced without consecutive repetition. Later outcomes therefore alternate rather than remaining independently random. Rewinding does not count as another toss or change the current outcome. The M and C preview keys only determine the first result; they do not override later alternation.

## Project files

Paths below are relative to the `MoonOrCoin` sketch folder.

| File or folder | Purpose |
| --- | --- |
| `MoonOrCoin.pde` | Main sketch: interaction, scene transitions, coin animation, water, title fragments and rewind. |
| `MoonSound.java` | Audio playback, ambient mixing and reversed sound cues. |
| `data/audio/` | Five WAV files used during playback: `water`, `toss`, `impact`, `moon` and `coin`. |
| `data/audio/source/coin_water_excerpt.wav` | Recorded excerpt used to build the impact sound. |
| `AUDIO_CREDITS.md` | Detailed recording credit, source information and licence. |
| `tools/make_audio.py` | Optional script for rebuilding the audio assets. Requires Python 3, NumPy and SciPy. |
| `README.md` | Project description and instructions. |

## How the code works

Scene states organise the forward animation and its reverse sequence. Timing variables control the progress of each stage. The title is stored as an `ArrayList` of fragments; each fragment begins moving only when the ripple reaches its position. Rewind draws the animation with decreasing progress values, allowing the fragments and coin to return to their earlier positions.

The `hasTossed` and `moonResult` variables control the outcome rule. The first toss chooses a result, and each later toss flips the stored Boolean value. Sound cues are triggered when the scene changes. During rewind, the corresponding cues play backwards while the ambient water continues forwards.

## Development

The work developed through adjustments to the ripple timing, title breakup, reverse transitions and impact sound. Peer feedback particularly valued the smooth rewind and the fragmented title. It also identified repeated outcomes as a weakness of the original independent 50/50 rule. The final version keeps the first toss random and alternates later results in response to that feedback.

## Audio credit

The impact sound contains an edited excerpt of **“Dropping Coins into Water.wav” by engreitz**, released under **Creative Commons Sampling Plus 1.0**.

- [Original recording](https://freesound.org/people/engreitz/sounds/79174/)
- [Licence](https://creativecommons.org/licenses/sampling+/1.0/)

The excerpt was filtered, faded and level-adjusted for the artwork, and is also played in reverse. The other four sound files are procedurally generated. See `AUDIO_CREDITS.md` for the full attribution and processing details; retain this credit when sharing the project.

## Troubleshooting

- **Processing asks to move the sketch:** check that the folder is named `MoonOrCoin` and the main file is `MoonOrCoin.pde`.
- **`MoonSound` cannot be found:** check that `MoonSound.java` is beside the PDE file.
- **No sound:** check the system output volume and confirm that all five WAV files remain in `data/audio/`. Audio-loading errors appear in the Processing console; the visuals can continue without sound.
- **A click appears to do nothing:** wait for the current animation or rewind to finish before starting the next action.
