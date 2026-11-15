import {useMemo} from 'react';
import {CPK, cpkStatus, RAW, smooth, yAt, zoneSegments, type Pt} from '../chartData';
import {alpha, C, fontFamily, statusColor, type Status} from '../theme';

const STROKE: Record<Status, number> = {ok: 2.5, warning: 3.4, critical: 4.2};
const GLOW: Record<Status, number> = {ok: 0, warning: 8, critical: 12};
const AREA: Record<Status, number> = {ok: 0, warning: 0.1, critical: 0.16};
const LABELS = ['08.11', '10.11', '12.11', '14.11', '15.11'];

/**
 * SVG recreation of IndicatorChart (focused single field): zone-colored
 * segments, glow on warning/critical, dashed thresholds, right-axis labels.
 * `progress` (0..1) reveals the line left → right; `thresholds` fades guides in.
 */
export const ZoneChart: React.FC<{
  width: number;
  height: number;
  progress: number;
  thresholds: number;
  pulse: number;
}> = ({width, height, progress, thresholds, pulse}) => {
  const labelW = 42;
  const bottomH = 28;
  const plotW = width - labelW;
  const plotH = height - bottomH;

  const sx = (x: number) => (x / CPK.days) * plotW;
  const sy = (y: number) => plotH - ((y - CPK.minY) / (CPK.maxY - CPK.minY)) * plotH;

  const {line, segs} = useMemo(() => {
    const line = smooth(RAW);
    return {line, segs: zoneSegments(line, [CPK.normalMin, CPK.normalMax, CPK.criticalMax], cpkStatus)};
  }, []);

  const path = (pts: Pt[]) => pts.map((p, i) => `${i ? 'L' : 'M'}${sx(p.x).toFixed(2)} ${sy(p.y).toFixed(2)}`).join(' ');
  const area = (pts: Pt[]) =>
    `${path(pts)} L${sx(pts[pts.length - 1].x)} ${plotH} L${sx(pts[0].x)} ${plotH} Z`;

  const first = line[0].x;
  const last = line[line.length - 1].x;
  const headX = first + (last - first) * progress;
  const headY = yAt(line, headX);
  const headStatus = cpkStatus(headY);
  const headColor = statusColor(headStatus);
  const revealW = sx(headX);

  const hLine = (y: number, color: string, dash: string, w: number) => (
    <line x1={0} x2={plotW} y1={sy(y)} y2={sy(y)} stroke={color} strokeWidth={w} strokeDasharray={dash} />
  );
  const yLabel = (y: number) => (
    <text x={plotW + 8} y={sy(y) + 4} fill={C.text2} fontSize={10} fontFamily={fontFamily}>
      {y}
    </text>
  );

  return (
    <svg width={width} height={height} style={{overflow: 'visible'}}>
      <defs>
        <clipPath id="reveal">
          <rect x={-10} y={-40} width={revealW + 10} height={plotH + 40} />
        </clipPath>
        {(['warning', 'critical'] as const).map((s) => (
          <filter key={s} id={`glow-${s}`} x="-20%" y="-50%" width="140%" height="200%">
            <feDropShadow dx={0} dy={0} stdDeviation={GLOW[s] / 2} floodColor={statusColor(s)} floodOpacity={s === 'critical' ? 0.75 : 0.55} />
          </filter>
        ))}
      </defs>

      <g opacity={thresholds}>
        {/* Range annotations */}
        <rect x={0} width={plotW} y={sy(CPK.normalMax)} height={sy(CPK.normalMin) - sy(CPK.normalMax)} fill={alpha(C.ok, 0.07)} />
        <rect x={0} width={plotW} y={0} height={sy(CPK.criticalMax)} fill={alpha(C.critical, 0.06)} />
        {[100, 200, 300].map((y) => (
          <line key={y} x1={0} x2={plotW} y1={sy(y)} y2={sy(y)} stroke={alpha(C.border, 0.5)} strokeWidth={1} />
        ))}
        {hLine(CPK.normalMin, alpha(C.text, 0.5), '4 4', 1)}
        {hLine(CPK.normalMax, alpha(C.text, 0.5), '4 4', 1)}
        {hLine(CPK.criticalMax, alpha(C.critical, 0.55), '6 4', 1.2)}
        {yLabel(CPK.normalMin)}
        {yLabel(CPK.normalMax)}
        {yLabel(CPK.criticalMax)}
        {LABELS.map((l, i) => (
          <text key={l} x={(i / 4) * plotW} y={height - 6} fill={C.text3} fontSize={11} textAnchor="middle" fontFamily={fontFamily}>
            {l}
          </text>
        ))}
      </g>

      <g clipPath="url(#reveal)">
        {segs.map((s, i) =>
          AREA[s.status] ? <path key={`a${i}`} d={area(s.pts)} fill={alpha(statusColor(s.status), AREA[s.status])} /> : null,
        )}
        {segs.map((s, i) => (
          <path
            key={i}
            d={path(s.pts)}
            fill="none"
            stroke={statusColor(s.status)}
            strokeWidth={STROKE[s.status]}
            strokeLinecap="round"
            strokeLinejoin="round"
            filter={s.status === 'ok' ? undefined : `url(#glow-${s.status})`}
          />
        ))}
      </g>

      {progress > 0 && (
        <g transform={`translate(${revealW} ${sy(headY)})`}>
          {pulse > 0 && (
            <circle r={6 + pulse * 22} fill="none" stroke={headColor} strokeWidth={2} opacity={(1 - pulse) * 0.9} />
          )}
          <circle r={9} fill={alpha(headColor, 0.25)} />
          <circle r={5} fill={headColor} stroke={C.surfaceHigh} strokeWidth={2} />
        </g>
      )}
    </svg>
  );
};

/** Value + status at the reveal head, shared by chart legend and headline. */
export function headState(progress: number) {
  const line = smooth(RAW);
  const first = line[0].x;
  const last = line[line.length - 1].x;
  const y = yAt(line, first + (last - first) * progress);
  return {value: y, status: cpkStatus(y)};
}
