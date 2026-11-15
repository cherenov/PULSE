import {AbsoluteFill, Img, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {mark, wordmark} from '../assetUrls';
import {EcgLine} from '../components/EcgLine';
import {Starfield} from '../components/Starfield';
import {f, FIN, FINALE} from '../promoTimeline';
import {alpha, C, easeOut, fontFamily} from '../theme';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

const MARK_W = 460;
const MARK_H = (MARK_W * 360) / 952;
const MARK_CY = 400; // the ECG spike resolves into the mark here

/**
 * Scene 5 (local frames from FINALE.pullStart): ECG sweep resolves into the
 * animated PULSE mark + wordmark, then team name (blue), tagline, next step.
 */
export const Finale: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const rise = (start: number, len = 26) => interpolate(frame, [start, start + len], [0, 1], {easing: easeOut, ...clamp});

  const stars = interpolate(frame, [0, f(FINALE.pullEnd - FINALE.pullStart)], [0, 1], clamp);
  const m = spring({frame: frame - FIN.markIn, fps, config: {damping: 200}});
  const w = spring({frame: frame - FIN.wordIn, fps, config: {damping: 200}});
  const team = spring({frame: frame - FIN.teamIn, fps, config: {damping: 18, stiffness: 120}});
  const tag = rise(FIN.tagIn);
  const next = rise(FIN.nextIn);
  // Slow breathing glow on the mark once it has landed.
  const breathe = 0.5 + 0.5 * Math.sin((frame - FIN.markIn) / 28);

  return (
    <AbsoluteFill>
      <Starfield opacity={stars * 0.8} />
      <EcgLine start={FIN.ecgStart} end={FIN.ecgEnd} fadeAt={FIN.markIn} mid={MARK_CY} />

      <AbsoluteFill style={{alignItems: 'center', fontFamily}}>
        <Img
          src={mark}
          style={{
            position: 'absolute',
            top: MARK_CY - MARK_H / 2,
            width: MARK_W,
            opacity: m,
            transform: `scale(${0.7 + 0.3 * m})`,
            filter: `blur(${(1 - m) * 16}px) drop-shadow(0 0 ${30 + 20 * breathe}px ${alpha(C.text, 0.18 + 0.12 * m * breathe)})`,
          }}
        />
        <Img
          src={wordmark}
          style={{
            position: 'absolute',
            top: MARK_CY + MARK_H / 2 + 36,
            width: 290,
            opacity: w,
            transform: `translateY(${(1 - w) * 24}px)`,
            filter: `blur(${(1 - w) * 8}px)`,
          }}
        />
        <div
          style={{
            position: 'absolute',
            top: MARK_CY + MARK_H / 2 + 112,
            fontSize: 52,
            fontWeight: 700,
            letterSpacing: '0.08em',
            color: C.team,
            textShadow: `0 0 28px ${alpha(C.team, 0.6)}`,
            opacity: Math.min(1, team * 1.3),
            transform: `translateY(${(1 - team) * 22}px) scale(${0.92 + 0.08 * team})`,
            filter: `blur(${Math.max(0, 1 - team) * 8}px)`,
          }}
        >
          Badyori
        </div>
        <div
          style={{
            position: 'absolute',
            top: MARK_CY + MARK_H / 2 + 196,
            fontSize: 25,
            color: C.text2,
            letterSpacing: '0.04em',
            opacity: tag,
            transform: `translateY(${(1 - tag) * 12}px)`,
          }}
        >
          Know before it's critical.
        </div>
        <div
          style={{
            position: 'absolute',
            top: MARK_CY + MARK_H / 2 + 270,
            display: 'flex',
            alignItems: 'center',
            gap: 16,
            padding: '14px 26px',
            borderRadius: 999,
            border: `1px solid ${C.border}`,
            background: alpha(C.surface, 0.8),
            opacity: next,
            transform: `translateY(${(1 - next) * 14}px)`,
          }}
        >
          <span style={{fontSize: 16, fontWeight: 700, letterSpacing: '0.28em', color: C.team}}>NEXT STEP</span>
          <span style={{width: 1, height: 20, background: C.border}} />
          <span style={{fontSize: 22, color: C.text}}>Live data from wearable sensors</span>
        </div>
      </AbsoluteFill>
    </AbsoluteFill>
  );
};
