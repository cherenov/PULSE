import {useMemo} from 'react';
import {AbsoluteFill, random, useCurrentFrame} from 'remotion';

/** Sparse drifting particles + faint diagonal haze, echoing the intro footage. */
export const Starfield: React.FC<{opacity?: number; count?: number}> = ({opacity = 1, count = 170}) => {
  const frame = useCurrentFrame();
  const stars = useMemo(
    () =>
      Array.from({length: count}, (_, i) => ({
        x: random(`x${i}`) * 1920,
        y: random(`y${i}`) * 1080,
        r: 0.6 + random(`r${i}`) ** 3 * 1.8,
        a: 0.25 + random(`a${i}`) * 0.6,
        speed: 0.05 + random(`s${i}`) * 0.2,
        phase: random(`p${i}`) * Math.PI * 2,
      })),
    [count],
  );

  return (
    <AbsoluteFill style={{opacity}}>
      <AbsoluteFill
        style={{
          background:
            'linear-gradient(160deg, transparent 38%, rgba(160,170,200,0.07) 50%, transparent 62%)',
          filter: 'blur(30px)',
        }}
      />
      <svg width={1920} height={1080}>
        {stars.map((s, i) => (
          <circle
            key={i}
            cx={(s.x + frame * s.speed) % 1920}
            cy={(s.y - frame * s.speed * 0.35 + 1080) % 1080}
            r={s.r}
            fill="#fff"
            opacity={s.a * (0.65 + 0.35 * Math.sin(frame / 22 + s.phase))}
          />
        ))}
      </svg>
    </AbsoluteFill>
  );
};
