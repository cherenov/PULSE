// 30 s promo @60fps. Times are in seconds; use f() to convert to frames.
export const FPS = 60;
export const f = (sec: number) => Math.round(sec * FPS);

export const PROMO_SECONDS = 30;

/** Phone screen opening in the intro's final frame, in 1920×1080 px. */
export const SCREEN = {x: 1249, y: 124, w: 422, h: 828, r: 60};
/** app-record.mp4 is 1182×2560 (19.5:9) — fit to screen height, status bar kept. */
export const REC_ASPECT = 1182 / 2560;

export type Clip = {
  /** Composition start/end (s). */
  at: number;
  until: number;
  /** Source in-point (s); rate is derived so [srcIn, srcOut] fills the slot. */
  srcIn: number;
  srcOut: number;
};

export const rate = (c: Clip) => (c.srcOut - c.srcIn) / (c.until - c.at);

/** Scene 1 — intro-mockup.mp4 (24fps, 11 s), sped up and shortened. */
// Continuous time-remap (no cuts, so the phone never jumps): only the speed changes.
export const INTRO: Clip[] = [
  {at: 0, until: 1.0, srcIn: 0, srcOut: 2.0}, // frame forms (2×)
  {at: 1.0, until: 2.4, srcIn: 2.0, srcOut: 8.0}, // particles + slow zoom (≈4.3×)
  {at: 2.4, until: 4.0, srcIn: 8.0, srcOut: 10.96}, // phone slides aside (≈1.85×)
];
export const INTRO_XFADE = 0;

/** Phone screen — app-record.mp4 (40fps, 37.4 s). */
export const SCREEN_CLIPS: Clip[] = [
  {at: 1.25, until: 2.3, srcIn: 0.6, srcOut: 2.7}, // power-on: PULSE splash (tracks the intro phone)
  {at: 2.3, until: 11.0, srcIn: 2.7, srcOut: 10.1}, // dashboard → Blood → BP (Both Arms)
  {at: 11.0, until: 18.0, srcIn: 10.1, srcOut: 20.0}, // metrics panel: chart + history
  {at: 18.0, until: 22.0, srcIn: 24.7, srcOut: 32.2}, // add record page
  {at: 22.0, until: 26.0, srcIn: 32.25, srcOut: 37.3}, // settings
];

export const CAPTIONS = [
  {
    at: 4.2,
    until: 10.8,
    eyebrow: '01 · Dashboard',
    title: ['Your Health.', 'One Dashboard.'],
    sub: 'Possible health risks at a glance.\nAny indicator within two taps.',
  },
  {
    at: 11.2,
    until: 17.8,
    eyebrow: '02 · Metrics panel',
    title: ['Understand', 'Your Health.'],
    sub: 'Status, history and a chart where colors\nmark the boundaries of the norm.',
    pills: true,
  },
  {
    at: 18.2,
    until: 21.8,
    eyebrow: '03 · Add records',
    title: ['Track Every', 'Change.'],
    sub: 'Enter measurements manually\nwhenever you need to.',
  },
  {
    at: 22.2,
    until: 25.2,
    eyebrow: '04 · Settings',
    title: ['Make It', 'Yours.'],
    sub: 'Personal baselines, data exchange,\nnotifications and appearance.',
  },
] as const;

/** Scene 5 — camera pulls back, phone leaves the frame, brand finale. */
export const FINALE = {pullStart: 25.0, pullEnd: 26.4};
/** Finale beats in frames, local to FINALE.pullStart. */
export const FIN = {ecgStart: 40, ecgEnd: 92, markIn: 80, wordIn: 94, teamIn: 116, tagIn: 132, nextIn: 152};
