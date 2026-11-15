import {spring, useCurrentFrame, useVideoConfig} from 'remotion';
import {alpha, C, fontFamily} from '../theme';

/** Floating critical alert — echoes IndicatorWarningCard. */
export const AlertCard: React.FC<{start: number}> = ({start}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const p = spring({frame: frame - start, fps, config: {damping: 14, mass: 0.8, stiffness: 140}});
  const ring = ((frame - start) % 50) / 50;
  if (frame < start) return null;

  return (
    <div
      style={{
        fontFamily,
        width: 510,
        padding: '26px 30px',
        borderRadius: 26,
        background: 'linear-gradient(160deg, #1f0c0e 0%, #120709 100%)',
        border: `1.5px solid ${alpha(C.critical, 0.55)}`,
        boxShadow: `0 30px 80px rgba(0,0,0,0.8), 0 0 60px ${alpha(C.critical, 0.25)}`,
        transform: `scale(${0.82 + 0.18 * p}) translateY(${(1 - p) * 40}px)`,
        opacity: Math.min(1, p * 1.4),
        filter: `blur(${Math.max(0, 1 - p) * 8}px)`,
      }}
    >
      <div style={{display: 'flex', alignItems: 'center', gap: 14}}>
        <div style={{position: 'relative', width: 14, height: 14}}>
          <div style={{position: 'absolute', inset: 0, borderRadius: 7, background: C.critical}} />
          <div
            style={{
              position: 'absolute',
              inset: -16 * ring,
              borderRadius: '50%',
              border: `2px solid ${C.critical}`,
              opacity: 1 - ring,
            }}
          />
        </div>
        <span style={{color: C.critical, fontSize: 17, fontWeight: 700, letterSpacing: '0.22em'}}>CRITICAL</span>
        <span style={{marginLeft: 'auto', color: C.text2, fontSize: 16}}>12:14</span>
      </div>
      <div style={{color: C.text, fontSize: 44, fontWeight: 700, marginTop: 16, letterSpacing: '-0.02em'}}>
        CPK 323 <span style={{fontSize: 26, color: C.text2, fontWeight: 600}}>U/L</span>
      </div>
      <div style={{color: C.text2, fontSize: 19, lineHeight: 1.45, marginTop: 10}}>
        Above the 300 U/L critical limit — muscle damage risk. Medical assessment required.
      </div>
    </div>
  );
};
