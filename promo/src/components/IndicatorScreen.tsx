import {CPK} from '../chartData';
import {alpha, C, fontFamily, statusColor, type Status} from '../theme';
import {ZoneChart} from './ZoneChart';

const Chip: React.FC<{label: string; active?: boolean}> = ({label, active}) => (
  <div
    style={{
      padding: '9px 14px',
      borderRadius: 9,
      fontSize: 13,
      fontWeight: 600,
      background: active ? C.text : C.surfaceHigh,
      color: active ? C.bg : C.text2,
    }}
  >
    {label}
  </div>
);

const statusLabel = (s: Status) => (s === 'ok' ? 'Normal' : s === 'warning' ? 'Caution' : 'Critical');

/** Recreation of IndicatorDetailScreen for CPK, driven by the chart reveal. */
export const IndicatorScreen: React.FC<{
  progress: number;
  thresholds: number;
  pulse: number;
  value: number;
  status: Status;
  historyIn: number;
}> = ({progress, thresholds, pulse, value, status, historyIn}) => (
  <div style={{width: '100%', height: '100%', background: C.bg, color: C.text, fontFamily, position: 'relative'}}>
    {/* Status bar */}
    <div style={{display: 'flex', justifyContent: 'space-between', padding: '14px 26px 0', fontSize: 14, fontWeight: 600}}>
      <span>18:26</span>
      <span style={{display: 'flex', gap: 6, alignItems: 'center'}}>
        <span style={{width: 16, height: 10, borderRadius: 2, background: alpha(C.text, 0.85)}} />
        <span style={{width: 22, height: 11, borderRadius: 3, border: `1.5px solid ${alpha(C.text, 0.85)}`}} />
      </span>
    </div>

    {/* App bar */}
    <div style={{display: 'flex', alignItems: 'center', gap: 22, padding: '26px 20px 18px', fontSize: 20, fontWeight: 600}}>
      <span style={{fontSize: 22}}>←</span>
      <span>Indicator details</span>
    </div>

    {/* Chart card */}
    <div
      style={{
        margin: '0 16px',
        padding: '20px 18px 18px',
        borderRadius: 22,
        background: C.surface,
        border: `1px solid ${C.border}`,
      }}
    >
      <div style={{fontSize: 19, fontWeight: 700, marginBottom: 16}}>Measurement chart</div>
      <div style={{display: 'flex', gap: 7, alignItems: 'center', marginBottom: 20}}>
        <Chip label="7D" active />
        <Chip label="30D" />
        <Chip label="90D" />
        <Chip label="1Y" />
        <div style={{width: 1, height: 22, background: C.border, margin: '0 2px'}} />
        <Chip label="Smooth" active />
      </div>
      <ZoneChart width={318} height={230} progress={progress} thresholds={thresholds} pulse={pulse} />
      <div style={{display: 'flex', alignItems: 'center', gap: 14, marginTop: 22, padding: '0 6px'}}>
        <div style={{width: 18, height: 3, borderRadius: 2, background: C.text}} />
        <div style={{flex: 1}}>
          <div style={{fontSize: 15, fontWeight: 600}}>CPK</div>
          <div style={{fontSize: 12, color: C.text2, marginTop: 3}}>
            Norm: {CPK.normalMin}–{CPK.normalMax} · Crit: &gt;{CPK.criticalMax}
          </div>
        </div>
        <div style={{fontSize: 18, fontWeight: 700, fontVariantNumeric: 'tabular-nums'}}>
          {Math.round(value)} {CPK.unit}
        </div>
        <div style={{width: 8, height: 8, borderRadius: 4, background: statusColor(status)}} />
      </div>
    </div>

    {/* History */}
    <div style={{padding: '26px 16px 0', opacity: historyIn, transform: `translateY(${(1 - historyIn) * 16}px)`}}>
      <div style={{fontSize: 21, fontWeight: 700}}>Measurement history</div>
      <div style={{fontSize: 13, color: C.text2, marginTop: 6, marginBottom: 14}}>Previous recorded values</div>
      {[
        {t: '15.11.2026 12:14', v: 323, s: 'critical' as Status},
        {t: '15.11.2026 06:14', v: 286, s: 'warning' as Status},
      ].map((r) => (
        <div
          key={r.t}
          style={{
            display: 'flex',
            gap: 14,
            padding: '14px 16px',
            borderRadius: 18,
            background: C.surface,
            border: `1px solid ${C.border}`,
            marginBottom: 10,
          }}
        >
          <div style={{width: 3, borderRadius: 2, background: statusColor(r.s)}} />
          <div style={{flex: 1}}>
            <div style={{fontSize: 13, color: C.text2}}>{r.t}</div>
            <div style={{fontSize: 16, fontWeight: 700, marginTop: 6}}>
              {r.v} {CPK.unit}
            </div>
          </div>
          <div style={{fontSize: 13, fontWeight: 600, color: statusColor(r.s)}}>{statusLabel(r.s)}</div>
        </div>
      ))}
    </div>
  </div>
);
