import track from './introTrack.json';
import {INTRO, type Clip} from './promoTimeline';

type P = [number, number];
type Quad = [P, P, P, P]; // TL, TR, BR, BL in 1920×1080 px

const S = track.scale;
const QUADS: Quad[] = track.corners.map((q) => q.map(([x, y]) => [x * S, y * S]) as Quad);
const FINAL = QUADS[QUADS.length - 1];
/** Offset (in source frames) for how the decoder picks the frame at a time. */
const FRAME_EPS = 0.001;

/**
 * Tracked phone quad for the source frame that is actually *displayed* at
 * `sec` — the 24fps intro holds each frame for several 60fps output frames, so
 * interpolating between frames would make the overlay run ahead of the image.
 */
function quadAtSource(sec: number): Quad {
  const k = Math.floor(sec * track.fps + FRAME_EPS) - track.first;
  return QUADS[Math.min(QUADS.length - 1, Math.max(0, k))];
}

const srcTime = (c: Clip, sec: number) => c.srcIn + ((sec - c.at) * (c.srcOut - c.srcIn)) / (c.until - c.at);

/** Phone quad at composition time `sec` (follows the intro edit, then holds). */
export function phoneQuad(sec: number): Quad {
  const last = INTRO[INTRO.length - 1];
  if (sec >= last.until) return FINAL;
  const clip = INTRO.find((c) => sec >= c.at && sec < c.until) ?? last;
  return quadAtSource(srcTime(clip, sec));
}

/** Solve the 3×3 homography mapping quad `from` → quad `to`. */
function homography(from: Quad, to: Quad): number[] {
  const A: number[][] = [];
  for (let i = 0; i < 4; i++) {
    const [x, y] = from[i];
    const [u, v] = to[i];
    A.push([x, y, 1, 0, 0, 0, -u * x, -u * y, u]);
    A.push([0, 0, 0, x, y, 1, -v * x, -v * y, v]);
  }
  // Gaussian elimination with partial pivoting on the 8×9 augmented matrix.
  for (let c = 0; c < 8; c++) {
    let p = c;
    for (let r = c + 1; r < 8; r++) if (Math.abs(A[r][c]) > Math.abs(A[p][c])) p = r;
    [A[c], A[p]] = [A[p], A[c]];
    for (let r = 0; r < 8; r++) {
      if (r === c) continue;
      const m = A[r][c] / A[c][c];
      for (let k = c; k < 9; k++) A[r][k] -= m * A[c][k];
    }
  }
  return A.map((row, i) => row[8] / row[i]);
}

/** CSS matrix3d that warps content laid out for the final frame onto the phone at `sec`. */
export function phoneTransform(sec: number): string {
  const [a, b, c, d, e, f, g, h] = homography(FINAL, phoneQuad(sec));
  return `matrix3d(${a},${d},0,${g},${b},${e},0,${h},0,0,1,0,${c},${f},0,1)`;
}
