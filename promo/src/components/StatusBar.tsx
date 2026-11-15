import {fontFamily} from '../theme';

/** Clean status bar (no screen-recorder badge), drawn in app-record.mp4 pixels (1182 wide). */
export const STATUS_BAR_H = 118;

export const StatusBar: React.FC<{scale: number}> = ({scale}) => (
  <div
    style={{
      position: 'absolute',
      left: 0,
      top: 0,
      width: 1182,
      height: STATUS_BAR_H,
      background: '#000',
      transform: `scale(${scale})`,
      transformOrigin: '0 0',
      fontFamily,
      color: '#fff',
    }}
  >
    <span style={{position: 'absolute', left: 66, top: 36, fontSize: 44, fontWeight: 600, letterSpacing: '-0.01em'}}>
      18:48
    </span>
    <svg style={{position: 'absolute', right: 74, top: 42}} width={260} height={46} viewBox="0 0 260 46">
      {/* Wi-Fi */}
      <g fill="#fff" transform="translate(40 4)">
        <path d="M22 38 l-6 -7 a9 9 0 0 1 12 0 z" />
        <path d="M8 22 a20 20 0 0 1 28 0 l-4 4.5 a14 14 0 0 0 -20 0 z" />
        <path d="M0 13 a31 31 0 0 1 44 0 l-4 4.5 a25 25 0 0 0 -36 0 z" />
      </g>
      {/* Signal */}
      <g fill="#fff" transform="translate(100 6)">
        <rect x={0} y={24} width={7} height={10} rx={1.5} />
        <rect x={11} y={16} width={7} height={18} rx={1.5} />
        <rect x={22} y={8} width={7} height={26} rx={1.5} />
        <rect x={33} y={0} width={7} height={34} rx={1.5} />
      </g>
      {/* Battery */}
      <g transform="translate(160 2)">
        <rect x={0} y={0} width={90} height={40} rx={20} fill="#fff" />
        <text x={45} y={29} textAnchor="middle" fontSize={27} fontWeight={700} fill="#000" fontFamily={fontFamily}>
          100
        </text>
      </g>
    </svg>
  </div>
);
