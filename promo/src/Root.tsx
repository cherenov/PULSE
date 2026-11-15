import {Composition} from 'remotion';
import {Promo, PROMO_FRAMES} from './Promo';
import {TestClip, TEST_CLIP_FRAMES} from './TestClip';

export const Root: React.FC = () => (
  <>
    <Composition id="Promo" component={Promo} durationInFrames={PROMO_FRAMES} fps={60} width={1920} height={1080} />
    <Composition
      id="TestClip"
      component={TestClip}
      durationInFrames={TEST_CLIP_FRAMES}
      fps={60}
      width={1920}
      height={1080}
    />
  </>
);
