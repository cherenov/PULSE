import {AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {AlertCard} from '../components/AlertCard';
import {Headline} from '../components/Headline';
import {IndicatorScreen} from '../components/IndicatorScreen';
import {PhoneMockup} from '../components/PhoneMockup';
import {headState} from '../components/ZoneChart';
import {easeInOut, easeOut} from '../theme';
import {T} from '../timeline';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

export const Hero: React.FC = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();

  const phone = spring({frame: frame - T.phoneIn, fps, config: {damping: 22, mass: 1.1, stiffness: 80}});
  const progress = interpolate(frame, [T.chartStart, T.chartEnd], [0, 1], {easing: easeInOut, ...clamp});
  const thresholds = interpolate(frame, [T.chartStart - 24, T.chartStart + 6], [0, 1], clamp);
  const historyIn = interpolate(frame, [T.chartStart + 10, T.chartStart + 40], [0, 1], {easing: easeOut, ...clamp});
  const head = headState(progress);
  const criticalAmt = interpolate(frame, [T.chartEnd - 14, T.chartEnd], [0, 1], clamp);
  const pulse = frame >= T.chartEnd ? ((frame - T.chartEnd) % 45) / 45 : 0;

  const push = interpolate(frame, [T.pushStart, T.pushEnd], [1, 1.07], {easing: easeInOut, ...clamp});
  const out = interpolate(frame, [T.heroOut, T.heroOut + 22], [0, 1], {easing: easeInOut, ...clamp});
  // Gentle idle float.
  const float = Math.sin(frame / 38) * 6;

  return (
    <AbsoluteFill
      style={{
        opacity: 1 - out,
        filter: `blur(${out * 10}px)`,
        transform: `scale(${push})`,
        transformOrigin: '62% 58%',
      }}
    >
      <div style={{position: 'absolute', left: 150, top: 0, bottom: 0, display: 'flex', alignItems: 'center'}}>
        <Headline start={T.headlineIn} status={head.status} criticalAmt={criticalAmt} />
      </div>

      <div
        style={{
          position: 'absolute',
          right: 210,
          top: 0,
          bottom: 0,
          display: 'flex',
          alignItems: 'center',
          perspective: 2200,
        }}
      >
        <div
          style={{
            transform: [
              `translateX(${(1 - phone) * 520}px)`,
              `translateY(${float}px)`,
              `rotateY(${-26 + 12 * phone}deg)`,
              `rotateX(${6 - 2 * phone}deg)`,
              `rotateZ(${(1 - phone) * 4}deg)`,
            ].join(' '),
            opacity: Math.min(1, phone * 1.6),
          }}
        >
          <PhoneMockup width={430}>
            <IndicatorScreen
              progress={progress}
              thresholds={thresholds}
              pulse={pulse}
              value={head.value}
              status={head.status}
              historyIn={historyIn}
            />
          </PhoneMockup>
        </div>
      </div>

      <div style={{position: 'absolute', left: 1030, top: 650}}>
        <AlertCard start={T.alertIn} />
      </div>
    </AbsoluteFill>
  );
};
