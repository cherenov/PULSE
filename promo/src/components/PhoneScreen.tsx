import {AbsoluteFill, interpolate, useCurrentFrame} from 'remotion';
import {phoneTransform} from '../introTrack';
import {f, REC_ASPECT, SCREEN, SCREEN_CLIPS} from '../promoTimeline';
import {alpha, C} from '../theme';
import {ClipVideo} from './ClipVideo';
import {StatusBar} from './StatusBar';

// Fit the full recording (incl. status bar) to the screen height so the
// device proportions stay true; the app's black background hides the side gaps.
const VIDEO_H = SCREEN.h;
const VIDEO_W = VIDEO_H * REC_ASPECT;
const SIDE_GAP = (SCREEN.w - VIDEO_W) / 2;
const CROP_TOP = 0;

/** App screen recording composited into the intro's phone frame. */
export const PhoneScreen: React.FC<{debug?: boolean}> = ({debug}) => {
  const frame = useCurrentFrame();
  const on = f(SCREEN_CLIPS[0].at);
  // Power-on: fade up from black with a soft brightness overshoot.
  const power = interpolate(frame, [on, on + 16], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  const flash = interpolate(frame, [on, on + 8, on + 24], [1, 1.35, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});

  return (
    // Laid out for the intro's final frame, then warped onto the tracked phone.
    <AbsoluteFill style={{transformOrigin: '0 0', transform: phoneTransform(frame / 60)}}>
    <div
      style={{
        position: 'absolute',
        left: SCREEN.x,
        top: SCREEN.y,
        width: SCREEN.w,
        height: SCREEN.h,
        borderRadius: SCREEN.r,
        overflow: 'hidden',
        background: C.bg,
        opacity: power,
        filter: `brightness(${flash})`,
      }}
    >
      <div style={{position: 'absolute', left: SIDE_GAP, top: -CROP_TOP, width: VIDEO_W, height: VIDEO_H}}>
        <ClipVideo
          src="footage/app-record.mp4"
          clips={SCREEN_CLIPS}
          style={{width: VIDEO_W, height: VIDEO_H, objectFit: 'cover'}}
        />
        <StatusBar scale={VIDEO_W / 1182} />
      </div>
      {/* Glass reflection */}
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: `linear-gradient(118deg, ${alpha(C.text, 0.06)} 0%, transparent 32%, transparent 72%, ${alpha(C.text, 0.025)} 100%)`,
        }}
      />
    </div>
    {debug && (
      <div
        style={{
          position: 'absolute',
          left: SCREEN.x,
          top: SCREEN.y,
          width: SCREEN.w,
          height: SCREEN.h,
          border: '2px solid #00ff00',
          boxSizing: 'border-box',
        }}
      />
    )}
    </AbsoluteFill>
  );
};
