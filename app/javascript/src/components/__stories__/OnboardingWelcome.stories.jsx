import { h } from 'preact';
import { storiesOf } from '@storybook/preact';
import { globalModalDecorator } from './story-decorators';
import OnboardingWelcome from '../OnboardingWelcome';

storiesOf('OnboardingWelcome', module)
  .addDecorator(globalModalDecorator)
  .add('Default', () => <OnboardingWelcome />);
