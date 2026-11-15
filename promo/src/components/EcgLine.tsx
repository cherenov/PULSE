import {interpolate, useCurrentFrame} from 'remotion';
import {alpha, C, easeInOut} from '../theme';

const W = 1920;

// Flat line with a single PQRST complex in the center.
const ecgPath = (MID: number) => [
  `M 0 ${MID}`,
  `L 820 ${MID}`,
  `C 840 ${MID} 850 ${MID - 22} 870 ${MID - 22}`,
  `C 890 ${MID - 22} 895 ${MID} 910 ${MID}`,
  `L 930 ${MID}`,
  `L 945 ${MID + 40}`,
  `L 968 ${MID - 210}`,
  `L 992 ${MID + 110}`,
  `L 1010 ${MID}`,
  `L 1040 ${MID}`,
  `C 1060 ${MID} 1070 ${MID - 40} 1095 ${MID - 40}`,
  `C 1120 ${MID - 40} 1130 ${MID} 1150 ${MID}`,
  `L ${W} ${MID}`,
].join(' ');
const LEN = 2600;

export const EcgLine: React.FC<{start: number; end: number; fadeAt: number; mid?: number}> = ({
  start,
  end,
  fadeAt,
  mid = 540,
}) => {
  const frame = useCurrentFrame();
  const p = interpolate(frame, [start, end], [0, 1], {
    easing: easeInOut,
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  const opacity = interpolate(frame, [fadeAt, fadeAt + 18], [1, 0], {
    extrapolateLeft: 'clamp',
    extrapolateRight: 'clamp',
  });
  // Trailing fade: only the last ~45% of the drawn line is visible.
  const head = p * LEN;
  const tail = Math.max(0, head - LEN * 0.45);

  return (
    <svg width={W} height={1080} style={{position: 'absolute', inset: 0, opacity}}>
      <defs>
        <filter id="ecgGlow" x="-10%" y="-50%" width="120%" height="200%">
          <feGaussianBlur stdDeviation="6" result="b" />
          <feMerge>
            <feMergeNode in="b" />
            <feMergeNode in="SourceGraphic" />
          </feMerge>
        </filter>
      </defs>
      <path
        d={ecgPath(mid)}
        fill="none"
        stroke={alpha(C.text, 0.95)}
        strokeWidth={3}
        strokeLinejoin="round"
        strokeLinecap="round"
        strokeDasharray={`${Math.max(0.001, head - tail)} ${LEN * 2}`}
        strokeDashoffset={-tail}
        opacity={head > 0 ? 1 : 0}
        filter="url(#ecgGlow)"
      />
    </svg>
  );
};
