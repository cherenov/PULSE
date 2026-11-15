import {Easing} from 'remotion';
import {loadFont} from '@remotion/google-fonts/Inter';

// Mirrors lib/theme/app_colors.dart — color is reserved for health status.
export const C = {
  bg: '#000000',
  surface: '#0B0B0B',
  surfaceHigh: '#161616',
  border: '#242424',
  text: '#FFFFFF',
  text2: '#8C8C8C',
  text3: '#4D4D4D',
  ok: '#A9DB7A',
  caution: '#F6CB55',
  critical: '#E5646E',
  // Team accent — used only for the team name in the finale.
  team: '#4C9BFF',
} as const;

export type Status = 'ok' | 'warning' | 'critical';

export const statusColor = (s: Status) =>
  s === 'ok' ? C.ok : s === 'warning' ? C.caution : C.critical;

export const {fontFamily} = loadFont('normal', {
  weights: ['400', '500', '600', '700'],
  subsets: ['latin'],
});

export const easeOut = Easing.bezier(0.22, 1, 0.36, 1);
export const easeInOut = Easing.bezier(0.65, 0, 0.35, 1);

/** Hex color + alpha (0..1) → rgba(). */
export const alpha = (hex: string, a: number) => {
  const n = parseInt(hex.slice(1), 16);
  return `rgba(${(n >> 16) & 255}, ${(n >> 8) & 255}, ${n & 255}, ${a})`;
};
