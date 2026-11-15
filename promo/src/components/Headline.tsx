import {Img, interpolate, interpolateColors, spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {mark} from '../assetUrls';
import {alpha, C, easeOut, fontFamily, statusColor, type Status} from '../theme';

const LINES = [['Know', 'before'], ["it's", 'critical.']];

const Word: React.FC<{text: string; delay: number; color?: string}> = ({text, delay, color = C.text}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - delay, fps, config: {damping: 200, mass: 0.7}});
  return (
    <span
      style={{
        display: 'inline-block',
        marginRight: '0.24em',
        opacity: p,
        color,
        transform: `translateY(${(1 - p) * 46}px)`,
        filter: `blur(${(1 - p) * 10}px)`,
      }}
    >
      {text}
    </span>
  );
};

export const StatusPill: React.FC<{label: string; s: Status; active: boolean; delay: number}> = ({label, s, active, delay}) => {
  const frame = useCurrentFrame();
  const inP = interpolate(frame, [delay, delay + 20], [0, 1], {easing: easeOut, extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const color = statusColor(s);
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        padding: '10px 18px',
        borderRadius: 999,
        fontSize: 20,
        fontWeight: 600,
        opacity: inP,
        transform: `translateY(${(1 - inP) * 14}px) scale(${active ? 1.06 : 1})`,
        color: active ? C.text : C.text2,
        background: active ? alpha(color, 0.14) : C.surface,
        border: `1px solid ${active ? alpha(color, 0.6) : C.border}`,
        boxShadow: active ? `0 0 28px ${alpha(color, 0.35)}` : 'none',
      }}
    >
      <span style={{width: 10, height: 10, borderRadius: 5, background: color, boxShadow: `0 0 10px ${color}`}} />
      {label}
    </div>
  );
};

export const Headline: React.FC<{start: number; status: Status; criticalAmt: number}> = ({start, status, criticalAmt}) => {
  const frame = useCurrentFrame();
  const sub = interpolate(frame, [start + 34, start + 60], [0, 1], {easing: easeOut, extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const brand = interpolate(frame, [start - 8, start + 16], [0, 1], {easing: easeOut, extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  return (
    <div style={{fontFamily, color: C.text, width: 820}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 18, marginBottom: 44, opacity: brand}}>
        <Img src={mark} style={{width: 74}} />
        <span style={{fontSize: 18, letterSpacing: '0.42em', color: C.text2, fontWeight: 500}}>ASTRONAUT TELEMETRY</span>
      </div>
      <div style={{fontSize: 112, fontWeight: 700, lineHeight: 1.02, letterSpacing: '-0.035em'}}>
        {LINES.map((line, li) => (
          <div key={li}>
            {line.map((w, wi) => (
              <Word
                key={w}
                text={w}
                delay={start + li * 12 + wi * 6}
                color={w === 'critical.' ? interpolateColors(criticalAmt, [0, 1], [C.text, C.critical]) : C.text}
              />
            ))}
          </div>
        ))}
      </div>
      <div style={{fontSize: 28, lineHeight: 1.45, color: C.text2, marginTop: 34, opacity: sub, transform: `translateY(${(1 - sub) * 18}px)`}}>
        Real-time biomedical telemetry with clinical
        <br />
        thresholds, trends and risk alerts.
      </div>
      <div style={{display: 'flex', gap: 14, marginTop: 40}}>
        <StatusPill label="Normal" s="ok" active={status === 'ok'} delay={start + 50} />
        <StatusPill label="Caution" s="warning" active={status === 'warning'} delay={start + 56} />
        <StatusPill label="Critical" s="critical" active={status === 'critical'} delay={start + 62} />
      </div>
    </div>
  );
};
