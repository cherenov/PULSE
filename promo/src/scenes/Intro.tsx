import {AbsoluteFill, Img, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {mark, wordmark} from '../assetUrls';
import {EcgLine} from '../components/EcgLine';
import {easeInOut} from '../theme';
import {T} from '../timeline';

/** ECG sweep resolves into the PULSE mark + wordmark. */
export const Intro: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const m = spring({frame: frame - T.markIn, fps, config: {damping: 200}});
  const w = spring({frame: frame - T.markIn - 12, fps, config: {damping: 200}});
  const out = interpolate(frame, [T.introOut - 14, T.introOut + 4], [0, 1], {
    easing: easeInOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });

  return (
    <AbsoluteFill style={{alignItems: 'center', justifyContent: 'center'}}>
      <EcgLine start={T.ecgStart} end={T.ecgEnd} fadeAt={T.markIn} />
      <div
        style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 46,
          opacity: 1 - out,
          transform: `scale(${1 - out * 0.12})`,
          filter: `blur(${out * 12}px)`,
        }}
      >
        <Img
          src={mark}
          style={{
            width: 520,
            opacity: m,
            transform: `scale(${0.7 + 0.3 * m})`,
            filter: `blur(${(1 - m) * 16}px) drop-shadow(0 0 40px rgba(255,255,255,${0.25 * m}))`,
          }}
        />
        <Img
          src={wordmark}
          style={{
            width: 300,
            opacity: w,
            transform: `translateY(${(1 - w) * 24}px)`,
            letterSpacing: 0,
          }}
        />
      </div>
    </AbsoluteFill>
  );
};
