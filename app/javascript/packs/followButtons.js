import { getInstantClick } from '../topNavigation/utilities';
import { waitOnBaseData } from '../utilities/waitOnBaseData';
import { locale } from '@utilities/locale';

/* global showLoginModal  userData  showModalAfterError browserStoreCache */

/**
 * Sets the text content of the button to the correct 'Follow' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */

function addButtonFollowText(button, style) {
  const { name, className } = JSON.parse(button.dataset.info);

  switch (style) {
    case 'small':
      addAriaLabelToButton({
        button,
        followName: name,
        followType: className,
        style: 'follow',
      });
      button.textContent = '+';
      break;
    case 'follow-back':
      addAriaLabelToButton({
        button,
        followName: name,
        followType: className,
        style: 'follow-back',
      });
      button.textContent = locale('core.follow_back');
      break;
    default:
      addAriaLabelToButton({
        button,
        followName: name,
        followType: className,
        style: 'follow',
      });
      button.textContent = locale('core.follow');
  }
}

/**
 * Sets the aria-label and aria-pressed value of the button
 *
 * @param {HTMLElement} button The Follow button to update.
 * @param {string} followType The followableType of the button.
 * @param {string} followName The name of the followable to be followed.
 * @param {string} style The style of the button from its "info" data attribute
 */
function addAriaLabelToButton({ button, followType, followName, style = '' }) {
  let label = '';
  let pressed = '';
  switch (style) {
    case 'follow':
      label = `Follow ${followType.toLowerCase()}: ${followName}`;
      pressed = 'false';
      break;
    case 'follow-back':
      label = `Follow ${followType.toLowerCase()} back: ${followName}`;
      pressed = 'false';
      break;
    case 'following':
      label = `Follow ${followType.toLowerCase()}: ${followName}`;
      pressed = 'true';
      break;
    case 'self':
      label = `Edit profile`;
      break;
    default:
      label = `Follow ${followType.toLowerCase()}: ${followName}`;
      pressed = 'false';
  }
  button.setAttribute('aria-label', label);
  pressed.length === 0
    ? button.removeAttribute('aria-pressed')
    : button.setAttribute('aria-pressed', pressed);
}

/**
 * Sets the text content of the button to the correct 'Following' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */
function addButtonFollowingText(button, style) {
  button.textContent = style === 'small' ? '✓' : locale('core.following');
}

/**
 * Changes the visual appearance and 'verb' of the button to match the new state
 *
 * @param {HTMLElement} button The Follow button to be updated
 */
function optimisticallyUpdateButtonUI(button) {
  const { verb: newState } = button.dataset;
  const buttonInfo = JSON.parse(button.dataset.info);
  const { style } = buttonInfo;

  // Often there are multiple follow buttons for the same followable item on the page
  // We collect all buttons which match the click, and update them all
  const matchingFollowButtons = Array.from(
    document.getElementsByClassName('follow-action-button'),
  ).filter((button) => {
    const { info } = button.dataset;
    if (info) {
      const { id } = JSON.parse(info);
      return id === buttonInfo.id;
    }
    return false;
  });

  matchingFollowButtons.forEach((matchingButton) => {
    matchingButton.classList.add('showing');

    switch (newState) {
      case 'follow':
      case 'follow-back':
        updateFollowButton(matchingButton, newState, buttonInfo);
        break;
      case 'login':
        addButtonFollowText(matchingButton, style);
        break;
      case 'self':
        updateUserOwnFollowButton(matchingButton);
        break;
      default:
        updateFollowingButton(matchingButton, style);
    }
  });
}

/**
 * Set the Follow button's UI to the 'following' state
 *
 * @param {HTMLElement} button The Follow button to be updated
 * @param {string} style Style of the follow button (e.g. 'small')
 */
function updateFollowingButton(button, style) {
  const { name, className } = JSON.parse(button.dataset.info);
  button.dataset.verb = 'follow';
  addButtonFollowingText(button, style);
  button.classList.remove('crayons-btn--primary');
  button.classList.remove('crayons-btn--secondary');
  button.classList.add('crayons-btn--outlined');
  addAriaLabelToButton({
    button,
    followName: name,
    followType: className,
    style: 'following',
  });
}

/**
 * Update the UI of the given button to the user's own button - i.e. 'Edit profile'
 *
 * @param {HTMLElement} button The Follow button to be updated
 */
function updateUserOwnFollowButton(button) {
  button.dataset.verb = 'self';
  button.textContent = locale('core.edit_profile');
  addAriaLabelToButton({
    button,
    followName: '',
    followType: '',
    style: 'self',
  });
}

/**
 * Update the UI of the given button to the 'follow' or 'follow-back' state
 *
 * @param {HTMLElement} button The Follow button to be updated
 * @param {string} newState The new follow state of the button
 * @param {Object} buttonInfo The parsed info object obtained from the button's dataset
 * @param {string} buttonInfo.style The style of the follow button (e.g 'small')
 * @param {string} buttonInfo.followStyle The crayons button variant (e.g 'primary')
 */
function updateFollowButton(button, newState, buttonInfo) {
  const { style, followStyle } = buttonInfo;

  button.dataset.verb = 'unfollow';
  button.classList.remove('crayons-btn--outlined');

  if (followStyle === 'primary') {
    button.classList.add('crayons-btn--primary');
  } else if (followStyle === 'secondary') {
    button.classList.add('crayons-btn--secondary');
  }

  const nextButtonStyle = newState === 'follow-back' ? newState : style;
  addButtonFollowText(button, nextButtonStyle);
}

/**
 * Checks a click event's target, and if it is a follow button, triggers the appropriate follow action
 *
 * @param {HTMLElement} target The target of the click event
 */
function handleFollowButtonClick({ target }) {
  if (
    target.classList.contains('follow-action-button') ||
    target.classList.contains('follow-user')
  ) {
    const userStatus = document.body.getAttribute('data-user-status');
    if (userStatus === 'logged-out') {
      let trackingData = {};
      if (determineSecondarySource(target)) {
        trackingData = {
          referring_source: determineSecondarySource(target),
          trigger: 'follow_button',
        };
      }
      showLoginModal(trackingData);
      return;
    }

    optimisticallyUpdateButtonUI(target);
    browserStoreCache('remove');

    const { verb } = target.dataset;

    if (verb === 'self') {
      window.location.href = '/settings';
      return;
    }

    const { className, id } = JSON.parse(target.dataset.info);
    const formData = new FormData();
    formData.append('followable_type', className);
    formData.append('followable_id', id);
    formData.append('verb', verb);
    getCsrfToken()
      .then(sendFetch('follow-creation', formData))
      .then((response) => {
        if (response.status !== 200) {
          showModalAfterError({
            response,
            element: 'user',
            action_ing: 'following',
            action_past: 'followed',
            timeframe: 'for a day',
          });
        }
      });
  }
}

/**
 * Determines where the click came from for event tracking
 */
function determineSecondarySource(target) {
  // The follow user buttons have both follow-action-button and follow-user
  // classnames on them. For now we only want to
  // implement tracking for follow-user.
  if (target.classList.contains('follow-user')) {
    return 'user';
  }
}

/**
 * Adds an event listener to the inner page content, to handle any and all follow button clicks with a single handler
 */
function listenForFollowButtonClicks() {
  document
    .getElementById('page-content-inner')
    .addEventListener('click', handleFollowButtonClick);

  document.getElementById(
    'page-content-inner',
  ).dataset.followClicksInitialized = true;
}

/**
 * Sets the UI of the button based on the current following status
 *
 * @param {string} followStatus The current following status for the button
 * @param {HTMLElement} button The button to update
 */
function updateInitialButtonUI(followStatus, button) {
  const buttonInfo = JSON.parse(button.dataset.info);
  const { style } = buttonInfo;
  button.classList.add('showing');

  switch (followStatus) {
    case 'true':
    case 'mutual':
      updateFollowingButton(button, style);
      break;
    case 'follow-back':
      addButtonFollowText(button, followStatus);
      break;
    case 'false':
      updateFollowButton(button, 'follow', buttonInfo);
      break;
    case 'self':
      updateUserOwnFollowButton(button);
      break;
    default:
      addButtonFollowText(button, style);
  }
}

/**
 * Fetches all user 'follow statuses' for the given userIds, and then updates the UI for all buttons related to each user
 *
 * @param {Object} idButtonHash A hash of user IDs and the array buttons which relate to them
 */
function fetchUserFollowStatuses(idButtonHash) {
  const url = new URL('/follows/bulk_show', document.location);
  const searchParams = new URLSearchParams();
  Object.keys(idButtonHash).forEach((id) => {
    searchParams.append('ids[]', id);
  });
  searchParams.append('followable_type', 'User');
  url.search = searchParams;

  fetch(url, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  })
    .then((response) => response.json())
    .then((idStatuses) => {
      Object.keys(idStatuses).forEach((id) => {
        idButtonHash[id].forEach((button) => {
          updateInitialButtonUI(idStatuses[id], button);
        });
      });
    });
}

/**
 * Sets up the initial state of all user follow buttons on the page,
 * by obtaining the 'follow status' of each user and updating the associated buttons' UI.
 */
function initializeAllUserFollowButtons() {
  const buttons = document.querySelectorAll(
    '.follow-action-button.follow-user:not([data-fetched])',
  );

  if (buttons.length === 0) {
    return;
  }

  const userIds = {};

  Array.from(buttons, (button) => {
    button.dataset.fetched = 'fetched';
    const { userStatus } = document.body.dataset;
    const buttonInfo = JSON.parse(button.dataset.info);
    const { name, className } = buttonInfo;

    if (userStatus === 'logged-out') {
      const { style } = buttonInfo;
      addButtonFollowText(button, style);
    } else {
      addAriaLabelToButton({ button, followType: className, followName: name });
      const { id: userId } = buttonInfo;
      if (userIds[userId]) {
        userIds[userId].push(button);
      } else {
        userIds[userId] = [button];
      }
    }
  });

  if (Object.keys(userIds).length > 0) {
    fetchUserFollowStatuses(userIds);
  }
}

/**
 * Individually fetches the current status of a follow button and updates the UI to match
 *
 * @param {HTMLElement} button
 * @param {Object} buttonInfo The parsed buttonInfo object obtained from the button's data-attribute
 */
function fetchFollowButtonStatus(button, buttonInfo) {
  button.dataset.fetched = 'fetched';

  fetch(`/follows/${buttonInfo.id}?followable_type=${buttonInfo.className}`, {
    method: 'GET',
    headers: {
      Accept: 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Content-Type': 'application/json',
    },
    credentials: 'same-origin',
  })
    .then((response) => response.text())
    .then((followStatus) => {
      updateInitialButtonUI(followStatus, button);
    });
}

/**
 * We get Followed Tags from the user's data on the body attribute and based on that we
 * update the UI of the initial state for the follow buttons for tags.
 * This applies only to non-user (tag) follow buttons, user follow buttons are initialized separately
 * via a bulk request.
 */
function initializeNonUserFollowButtons() {
  const nonUserFollowButtons = document.querySelectorAll(
    '.follow-action-button:not(.follow-user):not([data-fetched])',
  );

  waitOnBaseData().then(() => {
    const userLoggedIn =
      document.body.getAttribute('data-user-status') === 'logged-in';

    const user = userLoggedIn ? userData() : null;

    const followed = JSON.parse(user.followed_tags); // we don't filter because we still consider this a follow on the ui .filter((tag) => tag.points >= 0);
    const hidden = JSON.parse(user.followed_tags).filter(
      (tag) => tag.points < 0,
    );

    const followedTags = user ? followed.map((tag) => tag.id) : [];

    const hiddenTags = user ? hidden.map((tag) => tag.id) : [];

    const followedTagIds = new Set(followedTags);
    const hiddenTagIds = new Set(hiddenTags);

    nonUserFollowButtons.forEach((button) => {
      const { info } = button.dataset;
      const buttonInfo = JSON.parse(info);
      const { className, name } = buttonInfo;
      addAriaLabelToButton({ button, followType: className, followName: name });

      if (className === 'Tag' && user) {
        // We don't need to make a network request to 'fetch' the status of tag buttons
        button.dataset.fetched = true;
        const initialButtonFollowState = followedTagIds.has(buttonInfo.id)
          ? 'true'
          : 'false';
        updateInitialButtonUI(initialButtonFollowState, button);

        // TODO: we need a better way to determine the hiddenButton
        // preferably with a classname.
        const hiddenButton = button.nextElementSibling;
        if (hiddenButton) {
          setHiddenTagButtonState(hiddenTagIds, hiddenButton);
        }
      } else {
        fetchFollowButtonStatus(button, buttonInfo);
      }
    });
  });
}

/**
 * Sets the correct UI changes for a button of a tag that is hidden
 * @param {Array} hiddenTagIds an array of ids of tags that are hidden
 * @param {*} button the button for a tag that should be "hidden"
 */
const setHiddenTagButtonState = (hiddenTagIds, button) => {
  const { info } = button.dataset;
  const { id } = JSON.parse(info);
  hiddenTagIds.has(id);

  if (hiddenTagIds.has(id)) {
    button.classList.remove('crayons-btn--ghost');
    button.classList.add('crayons-btn--danger');
    // TODO: add aria label to button
    button.textContent = 'Unhide';
  }
};

initializeAllUserFollowButtons();
initializeNonUserFollowButtons();
listenForFollowButtonClicks();

/**
 * Creates a MutationObserver. The argument passed into the constructor is a callback function that will
 * be called on each DOM change that qualifies. Some follow buttons are added to the DOM dynamically, e.g. search results.
 * hence we listen for any new additions to be fetched.
 *  */
const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      initializeAllUserFollowButtons();
      initializeNonUserFollowButtons();
    }
  });
});

/**
 * A way to determine what qualifies for observation. In this case the target Node is where
 * data-follow-button-container is true. Our observer options are set to observe the target and all
 * of its children. We start observing the DOM for changes below.
 */
document
  .querySelectorAll('[data-follow-button-container]')
  .forEach((followButtonContainer) => {
    observer.observe(followButtonContainer, {
      childList: true,
      subtree: true,
    });
  });

/**
 * Using InstantClick, we remove the MutationObserver when the page changes.
 */
getInstantClick().then((ic) => {
  ic.on('change', () => {
    observer.disconnect();
  });
});

window.addEventListener('beforeunload', () => {
  observer.disconnect();
});
