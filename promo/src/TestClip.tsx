import {AbsoluteFill, interpolate, Sequence, useCurrentFrame} from 'remotion';
import {Background} from './components/Background';
import {headState} from './components/ZoneChart';
import {Hero} from './scenes/Hero';
import {Intro} from './scenes/Intro';
import {Outro} from './scenes/Outro';
import {statusColor} from './theme';
import {T} from './timeline';

export const TEST_CLIP_FRAMES = T.total;

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const TestClip: React.FC = () => {
  const frame = useCurrentFrame();
  const progress = interpolate(frame, [T.chartStart, T.chartEnd], [0, 1], clamp);
  const head = headState(progress);
  const glowStrength =
    interpolate(frame, [T.chartStart, T.chartStart + 30], [0, 1], clamp) *
    interpolate(frame, [T.heroOut, T.heroOut + 22], [1, 0], clamp) *
    (head.status === 'critical' ? 1.4 : head.status === 'warning' ? 1 : 0.6);

  return (
    <AbsoluteFill>
      <Background glow={statusColor(head.status)} glowStrength={glowStrength} />
      <Sequence durationInFrames={T.introOut + 10}>
        <Intro />
      </Sequence>
      {/* Hero/Outro read absolute frames from the timeline, so no `from` offset. */}
      <Sequence from={0} durationInFrames={T.total}>
        {frame >= T.phoneIn - 20 && <Hero />}
      </Sequence>
      <Sequence from={0} durationInFrames={T.total}>
        {frame >= T.lockupIn - 2 && <Outro />}
      </Sequence>
    </AbsoluteFill>
  );
};
