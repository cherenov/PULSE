import {alpha, C} from '../theme';

export const SCREEN_W = 390; // logical px, like a real device
export const SCREEN_H = 844;

/** Flat 2D phone frame; children are laid out in a 390×844 logical screen. */
export const PhoneMockup: React.FC<{width: number; children: React.ReactNode}> = ({width, children}) => {
  const bezel = width * 0.03;
  const screenW = width - bezel * 2;
  const k = screenW / SCREEN_W;
  const screenH = SCREEN_H * k;
  const height = screenH + bezel * 2;
  const radius = width * 0.15;

  return (
    <div
      style={{
        width,
        height,
        borderRadius: radius,
        padding: bezel,
        background: 'linear-gradient(145deg, #2a2a2a 0%, #0d0d0d 40%, #1a1a1a 100%)',
        boxShadow: [
          `0 0 0 1.5px ${alpha(C.text, 0.12)}`,
          'inset 0 0 0 2px #050505',
          '0 60px 120px rgba(0,0,0,0.9)',
          '0 20px 40px rgba(0,0,0,0.6)',
        ].join(', '),
        position: 'relative',
      }}
    >
      <div
        style={{
          width: screenW,
          height: screenH,
          borderRadius: radius - bezel,
          overflow: 'hidden',
          position: 'relative',
          background: C.bg,
        }}
      >
        <div style={{width: SCREEN_W, height: SCREEN_H, transform: `scale(${k})`, transformOrigin: 'top left'}}>
          {children}
        </div>
        {/* Camera punch-hole */}
        <div
          style={{
            position: 'absolute',
            top: 12 * k,
            left: '50%',
            width: 11 * k,
            height: 11 * k,
            marginLeft: -5.5 * k,
            borderRadius: '50%',
            background: '#050505',
            boxShadow: `0 0 0 1px ${alpha(C.text, 0.08)}`,
          }}
        />
        {/* Glass reflection */}
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: `linear-gradient(115deg, ${alpha(C.text, 0.07)} 0%, transparent 35%, transparent 70%, ${alpha(C.text, 0.03)} 100%)`,
            pointerEvents: 'none',
          }}
        />
      </div>
    </div>
  );
};
