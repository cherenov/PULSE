import {AbsoluteFill, useCurrentFrame} from 'remotion';
import {alpha, C} from '../theme';

/** Black cockpit background: drifting grid, vignette, status-tinted glow, film grain. */
export const Background: React.FC<{glow?: string; glowStrength?: number}> = ({
  glow = C.text,
  glowStrength = 0,
}) => {
  const frame = useCurrentFrame();
  const drift = (frame * 0.25) % 80;

  return (
    <AbsoluteFill style={{backgroundColor: C.bg, overflow: 'hidden'}}>
      <AbsoluteFill
        style={{
          backgroundImage: `linear-gradient(${alpha(C.text, 0.04)} 1px, transparent 1px), linear-gradient(90deg, ${alpha(C.text, 0.04)} 1px, transparent 1px)`,
          backgroundSize: '80px 80px',
          backgroundPosition: `${drift}px ${drift * 0.5}px`,
          maskImage: 'radial-gradient(ellipse 70% 65% at 55% 50%, black 20%, transparent 80%)',
          WebkitMaskImage: 'radial-gradient(ellipse 70% 65% at 55% 50%, black 20%, transparent 80%)',
        }}
      />
      <AbsoluteFill
        style={{
          background: `radial-gradient(circle 620px at 68% 52%, ${alpha(glow, 0.16 * glowStrength)}, transparent 70%)`,
        }}
      />
      <AbsoluteFill style={{background: 'radial-gradient(ellipse at center, transparent 55%, rgba(0,0,0,0.85) 100%)'}} />
      <svg width="100%" height="100%" style={{position: 'absolute', opacity: 0.06, mixBlendMode: 'screen'}}>
        <filter id="grain">
          <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed={frame % 8} />
          <feColorMatrix type="saturate" values="0" />
        </filter>
        <rect width="100%" height="100%" filter="url(#grain)" />
      </svg>
    </AbsoluteFill>
  );
};
