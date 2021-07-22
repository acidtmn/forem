/* global showLoginModal userData */

/**
 * Helper function to check if a user is currently following a tag
 *
 * @param {Object} user The current user
 * @param {string} tagId The ID of the tag
 *
 * @returns {boolean}
 */
const doesUserFollowTag = (user, tagId) =>
  !!JSON.parse(user.followed_tags).find((tag) => tag.id === tagId);

/**
 * Sets the text content of the button to the correct 'Follow' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */
function addButtonFollowText(button, style) {
  switch (style) {
    case 'small':
      button.textContent = '+';
      break;
    case 'follow-back':
      button.textContent = 'Follow back';
      break;
    default:
      button.textContent = 'Follow';
  }
}

/**
 * Sets the text content of the button to the correct 'Following' state
 *
 * @param {HTMLElement} button The Follow button to update
 * @param {string} style The style of the button from its "info" data attribute
 */
function addButtonFollowingText(button, style) {
  button.textContent = style === 'small' ? '✓' : 'Following';
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

  button.classList.add('showing');

  switch (newState) {
    case 'follow':
    case 'follow-back':
      updateFollowButton(button, newState, buttonInfo);
      break;
    case 'login':
      addButtonFollowText(button, style);
      break;
    case 'self':
      updateUserOwnFollowButton(button);
      break;
    default:
      updateFollowingButton(button, style);
  }
}

/**
 * Set the Follow button's UI to the 'following' state
 *
 * @param {HTMLElement} button The Follow button to be updated
 * @param {string} style Style of the follow button (e.g. 'small')
 */
function updateFollowingButton(button, style) {
  button.dataset.verb = 'follow';
  addButtonFollowingText(button, style);
  button.classList.remove('crayons-btn--primary');
  button.classList.remove('crayons-btn--secondary');
  button.classList.add('crayons-btn--outlined');
}

/**
 * Update the UI of the given button to the user's own button - i.e. 'Edit profile'
 *
 * @param {HTMLElement} button The Follow button to be updated
 */
function updateUserOwnFollowButton(button) {
  button.dataset.verb = 'self';
  button.textContent = 'Edit profile';
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
      showLoginModal();
      return;
    }

    optimisticallyUpdateButtonUI(target);

    const { verb } = target.dataset;

    if (verb === 'self') {
      window.location.href = '/settings';
      return;
    }

    const buttonDataInfo = JSON.parse(target.dataset.info);
    const formData = new FormData();
    formData.append('followable_type', buttonDataInfo.className);
    formData.append('followable_id', buttonDataInfo.id);
    formData.append('verb', verb);
    getCsrfToken().then(sendFetch('follow-creation', formData));
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
          button.dataset.buttonInitialized = true;
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
    const userStatus = document.body.getAttribute('data-user-status');

    if (userStatus === 'logged-out') {
      const { style } = JSON.parse(button.dataset.info);
      addButtonFollowText(button, style);
    } else {
      const { id: userId } = JSON.parse(button.dataset.info);
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
      button.dataset.buttonInitialized = true;
    });
}

/**
 * Makes sure the initial state of follow buttons is fetched and presented in the UI.
 * User follow buttons are initialized separately via bulk request
 */
function initializeNonUserFollowButtons() {
  const nonUserFollowButtons = document.querySelectorAll(
    '.follow-action-button:not(.follow-user)',
  );

  const user = userData();
  nonUserFollowButtons.forEach((button) => {
    const { info, fetched } = button.dataset;
    const buttonInfo = JSON.parse(info);
    if (
      buttonInfo.className === 'Tag' &&
      user &&
      button.dataset.buttonInitialized !== 'true'
    ) {
      const initialButtonFollowState = doesUserFollowTag(user, buttonInfo.id)
        ? 'true'
        : 'false';
      updateInitialButtonUI(initialButtonFollowState, button);
      button.dataset.buttonInitialized = true;
    } else if (fetched !== 'fetched') {
      fetchFollowButtonStatus(button, buttonInfo);
    }
  });
}

initializeAllUserFollowButtons();
initializeNonUserFollowButtons();
listenForFollowButtonClicks();

// Some follow buttons are added to the DOM dynamically, e.g. search results,
// So we listen for any new additions to be fetched
const observer = new MutationObserver((mutationsList) => {
  mutationsList.forEach((mutation) => {
    if (mutation.type === 'childList') {
      initializeAllUserFollowButtons();
      initializeNonUserFollowButtons();
    }
  });
});

observer.observe(document.getElementById('page-content-inner'), {
  childList: true,
  subtree: true,
});

InstantClick.on('change', () => {
  observer.disconnect();
});

window.addEventListener('beforeunload', () => {
  observer.disconnect();
});
