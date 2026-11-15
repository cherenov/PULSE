import type {Status} from './theme';

export type Pt = {x: number; y: number};

// CPK (U/L) — same thresholds as metrics registry: norm 20–200, crit >300.
export const CPK = {
  unit: 'U/L',
  normalMin: 20,
  normalMax: 200,
  criticalMax: 300,
  minY: 0,
  maxY: 340,
  days: 7,
};

export const cpkStatus = (v: number): Status =>
  v > CPK.criticalMax
    ? 'critical'
    : v > CPK.normalMax || v < CPK.normalMin
      ? 'warning'
      : 'ok';

// Synthetic 7-day series shaped like a real CPK spike.
export const RAW: Pt[] = [
  [0.15, 120], [0.45, 158], [0.8, 162], [1.15, 118], [1.5, 104], [1.85, 152],
  [2.15, 172], [2.45, 136], [2.8, 188], [3.05, 214], [3.3, 226], [3.55, 296],
  [3.8, 288], [4.05, 192], [4.35, 150], [4.65, 118], [4.95, 146], [5.2, 112],
  [5.5, 104], [5.8, 88], [6.1, 130], [6.4, 238], [6.65, 286], [6.9, 323],
].map(([x, y]) => ({x, y}));

/** Monotone cubic Hermite (Fritsch–Carlson) — port of IndicatorChart._smooth. */
export function smooth(pts: Pt[], steps = 14): Pt[] {
  const n = pts.length;
  if (n < 3) return pts;
  const xs = pts.map((p) => p.x);
  const ys = pts.map((p) => p.y);
  const d = Array.from({length: n - 1}, (_, i) => (ys[i + 1] - ys[i]) / (xs[i + 1] - xs[i]));
  const m = new Array<number>(n).fill(0);
  m[0] = d[0];
  m[n - 1] = d[n - 2];
  for (let i = 1; i < n - 1; i++) m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
  for (let i = 0; i < n - 1; i++) {
    if (d[i] === 0) {
      m[i] = 0;
      m[i + 1] = 0;
      continue;
    }
    const a = m[i] / d[i];
    const b = m[i + 1] / d[i];
    const s = a * a + b * b;
    if (s > 9) {
      const t = 3 / Math.sqrt(s);
      m[i] = t * a * d[i];
      m[i + 1] = t * b * d[i];
    }
  }
  const out: Pt[] = [];
  for (let i = 0; i < n - 1; i++) {
    const h = xs[i + 1] - xs[i];
    for (let s = 0; s < steps; s++) {
      const t = s / steps;
      const t2 = t * t;
      const t3 = t2 * t;
      out.push({
        x: xs[i] + h * t,
        y:
          (2 * t3 - 3 * t2 + 1) * ys[i] +
          (t3 - 2 * t2 + t) * h * m[i] +
          (-2 * t3 + 3 * t2) * ys[i + 1] +
          (t3 - t2) * h * m[i + 1],
      });
    }
  }
  out.push(pts[n - 1]);
  return out;
}

export type Segment = {status: Status; pts: Pt[]};

/** Split a line into status zones at threshold crossings — port of _zoneLines. */
export function zoneSegments(spots: Pt[], cuts: number[], status: (v: number) => Status): Segment[] {
  const sorted = [...cuts].sort((a, b) => a - b);
  const segs: Segment[] = [];
  let cur: Segment | null = null;

  const add = (a: Pt, b: Pt) => {
    const s = status((a.y + b.y) / 2);
    if (!cur || cur.status !== s) {
      cur = {status: s, pts: [a]};
      segs.push(cur);
    }
    cur.pts.push(b);
  };

  for (let i = 0; i < spots.length - 1; i++) {
    const a = spots[i];
    const b = spots[i + 1];
    const lo = Math.min(a.y, b.y);
    const hi = Math.max(a.y, b.y);
    const inside = sorted.filter((c) => c > lo && c < hi);
    const crossings = a.y < b.y ? inside : inside.reverse();
    let from = a;
    for (const c of crossings) {
      const t = (c - a.y) / (b.y - a.y);
      const p = {x: a.x + (b.x - a.x) * t, y: c};
      add(from, p);
      from = p;
    }
    add(from, b);
  }
  return segs;
}

/** Linear lookup of y on a polyline at x. */
export function yAt(pts: Pt[], x: number): number {
  if (x <= pts[0].x) return pts[0].y;
  for (let i = 1; i < pts.length; i++) {
    if (pts[i].x >= x) {
      const a = pts[i - 1];
      const b = pts[i];
      return a.y + ((b.y - a.y) * (x - a.x)) / (b.x - a.x);
    }
  }
  return pts[pts.length - 1].y;
}
