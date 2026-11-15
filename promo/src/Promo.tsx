import {AbsoluteFill, Img, interpolate, Sequence, staticFile, useCurrentFrame} from 'remotion';
import {Caption} from './components/Caption';
import {ClipVideo} from './components/ClipVideo';
import {PhoneScreen} from './components/PhoneScreen';
import {CAPTIONS, f, FINALE, INTRO, INTRO_XFADE, PROMO_SECONDS, SCREEN} from './promoTimeline';
import {Finale} from './scenes/Finale';
import {easeInOut} from './theme';

export const PROMO_FRAMES = f(PROMO_SECONDS);

const clamp = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'} as const;
const PHONE_CX = SCREEN.x + SCREEN.w / 2;
const PHONE_CY = SCREEN.y + SCREEN.h / 2;

export const Promo: React.FC<{debug?: boolean}> = ({debug = false}) => {
  const frame = useCurrentFrame();
  const hold = f(INTRO[INTRO.length - 1].until);

  // Scene 5: camera pulls back — the phone recedes toward center and vanishes.
  const pull = interpolate(frame, [f(FINALE.pullStart), f(FINALE.pullEnd)], [0, 1], {easing: easeInOut, ...clamp});
  const stageScale = 1 - 0.62 * pull;
  const stageX = (960 - PHONE_CX) * pull;
  const stageY = (540 - PHONE_CY) * pull;
  const stageOpacity = interpolate(pull, [0.35, 0.95], [1, 0], clamp);

  return (
    <AbsoluteFill style={{backgroundColor: '#000'}}>
      <AbsoluteFill
        style={{
          transformOrigin: `${PHONE_CX}px ${PHONE_CY}px`,
          transform: `translate(${stageX}px, ${stageY}px) scale(${stageScale})`,
          opacity: stageOpacity,
          filter: `blur(${pull * 4}px)`,
        }}
      >
        {/* Scene 1: intro footage, sped up, ends with the phone moved aside. */}
        <Sequence durationInFrames={hold + 2}>
          <ClipVideo
            src="footage/intro-mockup.mp4"
            clips={INTRO}
            xfade={INTRO_XFADE}
            style={{width: 1920, height: 1080, objectFit: 'cover'}}
          />
        </Sequence>
        {/* Scenes 2–4: static final frame of the intro + live app screen. */}
        <Sequence from={hold}>
          <Img src={staticFile('footage/intro-hold.png')} style={{width: 1920, height: 1080}} />
        </Sequence>
        <PhoneScreen debug={debug} />
      </AbsoluteFill>

      {CAPTIONS.map((c) => {
        const dur = f(c.until - c.at);
        return (
          <Sequence key={c.eyebrow} from={f(c.at)} durationInFrames={dur}>
            <AbsoluteFill style={{justifyContent: 'center', paddingLeft: 150}}>
              <Caption
                eyebrow={c.eyebrow}
                title={c.title}
                sub={c.sub}
                pills={'pills' in c ? c.pills : false}
                duration={dur}
              />
            </AbsoluteFill>
          </Sequence>
        );
      })}

      <Sequence from={f(FINALE.pullStart)}>
        <Finale />
      </Sequence>
    </AbsoluteFill>
  );
};
