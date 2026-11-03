/*
  MOON OR COIN? — final interactive animation
  Processing 4 / Java Mode

  SPACE or mouse click : toss / rewind the completed sequence
  M / C : choose the first Moon / Coin ending for preview
  After the first toss, every new toss alternates the outcome.

  Visuals are unchanged and drawn with code. Sound assets live
  in data/audio. MoonSound.java uses built-in Java Sound (no added library).
*/

final int IDLE = 0;
final int TOSS = 1;
final int IMPACT = 2;
final int ENDING = 3;
final int FINISHED = 4;
final int REWIND_ENDING = 5;
final int REWIND_IMPACT = 6;
final int REWIND_TOSS = 7;

final float START_X = 640;
final float START_Y = 770;
final float COIN_X = 820;
final float WATER_Y = 384;
final float COIN_R = 82;
// The reflection grows from the exact point where the Moon face touches water.
final float REFLECTION_X = COIN_X;

final float TOSS_TIME = 1.65f;
final float IMPACT_TIME = 0.62f;
final float ENDING_TIME = 5.20f;

int scene = IDLE;
int sceneStarted;
boolean moonResult = true;
boolean hasTossed = false;
boolean titleReady = true;
float now;
float surfaceRippleAge = -1;
PFont coinFont;
PFont titleFont;
PGraphics titleLayer;
ArrayList<TitleFragment> titleFragments = new ArrayList<TitleFragment>();
MoonSound soundtrack;

void settings() {
  size(1280, 720, P2D);
  smooth(8);
}

void setup() {
  surface.setTitle("Moon or Coin?");
  frameRate(60);
  coinFont = createFont("Georgia", 48, true);
  // Palatino keeps the literary serif tone but has more calligraphic,
  // old-print proportions than the previous neutral title face.
  titleFont = createFont("Palatino Linotype", 78, true);
  buildTitleFragments();
  sceneStarted = millis();
  soundtrack = new MoonSound(dataPath("audio"));
  registerMethod("dispose", soundtrack);
}

void draw() {
  now = millis() * 0.001f;
  updateScene();
  float t = sceneTime();
  surfaceRippleAge = currentSurfaceRippleAge(t);

  background(10, 11, 11);
  drawBlackPaper();
  drawWaterField();

  if (scene == IDLE) {
    float titleIn = titleReady ? 1 : ease(constrain(t / 2.35f, 0, 1));
    drawTitleFragments(0, titleIn);
    drawInteractionMark(titleIn);
  } else if (scene == TOSS) {
    float p = constrain(t / TOSS_TIME, 0, 1);
    drawTitleFragments(0, 1);
    drawLaunchWaves(p);
    drawQuietRipples(0.20f * ease(constrain((p - 0.58f) / 0.42f, 0, 1)));
    drawToss(p);
  } else if (scene == IMPACT) {
    drawQuietRipples(0.38f);
    drawImpactWaves(t);
    drawTitleFragments(t, 1);
    drawImpactCoin(t, false);
  } else if (scene == ENDING) {
    float p = constrain(t / ENDING_TIME, 0, 1);
    drawQuietRipples(0.32f + 0.28f * (1 - p));
    drawImpactWaves(IMPACT_TIME + t);
    drawTitleFragments(IMPACT_TIME + t, 1);
    if (moonResult) drawMoonEnding(p, false);
    else drawCoinEnding(p);
  } else if (scene == FINISHED) {
    if (moonResult) drawFinalMoonReflection(1);
    drawInteractionMark(1);
  } else if (scene == REWIND_ENDING) {
    float p = 1 - constrain(t / ENDING_TIME, 0, 1);
    float rippleAge = IMPACT_TIME + p * ENDING_TIME;
    drawQuietRipples(0.32f + 0.28f * (1 - p));
    drawImpactWaves(rippleAge);
    drawTitleFragments(rippleAge, 1);
    if (moonResult) drawMoonEnding(p, true);
    else drawCoinEnding(p);
  } else if (scene == REWIND_IMPACT) {
    float age = max(0, IMPACT_TIME - t);
    drawQuietRipples(0.38f);
    drawImpactWaves(age);
    drawTitleFragments(age, 1);
    drawImpactCoin(age, true);
  } else if (scene == REWIND_TOSS) {
    float p = 1 - constrain(t / TOSS_TIME, 0, 1);
    drawTitleFragments(0, 1);
    drawLaunchWaves(p);
    drawQuietRipples(0.20f * ease(constrain((p - 0.58f) / 0.42f, 0, 1)));
    drawReverseToss(p);
  }

  drawVignette();
}

float currentSurfaceRippleAge(float t) {
  if (scene == IMPACT) return t;
  if (scene == ENDING) return IMPACT_TIME + t;
  if (scene == REWIND_ENDING) {
    float p = 1 - constrain(t / ENDING_TIME, 0, 1);
    return IMPACT_TIME + p * ENDING_TIME;
  }
  if (scene == REWIND_IMPACT) return max(0, IMPACT_TIME - t);
  return -1;
}

void updateScene() {
  float t = sceneTime();
  if (scene == TOSS && t >= TOSS_TIME) enterScene(IMPACT);
  else if (scene == IMPACT && t >= IMPACT_TIME) enterScene(ENDING);
  else if (scene == ENDING && t >= ENDING_TIME) enterScene(FINISHED);
  else if (scene == REWIND_ENDING && t >= ENDING_TIME) enterScene(REWIND_IMPACT);
  else if (scene == REWIND_IMPACT && t >= IMPACT_TIME) enterScene(REWIND_TOSS);
  else if (scene == REWIND_TOSS && t >= TOSS_TIME) {
    titleReady = true;
    enterScene(IDLE);
  }
}

float sceneTime() {
  return (millis() - sceneStarted) * 0.001f;
}

void enterScene(int next) {
  scene = next;
  sceneStarted = millis();
  if (soundtrack != null) soundtrack.enterScene(next, moonResult);
}

void startToss(int forcedResult) {
  if (scene == FINISHED) {
    enterScene(REWIND_ENDING);
    return;
  }
  if (scene != IDLE) return;
  // Choose the first result once; later tosses must show the other side.
  // Rewind and clicks during animation return above, preserving this result.
  if (hasTossed) {
    moonResult = !moonResult;
  } else {
    moonResult = forcedResult == 0 ? true
      : forcedResult == 1 ? false
      : random(1) < 0.5f;
    hasTossed = true;
  }
  enterScene(TOSS);
}

void keyPressed() {
  if (key == ' ' || key == ENTER || key == RETURN) startToss(-1);
  else if (key == 'm' || key == 'M') startToss(0);
  else if (key == 'c' || key == 'C') startToss(1);
}

void mousePressed() {
  startToss(-1);
}

// -------------------------------------------------------------------------
// Title and transitions

final String TITLE = "MOON OR COIN?";
final float TITLE_SIZE = 78;
final float TITLE_Y = 407;

void buildTitleFragments() {
  titleLayer = createGraphics(width, height, P2D);
  titleLayer.beginDraw();
  titleLayer.clear();
  titleLayer.textFont(titleFont);
  titleLayer.textSize(TITLE_SIZE);
  titleLayer.textAlign(CENTER, BASELINE);
  titleLayer.noStroke();
  titleLayer.fill(224, 225, 220, 255);
  // Drawing the phrase as one string preserves the font's natural kerning.
  titleLayer.text(TITLE, width * 0.5f, TITLE_Y);
  titleLayer.endDraw();
  titleLayer.loadPixels();

  textFont(titleFont);
  textSize(TITLE_SIZE);
  int left = max(0, (int) ((width - textWidth(TITLE)) * 0.5f) - 14);
  int right = min(width, (int) ((width + textWidth(TITLE)) * 0.5f) + 14);
  int top = max(0, (int) TITLE_Y - 88);
  int bottom = min(height, (int) TITLE_Y + 22);
  // Long, shallow cells create broken serif strokes and reflective slivers,
  // rather than square digital pixels.
  int tileW = 9;
  int tileH = 3;

  for (int y = top; y < bottom; y += tileH) {
    for (int x = left; x < right; x += tileW) {
      int w = min(tileW, right - x);
      int h = min(tileH, bottom - y);
      boolean containsInk = false;
      for (int py = y; py < y + h && !containsInk; py += 2) {
        for (int px = x; px < x + w; px += 2) {
          int pixel = titleLayer.pixels[py * width + px];
          if (((pixel >>> 24) & 0xff) > 22) {
            containsInk = true;
            break;
          }
        }
      }
      if (containsInk) titleFragments.add(new TitleFragment(x, y, w, h));
    }
  }
}

void drawTitleFragments(float rippleAge, float globalOpacity) {
  if (globalOpacity <= 0) return;
  // In the calm 2D state the intact phrase is one object, not hundreds of
  // independent sprites. A sub-pixel drift keeps it embedded in the water.
  if (rippleAge <= 0) {
    tint(238, 239, 234, 255 * globalOpacity);
    float refraction = 0.65f * sin(now * 0.52f);
    image(titleLayer, refraction, 0, width, height,
      0, 0, width, height);
    noTint();
    return;
  }
  // By this age every stroke has already dissolved into the water field.
  if (rippleAge > 3.0f) return;
  for (TitleFragment fragment : titleFragments) {
    fragment.display(rippleAge, globalOpacity);
  }
  noTint();
}

float impactWaveRadius(float age) {
  if (age <= 0) return 0;
  // Grow continuously from the exact contact point; there is no first-frame
  // jump that could disturb lettering before a visible wave reaches it.
  float newbornRing = 66 * ease(constrain(age / 0.18f, 0, 1));
  return newbornRing + 315 * age;
}

class TitleFragment {
  int sx, sy, sw, sh;
  float centreX, centreY;
  float rippleDistance;
  float radialX, radialY;
  float seed;

  TitleFragment(int x, int y, int w, int h) {
    sx = x;
    sy = y;
    sw = w;
    sh = h;
    centreX = x + w * 0.5f;
    centreY = y + h * 0.5f;
    seed = x * 0.071f + y * 0.137f;

    float dx = centreX - COIN_X;
    float dy = centreY - WATER_Y;
    float stretchedY = dy / 0.54f;
    rippleDistance = sqrt(dx * dx + stretchedY * stretchedY);
    float screenDistance = sqrt(dx * dx + dy * dy);
    radialX = dx / max(1, screenDistance);
    radialY = dy / max(1, screenDistance);
  }

  void display(float rippleAge, float globalOpacity) {
    float front = impactWaveRadius(rippleAge);
    // A fragment cannot move until the physical ripple reaches its origin.
    float passedDistance = max(0, front - rippleDistance);
    float local = ease(constrain(passedDistance / 260.0f, 0, 1));
    // The fragment remains attached to the ring that broke it: as that ring
    // expands, its radial distance increases with the same wavefront.
    float travel = min(passedDistance, 330)
      * (0.62f + 0.16f * hash(seed + 4));
    float tangent = sin(PI * local) * (hash(seed + 8) - 0.5f) * 18;
    float currentX = centreX
      + radialX * travel
      - radialY * tangent;
    float currentY = centreY
      + radialY * travel
      + radialX * tangent;

    // Before the stroke separates, it rides the crest and trough of the same
    // height field as the white water lines.
    float surfaceHeight = rippleSurfaceHeight(centreX, centreY, rippleAge);
    float slopeX = (rippleSurfaceHeight(centreX + 7, centreY, rippleAge)
      - rippleSurfaceHeight(centreX - 7, centreY, rippleAge)) / 14.0f;
    currentY -= surfaceHeight * (1 - 0.72f * local) * 1.10f;

    // Whole rows share almost the same refraction, so the untouched title
    // remains readable as one object rather than a collection of letters.
    currentX += (1 - local) * 1.15f
      * sin(rippleAge * 0.52f + sy * 0.085f);

    float dissolve = ease(constrain((local - 0.72f) / 0.28f, 0, 1));
    float alpha = 255 * globalOpacity * (1 - dissolve);
    if (alpha < 1) return;

    pushMatrix();
    translate(currentX, currentY);
    rotate(-slopeX * (1 - local) * 0.12f
      + radialX * local * (hash(seed + 13) - 0.5f) * 0.16f);
    scale(1 + abs(surfaceHeight) * (1 - local) * 0.006f
      + local * (0.16f + 0.22f * hash(seed + 17)),
      1 - local * 0.08f);
    tint(238, 239, 234, alpha);
    image(titleLayer,
      -sw * 0.5f - 0.30f, -sh * 0.5f - 0.25f,
      sw + 0.60f, sh + 0.50f,
      sx, sy, sx + sw, sy + sh);
    popMatrix();
  }
}

// -------------------------------------------------------------------------
// Toss and impact

void drawToss(float p) {
  float x = tossX(p);
  float y = tossY(p);
  float r = 56 + (COIN_R - 56) * ease(p);
  float angle = flipAngle(p);
  float projected = cameraProjection(angle);
  float facing = abs(projected);

  drawFlightShadow(p);

  for (int i = 3; i >= 1; i--) {
    float q = max(0, p - i * 0.013f);
    float oldAngle = flipAngle(q);
    float oldProjection = cameraProjection(oldAngle);
    drawMotionArc(
      tossX(q),
      tossY(q),
      r,
      abs(oldProjection) / 0.58f,
      8 + i * 6
    );
  }

  float contactTilt = -0.075f
    * ease(constrain((p - 0.82f) / 0.18f, 0, 1));
  pushMatrix();
  translate(x, y);
  rotate(contactTilt);
  drawCoin(0, 0, r, projected >= 0,
    max(0.045f, facing / 0.58f), 255);
  if (facing < 0.22f) {
    drawCoinEdge(0, 0, r, 255 * (1 - facing / 0.22f));
  }
  popMatrix();
}

void drawReverseToss(float p) {
  float x = tossX(p);
  float y = tossY(p);
  float r = 56 + (COIN_R - 56) * ease(p);
  // For the Moon route, condensation exposes the physical $1 side before
  // the rewound flight. The extra half-turn keeps that face continuous.
  float angle = flipAngle(p) + (moonResult ? PI : 0);
  float projected = cameraProjection(angle);
  float facing = abs(projected);

  drawFlightShadow(p);
  for (int i = 3; i >= 1; i--) {
    float q = min(1, p + i * 0.013f);
    float oldAngle = flipAngle(q) + (moonResult ? PI : 0);
    float oldProjection = cameraProjection(oldAngle);
    drawMotionArc(tossX(q), tossY(q), r,
      abs(oldProjection) / 0.58f, 8 + i * 6);
  }

  float contactTilt = -0.075f
    * ease(constrain((p - 0.82f) / 0.18f, 0, 1));
  pushMatrix();
  translate(x, y);
  rotate(contactTilt);
  drawCoin(0, 0, r, projected >= 0,
    max(0.045f, facing / 0.58f), 255);
  if (facing < 0.22f) {
    drawCoinEdge(0, 0, r, 255 * (1 - facing / 0.22f));
  }
  popMatrix();
}

void drawImpactCoin(float age, boolean reversing) {
  float bounce = -18 * exp(-6.5f * age) * sin(14 * age);
  float baseAngle = (reversing || !moonResult) ? PI - 0.24f : -0.24f;
  float wobble = 0.18f * exp(-5.5f * age) * sin(13 * age);
  float projected = cameraProjection(baseAngle + wobble);
  boolean face = reversing ? false : moonResult;
  float vertical = constrain(abs(projected) / 0.58f, 0.16f, 1);
  float immersion = ease(constrain(age / IMPACT_TIME, 0, 1));

  pushMatrix();
  translate(COIN_X, WATER_Y + bounce + 9 * immersion);
  rotate(-0.075f * (1 - 0.55f * immersion));
  drawCoin(0, 0, COIN_R, face, vertical, 255);
  popMatrix();

  // The near half of the surface closes over the lower face, so the coin
  // enters the water instead of stamping onto it like a flat sticker.
  noStroke();
  fill(10, 11, 11, 118 * immersion);
  ellipse(COIN_X, WATER_Y + 35, COIN_R * 2.18f,
    32 + 30 * immersion);
}

float tossX(float p) {
  // Quadratic Bezier: launch from the bottom centre and land to the right.
  float inv = 1 - p;
  return inv * inv * START_X + 2 * inv * p * 710 + p * p * COIN_X;
}

float tossY(float p) {
  float inv = 1 - p;
  return inv * inv * START_Y + 2 * inv * p * 58 + p * p * WATER_Y;
}

float flipAngle(float p) {
  float steady = p - 0.065f * sin(TWO_PI * p) / TWO_PI;
  // Five fast full rotations, plus a half-turn for the dollar face.
  float landingTilt = -0.24f * ease(constrain((p - 0.82f) / 0.18f, 0, 1));
  return steady * (moonResult ? 10 * PI : 11 * PI) + landingTilt;
}

float cameraProjection(float angle) {
  return 0.58f * cos(angle) + 0.82f * sin(angle);
}

void drawFlightShadow(float p) {
  float arrival = ease(constrain((p - 0.58f) / 0.42f, 0, 1));
  noFill();
  stroke(229, 226, 213, 28 * arrival);
  strokeWeight(1);
  ellipse(COIN_X, WATER_Y + 7, 235 - 50 * arrival, 82 - 20 * arrival);
}

void drawLaunchWaves(float p) {
  if (p > 0.52f) return;
  float age = p / 0.52f;
  for (int ring = 0; ring < 4; ring++) {
    float local = age - ring * 0.12f;
    if (local < 0) continue;
    float radius = 32 + 120 * local;
    drawBrokenEllipse(START_X, 690, radius * 2, radius * 0.52f,
      54 * (1 - local), 0.9f, 810 + ring * 29);
  }
}

void drawMotionArc(float x, float y, float r, float scaleY, float alpha) {
  noFill();
  stroke(233, 231, 218, alpha);
  strokeWeight(1.1f);
  arc(x, y, r * 2, r * 1.70f * max(0.08f, scaleY), 0.32f, PI * 1.38f);
}

void drawCoinEdge(float x, float y, float r, float alpha) {
  float thickness = max(9, r * 0.20f);
  noStroke();
  fill(20, 21, 20, alpha * 0.96f);
  ellipse(x, y, 2 * r, thickness);

  noFill();
  stroke(243, 241, 228, alpha * 0.90f);
  strokeWeight(2);
  arc(x, y - thickness * 0.18f, 2 * r, thickness, PI, TWO_PI);
  stroke(198, 197, 188, alpha * 0.62f);
  arc(x, y + thickness * 0.18f, 2 * r, thickness, 0, PI);

  for (int i = -20; i <= 20; i++) {
    float u = i / 21.0f;
    float h = thickness * 0.42f * sqrt(max(0, 1 - u * u));
    stroke(224, 222, 210, alpha * (0.20f + 0.18f * hash(i + 61)));
    strokeWeight(0.65f);
    line(x + u * r, y - h, x + u * r, y + h);
  }
}

void drawImpactWaves(float age) {
  if (age > IMPACT_TIME + ENDING_TIME + 0.05f) return;

  noFill();
  for (int ring = 0; ring < 7; ring++) {
    float waveAge = age - ring * 0.16f;
    if (waveAge < 0) continue;
    float radius = impactWaveRadius(waveAge);
    float alpha = 148 * exp(-0.36f * waveAge) * (1 - ring * 0.085f);
    drawHeightMappedRippleRing(radius, age, alpha, 1.20f, ring * 41);
  }

  if (age < 0.80f) {
    noStroke();
    for (int i = 0; i < 20; i++) {
      float life = age / (0.38f + 0.35f * hash(i * 8.71f));
      if (life <= 0 || life >= 1) continue;
      float a = hash(i * 12.31f) * TWO_PI;
      float speed = 38 + 115 * hash(i * 3.09f);
      float x = COIN_X + cos(a) * (COIN_R * 0.90f + speed * age);
      float y = WATER_Y + sin(a) * (COIN_R * 0.33f + speed * age * 0.28f)
        - 35 * sin(PI * life);
      fill(240, 237, 222, 126 * sin(PI * life));
      circle(x, y, 0.6f + 1.55f * hash(i * 5.7f));
    }
  }
}

void drawHeightMappedRippleRing(float radius, float age,
                                 float alpha, float weight, int seed) {
  noFill();
  int segments = 88;
  for (int i = 0; i < segments; i++) {
    float grain = hash(seed + i * 8.17f);
    if (grain < 0.29f) continue;
    float a0 = i * TWO_PI / segments;
    float a1 = (i + 0.72f) * TWO_PI / segments;
    float x0 = COIN_X + cos(a0) * radius;
    float y0 = WATER_Y + 3 + sin(a0) * radius * 0.54f;
    float x1 = COIN_X + cos(a1) * radius;
    float y1 = WATER_Y + 3 + sin(a1) * radius * 0.54f;
    float h0 = rippleSurfaceHeight(x0, y0, age);
    float h1 = rippleSurfaceHeight(x1, y1, age);
    float px0 = rippleProjectedX(x0, y0, h0);
    float py0 = rippleProjectedY(x0, y0, h0);
    float px1 = rippleProjectedX(x1, y1, h1);
    float py1 = rippleProjectedY(x1, y1, h1);
    float crest = constrain((h0 + h1) / 42.0f, -0.24f, 0.62f);

    stroke(238, 235, 222,
      alpha * (0.48f + 0.52f * grain) * (1 + max(0, crest)));
    strokeWeight(weight * (0.80f + 0.36f * grain));
    line(px0, py0, px1, py1);

    // Sparse vertical joins reveal the height of the crest without turning
    // the monochrome drawing into a glossy 3D render.
    if (grain > 0.93f && max(abs(h0), abs(h1)) > 5) {
      stroke(224, 222, 213, alpha * 0.18f);
      strokeWeight(0.55f);
      line(px0, py0, x0, y0);
    }
  }
}

// -------------------------------------------------------------------------
// Endings

void drawMoonEnding(float p, boolean reversing) {
  float separation = ease(constrain(p / 0.34f, 0, 1));
  float coinPresence = 1 - separation;

  // The physical coin stays visible while its rim is being pulled into
  // water-borne strips. During rewind, the condensed light reveals the $1
  // face beneath it before the reverse splash begins.
  if (coinPresence > 0.002f) {
    pushMatrix();
    translate(COIN_X, WATER_Y + 24 * separation);
    rotate(-0.075f - 0.12f * separation);
    drawCoin(0, 0, COIN_R, reversing ? false : true,
      max(0.13f, 0.62f * (1 - 0.74f * separation)),
      255 * coinPresence);
    popMatrix();
    if (reversing) drawLiquidMoonFilm(separation, coinPresence);
  }

  drawCoinReflectionBands(p);

  float formation = ease(constrain((p - 0.13f) / 0.72f, 0, 1));
  drawFinalMoonReflection(formation);
}

void drawCoinReflectionBands(float p) {
  // These controlled strips are shared by forward and reverse playback.
  // They visibly carry the coin's outline into the reflection and back.
  for (int i = 0; i < 78; i++) {
    float seed = i * 5.731f;
    float born = 0.025f + 0.19f * hash(seed + 9);
    float life = constrain((p - born) / (0.48f + 0.16f * hash(seed + 17)), 0, 1);
    if (life <= 0 || life >= 1) continue;

    float a = hash(seed + 21) * TWO_PI;
    float startX = COIN_X + cos(a) * COIN_R * (0.76f + 0.17f * hash(seed + 23));
    float startY = WATER_Y + sin(a) * COIN_R * 0.56f;
    float targetY = WATER_Y - 94 + hash(seed + 41) * 350;
    float vertical = constrain((targetY - (WATER_Y - 96)) / 352.0f, 0, 1);
    float targetX = REFLECTION_X
      + moonReflectionOffset(vertical, hash(seed + 51));
    float travel = ease(life);
    float x = startX + (targetX - startX) * travel
      + 17 * sin(PI * life) * (hash(seed + 61) - 0.5f);
    float y = startY + (targetY - startY) * travel;
    float length = 2 + 17 * travel * (0.45f + hash(seed + 71));
    float alpha = 196 * sin(PI * life);
    float warmth = ease(life);
    stroke(232 + 6 * warmth, 232 - 10 * warmth,
      223 - 55 * warmth, alpha);
    strokeWeight(0.65f + 1.25f * hash(seed + 81));
    line(x - length * 0.5f, y, x + length * 0.5f,
      y + 1.2f * sin(now + seed));
  }

  // A smaller warm thread preserves the original pale Moon colour without
  // turning the transition into a particle explosion.
  for (int i = 0; i < 20; i++) {
    float seed = i * 8.137f;
    float born = 0.08f + 0.18f * hash(seed + 3);
    float life = constrain((p - born) / 0.47f, 0, 1);
    if (life <= 0 || life >= 1) continue;
    float startX = COIN_X - 14 + 36 * hash(seed + 7);
    float startY = WATER_Y - 25 + 46 * hash(seed + 11);
    float targetY = WATER_Y - 70 + 285 * hash(seed + 17);
    float vertical = constrain((targetY - (WATER_Y - 96)) / 352.0f, 0, 1);
    float targetX = REFLECTION_X
      + moonReflectionOffset(vertical, 0.24f + 0.52f * hash(seed + 23));
    float travel = ease(life);
    stroke(246, 225, 157, 145 * sin(PI * life));
    strokeWeight(0.75f + hash(seed + 29));
    line(startX + (targetX - startX) * travel,
         startY + (targetY - startY) * travel,
         startX + (targetX - startX) * travel + 3 + 8 * travel,
         startY + (targetY - startY) * travel);
  }
}

void drawLiquidMoonFilm(float separation, float coinPresence) {
  float film = sin(PI * separation) * (0.55f + 0.45f * coinPresence);
  if (film <= 0) return;
  for (int row = -8; row <= 8; row++) {
    float yy = row * 5.0f;
    float edge = sqrt(max(0, 1 - sq(yy / 44.0f)));
    float half = COIN_R * 0.78f * edge * film;
    float warmth = separation;
    stroke(236 + 4 * warmth, 233 - 12 * warmth,
      216 - 51 * warmth,
      155 * film * (0.55f + 0.45f * hash(row + 31)));
    strokeWeight(1.1f + 1.2f * hash(row * 7.1f));
    line(COIN_X - half, WATER_Y + yy,
         COIN_X + half, WATER_Y + yy + sin(now + row));
  }
}

void drawFinalMoonReflection(float formation) {
  if (formation <= 0) return;
  float sourceReveal = ease(constrain(formation / 0.24f, 0, 1));

  // A small broken glint marks the exact place where the Moon face touched.
  for (int ring = 0; ring < 3; ring++) {
    float pulse = 4 * sin(now * 0.62f + ring);
    drawBrokenMoonEllipse(REFLECTION_X, WATER_Y + 3,
      76 + ring * 55 + pulse, 17 + ring * 13,
      sourceReveal * (66 - ring * 14), 1060 + ring * 31);
  }

  // A water reflection is not a filled shape: it is a loose stack of short,
  // interrupted highlights. The crooked centre line and changing gaps make
  // the image shimmer while keeping its origin fixed at the coin's landing.
  for (int row = 0; row < 50; row++) {
    if (hash(row * 13.7f + 5) < 0.13f) continue;
    float settledY = WATER_Y - 96 + row * 7.15f;
    float vertical = row / 49.0f;
    float distanceFromSource = abs(settledY - WATER_Y) / 255.0f;
    float reveal = ease(constrain(
      (formation - distanceFromSource * 0.54f) / 0.30f, 0, 1));
    if (reveal <= 0.002f) continue;
    float y = WATER_Y + (settledY - WATER_Y) * reveal;
    float halfWidth = moonReflectionHalfWidth(vertical)
      * reveal * (0.78f + 0.22f * sin(row * 1.47f + now * 0.46f));
    float settledCentre = REFLECTION_X
      + (4 + 13 * vertical) * sin(now * 0.48f + row * 0.53f)
      + (row % 2 == 0 ? -1 : 1) * (4 + 13 * hash(row * 5.73f))
      + 8 * (noise(row * 0.19f, now * 0.10f) - 0.5f);
    float centre = REFLECTION_X + (settledCentre - REFLECTION_X) * reveal;
    // The available band is crescent-shaped but never outlined. Broken light
    // alone lets the eye infer the Moon while the surface remains primary.
    float crescentEdge = pow(abs(vertical * 2 - 1), 1.35f);
    float leftEdge = centre - halfWidth;
    float rightEdge = centre + halfWidth * (-0.03f + 0.46f * crescentEdge);
    float crescentSpan = max(2, rightEdge - leftEdge);
    int pieces = 2 + (int) floor(hash(row * 21.3f + 9) * 3);

    for (int part = 0; part < pieces; part++) {
      float cell = crescentSpan / pieces;
      float jitter = (hash(row * 31 + part * 17) - 0.5f) * cell * 0.34f;
      float left = leftEdge + part * cell + jitter;
      float length = cell * (0.22f + 0.44f * hash(row * 47 + part * 13));
      if ((row + part) % 11 == 0) length *= 1.55f;
      float alpha = reveal * (52 + 132 * hash(row * 43 + part * 11));
      stroke(239, 222, 166, alpha);
      strokeWeight(0.75f + 1.65f * hash(row * 9 + part * 5));
      line(left, y, left + length,
        y + 1.4f * sin(now * 0.92f + row + part));
    }

    // A broken bright core gives the reflection the hand-drawn zigzag found
    // in the concept image, without closing it into a solid silhouette.
    if (row % 3 != 1) {
      float core = 3 + 12 * hash(row * 17.41f);
      float coreCentre = leftEdge + crescentSpan
        * (0.44f + 0.13f * sin(row * 0.77f + now * 0.31f));
      stroke(249, 230, 164, reveal * (68 + 80 * hash(row * 3.77f)));
      strokeWeight(0.8f + 1.25f * hash(row * 8.63f));
      line(coreCentre - core * 0.55f, y + 0.8f,
           coreCentre + core * 0.45f, y - 0.8f);
    }
  }

  // Fine flecks bridge the gaps without turning the reflection into a solid
  // object. They drift slightly with the same right-moving current.
  noStroke();
  for (int i = 0; i < 92; i++) {
    float settledY = WATER_Y - 95 + hash(i * 7.19f) * 350;
    float vertical = constrain((settledY - (WATER_Y - 96)) / 352.0f, 0, 1);
    float distanceFromSource = abs(settledY - WATER_Y) / 255.0f;
    float reveal = ease(constrain(
      (formation - distanceFromSource * 0.54f) / 0.30f, 0, 1));
    if (reveal <= 0.002f) continue;
    float y = WATER_Y + (settledY - WATER_Y) * reveal;
    float settledX = REFLECTION_X
      + moonReflectionOffset(vertical, hash(i * 4.37f))
      + 6 * sin(now * 0.40f + i);
    float x = REFLECTION_X + (settledX - REFLECTION_X) * reveal;
    fill(241, 222, 164, reveal * (10 + 48 * hash(i * 11.3f)));
    circle(x, y, 0.45f + 1.65f * hash(i * 3.8f));
  }

  drawMoonWaterLight(sourceReveal);
}

float moonReflectionHalfWidth(float vertical) {
  vertical = constrain(vertical, 0, 1);
  float body = pow(sin(PI * vertical), 0.76f);
  return 8 + 74 * body * (1 - 0.12f * vertical);
}

float moonReflectionOffset(float vertical, float unitPosition) {
  vertical = constrain(vertical, 0, 1);
  unitPosition = constrain(unitPosition, 0, 1);
  float half = moonReflectionHalfWidth(vertical);
  float crescentEdge = pow(abs(vertical * 2 - 1), 1.35f);
  float right = half * (-0.03f + 0.46f * crescentEdge);
  return -half + unitPosition * (right + half);
}

void drawBrokenMoonEllipse(float x, float y, float w, float h,
                           float alpha, int seed) {
  noFill();
  int segments = 34;
  for (int i = 0; i < segments; i++) {
    float grain = hash(seed + i * 7.91f);
    if (grain < 0.46f) continue;
    float a0 = i * TWO_PI / segments;
    float a1 = (i + 0.58f) * TWO_PI / segments;
    stroke(239, 222, 168, alpha * (0.45f + 0.55f * grain));
    strokeWeight(0.65f + 0.75f * grain);
    arc(x, y, w, h, a0, a1);
  }
}

void drawMoonWaterLight(float opacity) {
  // Nearby white chalk currents catch only a trace of warm light.
  for (int i = 0; i < 18; i++) {
    float vertical = hash(i * 4.91f);
    float y = WATER_Y - 70 + vertical * 300;
    float side = hash(i * 7.13f) < 0.5f ? -1 : 1;
    float distance = 70 + 150 * hash(i * 2.77f);
    float x = REFLECTION_X + side * distance
      + 5 * sin(now * 0.45f + i);
    float length = 8 + 32 * hash(i * 9.31f);
    stroke(239, 220, 158, opacity * (9 + 20 * hash(i * 5.17f)));
    strokeWeight(0.55f + 0.45f * hash(i * 3.43f));
    line(x, y, x + length, y + sin(now + i));
  }
}

void drawCoinEnding(float p) {
  float tilt = ease(constrain((p - 0.04f) / 0.38f, 0, 1));
  float sink = ease(constrain((p - 0.16f) / 0.84f, 0, 1));
  float x = COIN_X + 58 * sin(PI * sink) - 24 * sink
    + 8 * sin(5 * PI * sink) * (1 - sink);
  float y = WATER_Y + 25 * tilt + 188 * pow(sink, 1.34f);
  float r = COIN_R * (1 - 0.47f * sink);
  float vertical = max(0.08f,
    0.62f * (1 - 0.90f * tilt)
    + 0.20f * abs(cos(3.5f * PI * sink)) * sink * (1 - sink));
  float alpha = 255 * (1 - ease(constrain((p - 0.46f) / 0.54f, 0, 1)));
  float turnOnWater = -0.08f - 0.52f * sink + 0.10f * sin(4 * PI * sink) * (1 - sink);

  // The coin first tips through the surface, then follows a curved,
  // resisted path downward instead of translating as a flat image.
  pushMatrix();
  translate(x, y);
  rotate(turnOnWater);
  drawCoin(0, 0, r, false, vertical, alpha);
  popMatrix();

  drawBrokenEllipse(COIN_X, WATER_Y + 4,
    184 + 180 * sink, 66 + 71 * sink,
    92 * (1 - p), 1.0f, 319);

  // Small air bubbles and turbulence trail behind the sinking edge.
  noStroke();
  for (int i = 0; i < 34; i++) {
    float born = 0.22f + 0.52f * hash(i * 8.7f);
    float life = constrain((p - born) / 0.30f, 0, 1);
    if (life <= 0 || life >= 1) continue;
    float bx = x + (hash(i * 3.9f) - 0.5f) * 70 - 16 * life;
    float by = y - 15 - 90 * life * (0.45f + hash(i * 6.2f));
    noFill();
    stroke(233, 231, 218, 72 * sin(PI * life));
    strokeWeight(0.8f);
    circle(bx, by, 2 + 7 * hash(i * 11.1f));
  }

  // A dark moving veil suggests increasing depth without a hard cut.
  noStroke();
  fill(10, 11, 11, 125 * ease(constrain((p - 0.34f) / 0.60f, 0, 1)));
  ellipse(x, y - 7, r * 2.3f, r * 0.82f);
}

// -------------------------------------------------------------------------
// Coin drawing

void drawCoin(float x, float y, float r, boolean moonFace,
              float verticalScale, float alpha) {
  pushMatrix();
  translate(x, y);

  float faceScaleY = 0.58f * max(0.045f, verticalScale);
  float faceHeight = 2 * r * faceScaleY;
  // The centre-to-centre offset is 8–12% of the diameter. It remains
  // visible at frontal angles and becomes dominant when the face turns away.
  float thickness = 2 * r * (0.082f
    + 0.035f * (1 - constrain(verticalScale, 0, 1)));

  // Back ellipse and connecting wall create a real cylindrical side rather
  // than a vertically squashed paper circle.
  noStroke();
  fill(17, 18, 18, alpha * 0.98f);
  ellipse(0, thickness, 2 * r, faceHeight);
  noFill();
  stroke(190, 189, 180, alpha * 0.46f);
  strokeWeight(1.0f);
  arc(0, thickness, 2 * r, faceHeight, 0, PI);
  line(-r, 0, -r, thickness);
  line(r, 0, r, thickness);

  // Reeding follows the lower visible half of the cylindrical rim.
  for (int i = 0; i <= 34; i++) {
    float a = i * PI / 34.0f;
    float xx = cos(a) * (r - 1);
    float yy = sin(a) * r * faceScaleY;
    stroke(225, 223, 211,
      alpha * (0.16f + 0.25f * hash(i * 4.31f + r)));
    strokeWeight(0.65f);
    line(xx, yy, xx, yy + thickness);
  }

  // The opaque front face hides the rear disk, leaving only the rim band.
  noStroke();
  fill(10, 11, 11, alpha);
  ellipse(0, 0, 2 * r, faceHeight);

  pushMatrix();
  scale(1, faceScaleY);

  noFill();
  for (int layer = 0; layer < 3; layer++) {
    stroke(242, 240, 227, alpha * (layer == 1 ? 0.87f : 0.28f));
    strokeWeight(layer == 1 ? 2.3f : 0.9f);
    drawBrokenCircle(0, (layer - 1) * 1.4f,
      2 * r - layer * 3.1f, alpha, layer * 73);
  }

  stroke(235, 232, 217, alpha * 0.48f);
  strokeWeight(1.1f);
  drawBrokenCircle(0, -1, 2 * r - 18, alpha, 181);

  stroke(233, 230, 215, alpha * 0.52f);
  arc(0, 8, 2 * r, 2 * r, 0.10f, PI - 0.10f);
  for (int i = 0; i < 29; i++) {
    float a = (i + 0.5f) * PI / 29;
    float xx = cos(a) * (r - 1);
    float yy = sin(a) * (r - 1);
    stroke(232, 229, 215, alpha * (0.22f + 0.22f * hash(i + 91)));
    strokeWeight(0.75f);
    line(xx, yy + 5, xx, yy + 13);
  }

  if (moonFace) {
    drawMoonFaceMark(r, alpha);
  } else {
    textFont(coinFont);
    textAlign(CENTER, CENTER);
    textSize(r * 0.69f);
    fill(239, 237, 225, alpha * 0.78f);
    text("$1", 0, -5);

    noFill();
    for (int i = 0; i < 31; i++) {
      float px = (hash(i * 3.41f + 16) - 0.5f) * r * 1.15f;
      float py = (hash(i * 7.13f + 18) - 0.5f) * r * 0.95f;
      stroke(240, 237, 222, alpha * 0.28f);
      strokeWeight(0.8f);
      point(px, py);
    }
  }
  popMatrix();
  popMatrix();
}

void drawMoonFaceMark(float r, float alpha) {
  // Restore the clear pale-yellow crescent from the concept drawing. The
  // silhouette is immediately readable, while tiny gaps and specks keep its
  // chalk-on-black character rather than making it a polished UI symbol.
  float moonR = r * 0.31f;
  float moonX = -r * 0.025f;
  float moonY = -r * 0.035f;
  float cutX = moonX + moonR * 0.47f;
  float cutY = moonY - moonR * 0.12f;
  float cutR = moonR * 0.86f;

  noStroke();
  fill(243, 218, 139, alpha * 0.90f);
  circle(moonX, moonY, moonR * 2);
  fill(10, 11, 11, 255);
  circle(cutX, cutY, cutR * 2);

  // Sparse pigment variation echoes the rough yellow pencil texture in the
  // concept image without weakening the crescent silhouette.
  for (int i = 0; i < 42; i++) {
    float px = moonX + (hash(i * 7.17f + 5) - 0.5f) * moonR * 1.85f;
    float py = moonY + (hash(i * 4.39f + 13) - 0.5f) * moonR * 1.85f;
    boolean insideMoon = sq(px - moonX) + sq(py - moonY) < sq(moonR * 0.94f);
    boolean outsideCut = sq(px - cutX) + sq(py - cutY) > sq(cutR * 1.02f);
    if (insideMoon && outsideCut) {
      fill(126, 105, 55, alpha * (0.12f + 0.17f * hash(i * 9.31f)));
      circle(px, py, 0.7f + 1.8f * hash(i * 3.83f));
    }
  }

  noFill();
  stroke(255, 237, 169, alpha * 0.46f);
  strokeWeight(1.0f);
  arc(moonX, moonY, moonR * 2.03f, moonR * 2.03f,
    HALF_PI * 0.72f, PI * 1.45f);
  stroke(222, 194, 116, alpha * 0.30f);
  strokeWeight(0.75f);
  arc(cutX, cutY, cutR * 2.02f, cutR * 2.02f,
    HALF_PI, PI * 1.50f);
}

// -------------------------------------------------------------------------
// Water and chalk texture

void drawBlackPaper() {
  noStroke();
  for (int i = 0; i < 1050; i++) {
    float x = hash(i * 2.113f + 3) * width;
    float y = hash(i * 4.671f + 93) * height;
    float a = 3 + 13 * hash(i * 8.231f);
    fill(224, 221, 208, a);
    circle(x, y, 0.4f + 1.15f * hash(i * 3.761f));
  }

  for (int i = 0; i < 120; i++) {
    float x = hash(i * 17.3f) * width;
    float y = hash(i * 22.9f) * height;
    stroke(45, 44, 41, 20 + 20 * hash(i * 3.1f));
    strokeWeight(0.55f);
    line(x, y, x + 28 + 80 * hash(i * 2.2f), y + 3 * (hash(i * 9.8f) - 0.5f));
  }
}

void drawWaterField() {
  noFill();

  for (int stream = 0; stream < 17; stream++) {
    float baseY = 42 + stream * 41;
    float speed = 8.2f + stream * 0.23f;

    // Each broken segment has a stable source position, while its displayed
    // position wraps slowly to the right. The marks themselves now travel,
    // instead of only changing their vertical wave phase.
    for (int step = 0; step < 126; step++) {
      float sourceX0 = -110 + step * 12.2f;
      float sourceX1 = sourceX0 + 12.2f;
      float x0 = flowingX(sourceX0, speed);
      float x1 = flowingX(sourceX1, speed);
      if (x1 <= x0 || x1 < -24 || x0 > width + 24) continue;

      float y0 = waterLineY(sourceX0, baseY, stream);
      float y1 = waterLineY(sourceX1, baseY, stream);
      float grain = hash(stream * 149 + step * 9.31f);
      float distance = dist((x0 + x1) * 0.5f, (y0 + y1) * 0.5f, COIN_X, WATER_Y);
      float depth = rippleDepthEnvelope(surfaceRippleAge);
      float clearance = 104 - 72 * depth;

      if (grain > 0.31f && distance > clearance) {
        float h0 = rippleSurfaceHeight(x0, y0, surfaceRippleAge);
        float h1 = rippleSurfaceHeight(x1, y1, surfaceRippleAge);
        float px0 = rippleProjectedX(x0, y0, h0);
        float py0 = rippleProjectedY(x0, y0, h0);
        float px1 = rippleProjectedX(x1, y1, h1);
        float py1 = rippleProjectedY(x1, y1, h1);
        float crestLight = constrain((h0 + h1) / 38.0f, -0.28f, 0.62f);
        float lineAlpha = (7 + 31 * grain) * (1 + crestLight);

        stroke(233, 231, 219, lineAlpha);
        strokeWeight((0.48f + 0.82f * grain) * (1 + max(0, crestLight) * 0.42f));
        line(px0, py0, px1, py1);
        if (grain > 0.93f) {
          stroke(240, 237, 223, 16 * (1 + max(0, crestLight)));
          line(px0 + 1, py0 + 2.1f, px1 - 1, py1 + 2.1f);
        }
      }
    }
  }

  // Normally invisible intermediate currents become legible only where the
  // disturbance has reached them. Their projected bends reveal crest,
  // trough and foreshortening without changing the flat drawing language.
  drawRevealedSurfaceContours(surfaceRippleAge);

  drawWideCurrent(flowingCurrentX(165, 3.2f), 132, 260, 0.9f, 17);
  drawWideCurrent(flowingCurrentX(284, 4.0f), 566, 355, 1.2f, 83);
  drawWideCurrent(flowingCurrentX(1045, 3.6f), 125, 270, 1.0f, 137);
}

void drawRevealedSurfaceContours(float age) {
  float depth = rippleDepthEnvelope(age);
  if (depth <= 0) return;
  float front = impactWaveRadius(age);

  for (int band = -7; band <= 7; band++) {
    float baseY = WATER_Y + band * 14.5f;
    float speed = 8.9f + band * 0.08f;
    for (int step = 0; step < 92; step++) {
      float sourceX0 = -105 + step * 16.2f;
      float sourceX1 = sourceX0 + 16.2f;
      float x0 = flowingX(sourceX0, speed);
      float x1 = flowingX(sourceX1, speed);
      if (x1 <= x0 || x1 < -24 || x0 > width + 24) continue;

      float y0 = baseY + 3.8f * sin(sourceX0 * 0.011f
        + band * 0.74f + now * 0.18f);
      float y1 = baseY + 3.8f * sin(sourceX1 * 0.011f
        + band * 0.74f + now * 0.18f);
      float midX = (x0 + x1) * 0.5f;
      float midY = (y0 + y1) * 0.5f;
      float dx = midX - COIN_X;
      float dy = (midY - WATER_Y) / 0.54f;
      float radius = sqrt(dx * dx + dy * dy);
      if (radius > front + 72) continue;

      float h0 = rippleSurfaceHeight(x0, y0, age);
      float h1 = rippleSurfaceHeight(x1, y1, age);
      float magnitude = min(1, (abs(h0) + abs(h1)) / 22.0f);
      if (magnitude < 0.045f) continue;
      float reached = ease(constrain((front + 72 - radius) / 105.0f, 0, 1));
      float grain = hash(band * 47.3f + step * 8.1f);

      stroke(234, 232, 220,
        depth * reached * magnitude * (14 + 31 * grain));
      strokeWeight(0.45f + 0.65f * grain);
      line(rippleProjectedX(x0, y0, h0), rippleProjectedY(x0, y0, h0),
           rippleProjectedX(x1, y1, h1), rippleProjectedY(x1, y1, h1));
    }
  }
}

float rippleDepthEnvelope(float age) {
  if (age < 0) return 0;
  float reveal = ease(constrain(age / 0.10f, 0, 1));
  float settle = 1 - ease(constrain((age - 3.75f) / 1.20f, 0, 1));
  return reveal * settle;
}

float gaussian(float value, float centre, float spread) {
  float n = (value - centre) / max(0.001f, spread);
  return exp(-0.5f * n * n);
}

float rippleSurfaceHeight(float x, float y, float age) {
  float depth = rippleDepthEnvelope(age);
  if (depth <= 0) return 0;

  float dx = x - COIN_X;
  float stretchedY = (y - WATER_Y) / 0.54f;
  float radius = sqrt(dx * dx + stretchedY * stretchedY);
  float front = impactWaveRadius(age);

  // A raised crest is followed by a trough and a smaller secondary crest.
  // This is a reversible height field, not a stack of flat ellipses.
  float travelling =
      24 * gaussian(radius, front, 38)
    - 15 * gaussian(radius, front - 67, 42)
    + 9 * gaussian(radius, front - 137, 57);

  // The initial local depression and rebound give the coin visible weight.
  float centreShape = gaussian(radius, 0, 92);
  float impactPulse =
      -25 * gaussian(age, 0.055f, 0.060f)
      + 20 * gaussian(age, 0.205f, 0.085f)
      - 8 * gaussian(age, 0.385f, 0.105f);

  return depth * (travelling + centreShape * impactPulse);
}

float rippleProjectedX(float x, float y, float heightValue) {
  return x + (x - COIN_X) * heightValue * 0.00105f;
}

float rippleProjectedY(float x, float y, float heightValue) {
  float perspective = 1.48f + 0.00035f * (y - WATER_Y);
  return y - heightValue * perspective;
}

float flowingX(float sourceX, float speed) {
  float margin = 110;
  float span = width + margin * 2;
  return (sourceX + now * speed + margin) % span - margin;
}

float flowingCurrentX(float sourceX, float speed) {
  float margin = 430;
  float span = width + margin * 2;
  return (sourceX + now * speed + margin) % span - margin;
}

float waterLineY(float x, float baseY, int stream) {
  float drift = now * 0.085f;
  float longWave = 16 * sin(x * 0.0048f + stream * 0.61f + drift);
  float shortWave = 5 * sin(x * 0.015f - stream * 0.43f - drift * 0.8f);
  float organic = 24 * (noise(x * 0.0024f, stream * 0.19f, drift * 0.25f) - 0.5f);
  return baseY + longWave + shortWave + organic;
}

void drawWideCurrent(float x, float y, float radius, float squash, int seed) {
  for (int ring = 0; ring < 4; ring++) {
    float r = radius + ring * 20;
    drawBrokenEllipse(x, y, r * 2, r * 0.55f * squash,
      24 - ring * 4, 0.8f, seed + ring * 31);
  }
}

void drawQuietRipples(float strength) {
  for (int ring = 0; ring < 7; ring++) {
    float r = 106 + ring * 35 + 4 * sin(now * 0.65f + ring);
    drawBrokenEllipse(COIN_X, WATER_Y + 4,
      r * 2, r * 0.69f,
      strength * (70 - ring * 7),
      0.8f + 0.3f * hash(ring * 11),
      500 + ring * 71);
  }
}

void drawBrokenEllipse(float x, float y, float w, float h,
                       float alpha, float weight, int seed) {
  noFill();
  int segments = 38;
  for (int i = 0; i < segments; i++) {
    float grain = hash(seed + i * 8.17f);
    if (grain < 0.27f) continue;
    float a0 = i * TWO_PI / segments;
    float a1 = (i + 0.70f) * TWO_PI / segments;
    stroke(238, 235, 222, alpha * (0.50f + 0.50f * grain));
    strokeWeight(weight * (0.82f + 0.35f * grain));
    arc(x, y, w, h, a0, a1);
  }
}

void drawBrokenCircle(float x, float y, float diameter, float alpha, int seed) {
  int segments = 46;
  for (int i = 0; i < segments; i++) {
    float grain = hash(seed + i * 9.13f);
    if (grain < 0.17f) continue;
    float a0 = i * TWO_PI / segments;
    float a1 = (i + 0.77f) * TWO_PI / segments;
    arc(x, y, diameter, diameter, a0, a1);
  }
}

void drawInteractionMark(float opacity) {
  float breathe = 0.72f + 0.28f * sin(now * 1.15f);
  noFill();
  stroke(240, 238, 225, opacity * (82 + 34 * breathe));
  strokeWeight(2.1f);
  ellipse(74, 500, 24, 24);
  stroke(240, 238, 225, opacity * (24 + 22 * breathe));
  strokeWeight(0.8f);
  ellipse(75, 499, 29 + 4 * breathe, 29 + 4 * breathe);

  textFont(coinFont);
  textSize(13);
  textAlign(LEFT, CENTER);
  fill(239, 237, 225, opacity * 88);
  String prompt = scene == FINISHED ? "CLICK / SPACE TO REWIND" : "CLICK / SPACE TO TOSS";
  text(prompt, 97, 500);
}

void drawVignette() {
  // A hand-drawn dark edge keeps attention on the water without introducing
  // a glossy digital gradient that would fight the chalk aesthetic.
  noFill();
  for (int i = 0; i < 38; i++) {
    float alpha = 8.5f * (1 - i / 38.0f);
    stroke(0, 0, 0, alpha);
    strokeWeight(2);
    line(0, i, width, i);
    line(0, height - i, width, height - i);
    line(i, 0, i, height);
    line(width - i, 0, width - i, height);
  }
}

float ease(float p) {
  p = constrain(p, 0, 1);
  return p * p * (3 - 2 * p);
}

float hash(float n) {
  float value = sin(n * 78.233f) * 43758.5453f;
  return value - floor(value);
}
