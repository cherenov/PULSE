import {AbsoluteFill, Img, interpolate, useCurrentFrame} from 'remotion';
import {lockup} from '../assetUrls';
import {C, easeOut, fontFamily} from '../theme';
import {T} from '../timeline';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const Outro: React.FC = () => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [T.lockupIn, T.lockupIn + 30], [0, 1], {easing: easeOut, ...clamp});
  const tag = interpolate(frame, [T.lockupIn + 16, T.lockupIn + 40], [0, 1], {easing: easeOut, ...clamp});

  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center', flexDirection: 'column', gap: 40}}>
      <Img
        src={lockup}
        style={{
          width: 480,
          opacity: p,
          transform: `scale(${0.94 + 0.06 * p})`,
          filter: `blur(${(1 - p) * 10}px)`,
        }}
      />
      <div
        style={{
          fontFamily,
          fontSize: 26,
          color: C.text2,
          letterSpacing: '0.04em',
          opacity: tag,
          transform: `translateY(${(1 - tag) * 12}px)`,
        }}
      >
        Biomedical telemetry for crews in orbit.
      </div>
    </AbsoluteFill>
  );
};
