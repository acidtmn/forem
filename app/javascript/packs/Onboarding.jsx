import { h, render } from 'preact';
import { getUserDataAndCsrfToken } from '../chat/util';
import getUnopenedChannels from '../src/utils/getUnopenedChannels';

HTMLDocument.prototype.ready = new Promise(resolve => {
  if (document.readyState !== 'loading') {
    return resolve();
  }
  document.addEventListener('DOMContentLoaded', () => resolve());
  return null;
});

function isUserSignedIn() {
  return (
    document.head.querySelector(
      'meta[name="user-signed-in"][content="true"]',
    ) !== null
  );
}

function renderPage() {
  import('../src/Onboarding')
    .then(({ default: Onboarding }) =>
      render(<Onboarding />, document.getElementById('top-bar')),
    )
    .catch(error => {
      // eslint-disable-next-line no-console
      console.error('Unable to load onboarding', error);
    });
}

document.ready.then(
  getUserDataAndCsrfToken().then(({ currentUser, csrfToken }) => {
    window.currentUser = currentUser;
    window.csrfToken = csrfToken;

    getUnopenedChannels();

    if (isUserSignedIn() && !currentUser.saw_onboarding) {
      renderPage();
    }
  }),
);
