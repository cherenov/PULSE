import {interpolate, OffthreadVideo, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {f, rate, type Clip} from '../promoTimeline';

const Faded: React.FC<{fadeIn: number; children: React.ReactNode}> = ({fadeIn, children}) => {
  const frame = useCurrentFrame();
  const opacity = fadeIn > 0 ? interpolate(frame, [0, fadeIn], [0, 1], {extrapolateRight: 'clamp'}) : 1;
  return <div style={{position: 'absolute', inset: 0, opacity}}>{children}</div>;
};

/**
 * Plays a list of clips from one source back to back. Each clip is retimed so
 * [srcIn, srcOut] exactly fills [at, until]; consecutive clips overlap by
 * `xfade` seconds and the later one fades in on top.
 */
export const ClipVideo: React.FC<{
  src: string;
  clips: readonly Clip[];
  xfade?: number;
  style?: React.CSSProperties;
}> = ({src, clips, xfade = 0.13, style}) => (
  <>
    {clips.map((c, i) => {
      const last = i === clips.length - 1;
      const dur = f(c.until - c.at) + (last ? 0 : f(xfade));
      return (
        <Sequence key={i} from={f(c.at)} durationInFrames={dur} layout="none">
          <Faded fadeIn={i === 0 ? 0 : f(xfade)}>
            <OffthreadVideo
              src={staticFile(src)}
              muted
              trimBefore={f(c.srcIn)}
              playbackRate={rate(c)}
              style={style}
            />
          </Faded>
        </Sequence>
      );
    })}
  </>
);
