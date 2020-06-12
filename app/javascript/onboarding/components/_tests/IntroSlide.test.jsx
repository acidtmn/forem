import { h } from 'preact';
import { render, waitForElement } from '@testing-library/preact';
import { axe } from 'jest-axe';
import fetch from 'jest-fetch-mock';
import '@testing-library/jest-dom';

import IntroSlide from '../IntroSlide';

global.fetch = fetch;

describe('IntroSlide', () => {
  const renderIntroSlide = () => render(
    <IntroSlide
      next={jest.fn()}
      prev={jest.fn()}
      currentSlideIndex={0}
      communityConfig={{
        communityName: 'Community Name',
        communityDescription: 'Some community description',
      }}
      previousLocation={null}
    />
  );

  const getUserData = () =>
    JSON.stringify({
      followed_tag_names: ['javascript'],
      profile_image_90: 'mock_url_link',
      name: 'firstname lastname',
      username: 'username',
    });

  beforeEach(() => {
    document.head.innerHTML = '<meta name="csrf-token" content="some-csrf-token" />';
    document.body.setAttribute('data-user', getUserData());
  });

  it('should load the appropriate welcome text', () => {
    const { getByTestId, getByText } = renderIntroSlide();

    expect(getByTestId('onboarding-introduction-title')).toHaveTextContent(/firstname lastname— welcome to Community Name!/i)
    getByText('Some community description')
  });

  it('should link to the code of conduct', () => {
    const { getByText } = renderIntroSlide();
    expect(getByText(/code of conduct/i)).toHaveAttribute('href');
    expect(getByText(/code of conduct/i).getAttribute('href')).toContain('/code-of-conduct');
  });

  it('should link to the terms and conditions', () => {
    const { getByText } = renderIntroSlide();
    expect(getByText(/terms and conditions/i)).toHaveAttribute('href');
    expect(getByText(/terms and conditions/i).getAttribute('href')).toContain('/terms');
  });

  it('it does not render a stepper', () => {
    const { queryByTestId } = renderIntroSlide();
    expect(queryByTestId('stepper')).toBeNull();
  });

  it('should enable the button if required boxes are checked', async () => {
    const { getByTestId, getByText } = renderIntroSlide();
    fetch.once({});
    expect(getByText(/continue/i)).toBeDisabled();

    const codeOfConductCheckbox = getByTestId('checked-code-of-conduct');
    codeOfConductCheckbox.click()

    const termsCheckbox = getByTestId('checked-terms-and-conditions');
    termsCheckbox.click();

    const nextButton = await waitForElement(() =>
      getByText(/continue/i),
    );
    expect(nextButton).not.toBeDisabled();
  });
});
