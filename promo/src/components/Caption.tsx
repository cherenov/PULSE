import {interpolate, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {alpha, C, easeInOut, easeOut, fontFamily} from '../theme';
import {StatusPill} from './Headline';

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;

const Word: React.FC<{text: string; delay: number}> = ({text, delay}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - delay, fps, config: {damping: 200, mass: 0.7}});
  return (
    <span
      style={{
        display: 'inline-block',
        marginRight: '0.24em',
        opacity: p,
        transform: `translateY(${(1 - p) * 44}px)`,
        filter: `blur(${(1 - p) * 10}px)`,
      }}
    >
      {text}
    </span>
  );
};

/** Side caption: eyebrow, kinetic title, subline, optional status pills. Local frames. */
export const Caption: React.FC<{
  eyebrow: string;
  title: readonly string[];
  sub: string;
  pills?: boolean;
  duration: number;
}> = ({eyebrow, title, sub, pills, duration}) => {
  const frame = useCurrentFrame();
  const eb = interpolate(frame, [0, 18], [0, 1], {easing: easeOut, ...clamp});
  const subIn = interpolate(frame, [22, 44], [0, 1], {easing: easeOut, ...clamp});
  const out = interpolate(frame, [duration - 16, duration], [0, 1], {easing: easeInOut, ...clamp});
  let w = 0;

  return (
    <div
      style={{
        fontFamily,
        color: C.text,
        width: 900,
        opacity: 1 - out,
        transform: `translateY(${-out * 24}px)`,
        filter: `blur(${out * 8}px)`,
      }}
    >
      <div style={{display: 'flex', alignItems: 'center', gap: 16, marginBottom: 34, opacity: eb}}>
        <div style={{width: 46 * eb, height: 2, background: alpha(C.text, 0.6)}} />
        <span style={{fontSize: 19, letterSpacing: '0.34em', color: C.text2, fontWeight: 500, textTransform: 'uppercase'}}>
          {eyebrow}
        </span>
      </div>
      <div style={{fontSize: 104, fontWeight: 700, lineHeight: 1.03, letterSpacing: '-0.035em'}}>
        {title.map((line, li) => (
          <div key={li}>
            {line.split(' ').map((word) => (
              <Word key={word + li} text={word} delay={6 + w++ * 5} />
            ))}
          </div>
        ))}
      </div>
      <div
        style={{
          fontSize: 29,
          lineHeight: 1.45,
          color: C.text2,
          marginTop: 30,
          whiteSpace: 'pre-line',
          opacity: subIn,
          transform: `translateY(${(1 - subIn) * 16}px)`,
        }}
      >
        {sub}
      </div>
      {pills && (
        <div style={{display: 'flex', gap: 14, marginTop: 38}}>
          {/* Cycle the highlight through the zones while the chart is on screen. */}
          {(['ok', 'warning', 'critical'] as const).map((s, i) => {
            const active = Math.floor(Math.max(0, frame - 70) / 50) % 3 === i && frame > 70;
            return (
              <StatusPill
                key={s}
                label={s === 'ok' ? 'Normal' : s === 'warning' ? 'Caution' : 'Critical'}
                s={s}
                active={active}
                delay={40 + i * 6}
              />
            );
          })}
        </div>
      )}
    </div>
  );
};
