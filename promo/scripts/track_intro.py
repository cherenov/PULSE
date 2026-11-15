"""Track the phone outline in intro-mockup.mp4 and write per-frame corners.

Usage (from promo/):  python3 -I scripts/track_intro.py
Needs: ffmpeg on PATH, numpy.  Output: src/introTrack.json

Method
------
Walk backwards in time from the clean final frame. For each frame and each
side of the phone, sample many perpendicular profiles inside a narrow band
around the previous estimate, locate the thin bright outline with a line
(ridge) filter at sub-pixel precision, robustly fit a straight line, and
intersect the four lines to get (virtual) sharp corners. Finally a Hampel
filter in time removes frames where particles/smoke fooled a side, without
smoothing (and so without lagging) genuine motion.
"""
import json
import subprocess
import sys
from pathlib import Path

import numpy as np

SRC = Path('public/footage/intro-mockup.mp4')
OUT = Path('src/introTrack.json')
W, H, FPS = 1280, 720, 24
FIRST = 40         # earliest source frame to track (≈1.67 s)
BAND_MOVING = 16   # px search band while the phone slides aside
BAND_STILL = 6     # before the slide the phone moves ≤1.5 px/frame
FLAT_UNTIL = 198   # before this source frame the phone is axis-aligned (no tilt)
DOLLY_FROM = 66    # from here until FLAT_UNTIL the camera dollies in monotonically


def load():
    raw = subprocess.run(
        ['ffmpeg', '-v', 'error', '-i', str(SRC), '-vf', 'format=gray', '-f', 'rawvideo', '-'],
        check=True, capture_output=True).stdout
    return np.frombuffer(raw, np.uint8).reshape(-1, H, W).astype(np.float32)


def ridge_peak(prof):
    """Sub-pixel position of the thin bright line in a 1-D profile (or None)."""
    # Line filter: centre minus surroundings — favours 1–3 px wide lines over
    # broad glow/smoke and over isolated particles (checked by min contrast).
    p = np.pad(prof, 4, mode='edge')
    resp = p[4:-4] - 0.5 * (p[:-8] + p[8:])
    i = int(np.argmax(resp))
    if resp[i] < 25 or i == 0 or i == len(resp) - 1:
        return None
    a, b, c = resp[i - 1], resp[i], resp[i + 1]
    den = a - 2 * b + c
    return i + (0.5 * (a - c) / den if den != 0 else 0.0)


def robust_line(t, v, fit_slope):
    """Fit v = a*t + b (or v = b) with MAD-based outlier rejection."""
    t, v = np.asarray(t, float), np.asarray(v, float)
    if len(v) < 8:
        return None
    keep = np.ones(len(v), bool)
    for _ in range(3):
        if keep.sum() < 8:
            return None
        if fit_slope:
            a, b = np.polyfit(t[keep], v[keep], 1)
        else:
            a, b = 0.0, float(np.median(v[keep]))
        r = v - (a * t + b)
        mad = np.median(np.abs(r[keep])) + 0.3
        keep = np.abs(r) < 3.0 * mad
    return (float(np.clip(a, -0.05, 0.05)), float(b)) if keep.sum() >= 8 else None


def sample_edge(img, line, ts, vertical, band):
    a, b = line
    pts_t, pts_v = [], []
    for t in ts:
        c = a * t + b
        lo = int(np.floor(c - band))
        hi = int(np.ceil(c + band))
        if vertical:
            if lo < 0 or hi >= W:
                continue
            prof = img[int(round(t)), lo:hi + 1]
        else:
            if lo < 0 or hi >= H:
                continue
            prof = img[lo:hi + 1, int(round(t))]
        pk = ridge_peak(prof)
        if pk is not None:
            pts_t.append(t)
            pts_v.append(lo + pk)
    return pts_t, pts_v


def track_frame(img, lines, tilt):
    left, right, top, bottom = lines
    y0, y1 = top[1] + top[0] * 640, bottom[1] + bottom[0] * 640
    x0, x1 = left[1] + left[0] * 360, right[1] + right[0] * 360
    hgt, wid = y1 - y0, x1 - x0
    # Sides: skip rounded corners and the side buttons (≈20–48% height).
    ys = np.concatenate([np.arange(y0 + 0.12 * hgt, y0 + 0.19 * hgt, 1.5), np.arange(y0 + 0.50 * hgt, y0 + 0.90 * hgt, 1.5)])
    # Top/bottom: skip rounded corners and the top-center notch.
    xs = np.concatenate([np.arange(x0 + 0.16 * wid, x0 + 0.42 * wid, 1.5), np.arange(x0 + 0.58 * wid, x0 + 0.84 * wid, 1.5)])
    new = []
    for line, ts, vertical in ((left, ys, True), (right, ys, True), (top, xs, False), (bottom, xs, False)):
        t, v = sample_edge(img, line, ts, vertical, BAND_MOVING if tilt else BAND_STILL)
        fit = robust_line(t, v, fit_slope=(not vertical) and tilt)
        new.append(fit if fit is not None else line)
    return new


def intersect(v_line, h_line):
    # vertical edge: x = a*y + b ; horizontal edge: y = c*x + d
    a, b = v_line
    c, d = h_line
    y = (c * b + d) / (1 - c * a)
    return [a * y + b, y]


def hampel(x, half=3, k=3.0):
    """Replace isolated outliers with the local median; leaves true motion intact."""
    y = x.copy()
    for i in range(len(x)):
        lo, hi = max(0, i - half), min(len(x), i + half + 1)
        med = np.median(x[lo:hi], axis=0)
        mad = np.median(np.abs(x[lo:hi] - med), axis=0) * 1.4826 + 0.35
        bad = np.abs(x[i] - med) > k * mad
        y[i] = np.where(bad, med, x[i])
    return y


def robust_loess(x, half=7, iters=3):
    """Robust local-quadratic smoothing of a (T, ...) track (tricube × bisquare)."""
    T = len(x)
    flat = x.reshape(T, -1)
    out = flat.copy()
    t_all = np.arange(T, dtype=float)
    for j in range(flat.shape[1]):
        y = flat[:, j]
        rw = np.ones(T)
        for _ in range(iters):
            fit = np.empty(T)
            for i in range(T):
                lo, hi = max(0, i - half), min(T, i + half + 1)
                t = t_all[lo:hi] - i
                w = (1 - (np.abs(t) / (half + 1)) ** 3) ** 3 * rw[lo:hi]
                if w.sum() < 1e-6:
                    fit[i] = y[i]
                    continue
                c = np.polyfit(t, y[lo:hi], 2, w=np.sqrt(w))
                fit[i] = c[-1]
            r = y - fit
            s = np.median(np.abs(r)) * 6 + 1e-6
            u = np.clip(r / s, -1, 1)
            rw = (1 - u ** 2) ** 2
        out[:, j] = fit
    return out.reshape(x.shape)


def isotonic(y, increasing):
    """Pool-adjacent-violators: closest monotone sequence to y (least squares)."""
    v = list(y if increasing else -y)
    blocks = [[val, 1] for val in v]
    i = 0
    while i < len(blocks) - 1:
        if blocks[i][0] > blocks[i + 1][0]:
            m = (blocks[i][0] * blocks[i][1] + blocks[i + 1][0] * blocks[i + 1][1]) / (blocks[i][1] + blocks[i + 1][1])
            blocks[i] = [m, blocks[i][1] + blocks[i + 1][1]]
            del blocks[i + 1]
            i = max(0, i - 1)
        else:
            i += 1
    out = np.concatenate([np.full(n, val) for val, n in blocks])
    return out if increasing else -out


def main():
    frames = load()
    n = len(frames)
    lines = [(0.0, 826.5), (0.0, 1119.0), (0.0, 76.0), (0.0, 640.0)]
    for _ in range(4):
        lines = track_frame(frames[-1], lines, tilt=False)
    corners = {}
    for i in range(n - 1, FIRST - 1, -1):
        lines = track_frame(frames[i], lines, tilt=i >= FLAT_UNTIL)
        l, r, t, b = lines
        corners[i] = [intersect(l, t), intersect(r, t), intersect(r, b), intersect(l, b)]

    idx = list(range(FIRST, n))
    arr = np.array([corners[i] for i in idx])  # (T, 4, 2)
    # Still phase (particles/smoke around a slowly zooming phone): robust
    # smooth curve. Slide phase (clean background, fast motion): per-frame
    # values with only isolated-outlier removal, so nothing lags.
    cut = FLAT_UNTIL - FIRST
    arr[:cut] = robust_loess(arr[:cut])
    # From DOLLY_FROM the camera dollies in steadily: each side moves one way
    # only (left/top decrease, right/bottom increase). Enforce it, then re-smooth.
    d0 = DOLLY_FROM - FIRST
    seg = arr[d0:cut]
    for corner in range(4):
        for axis in range(2):
            left_or_top = (axis == 0 and corner in (0, 3)) or (axis == 1 and corner in (0, 1))
            seg[:, corner, axis] = isotonic(seg[:, corner, axis], increasing=not left_or_top)
    arr[d0:cut] = robust_loess(seg, half=4, iters=1)
    arr[cut:] = hampel(arr[cut:])
    out = {
        'fps': FPS,
        'first': FIRST,
        'scale': 1920 / W,
        # TL, TR, BR, BL per source frame, in source (1280×720) pixels
        'corners': [[[round(float(c), 2) for c in p] for p in q] for q in arr],
    }
    OUT.write_text(json.dumps(out))
    print(f'wrote {OUT} ({n - FIRST} frames)', file=sys.stderr)


if __name__ == '__main__':
    main()
