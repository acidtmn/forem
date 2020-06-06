'use strict';

function initializeCommentDropdown() {
  const announcer = document.getElementById('article-copy-link-announcer');

  function isClipboardSupported() {
    return (
      typeof navigator.clipboard !== "undefined" &&
      navigator.clipboard !== null
    );
  }

  function isNativeAndroidDevice() {
    return (
      navigator.userAgent === 'DEV-Native-android' &&
      typeof AndroidBridge !== "undefined" &&
      AndroidBridge !== null
    );
  }

  function removeClass(className) {
    return element => element.classList.remove(className);
  }

  function getAllByClassName(className) {
    return Array.from(document.getElementsByClassName(className));
  }

  function showAnnouncer() {
    const { activeElement } = document;
    const input =
      activeElement.localName === 'clipboard-copy'
        ? activeElement.querySelector('input')
        : document.getElementById('article-copy-link-input');
    input.focus();
    input.setSelectionRange(0, input.value.length);
    announcer.hidden = false;
  }

  function hideAnnouncer() {
    if (announcer) {
      announcer.hidden = true;
    }
  }

  function execCopyText() {
    document.execCommand('copy');
  }

  function copyText(text, callback, fallback) {
    if (isNativeAndroidDevice()) {
      AndroidBridge.copyToClipboard(text);
      callback();
    } else if (isClipboardSupported()) {
      navigator.clipboard.writeText(text)
        .then(() => {
          callback();
        })
        .catch((err) => {
          fallback();
        });
    } else {
      fallback();
    }
  }

  function copyPermalink(event) {
    var origin = window.location.origin;
    var permalink = origin + event.target.getAttribute("data-permalink");

    copyText(permalink, () => {}, () => {
      event.clipboardData.setData("text/plain", permalink);
      execCopyText();
    });
  }

  function copyArticleLink() {
    const inputValue = document.getElementById('article-copy-link-input').value;

    copyText(inputValue, () => {
      showAnnouncer();
    }, () => {
      showAnnouncer();
      execCopyText();
    });
  }

  function shouldCloseDropdown(event) {
    return !(
      event.target.matches('.dropdown-icon') ||
      event.target.matches('.dropbtn') ||
      event.target.matches('clipboard-copy') ||
      event.target.matches('clipboard-copy input') ||
      event.target.matches('clipboard-copy img') ||
      event.target.parentElement.classList.contains('dropdown-link-row')
    );
  }

  function removeClickListener() {
    // disabling this rule because `removeEventListener` needs
    // a reference to the specific handler. The function is hoisted.
    // eslint-disable-next-line no-use-before-define
    document.removeEventListener('click', outsideClickListener);
  }

  function removeCopyListener() {
    const clipboardCopyElement = document.getElementsByTagName(
      'clipboard-copy',
    )[0];
    if (clipboardCopyElement) {
      clipboardCopyElement.removeEventListener('click', copyArticleLink);
    }
  }

  function removeAllShowing() {
    getAllByClassName('showing').forEach(removeClass('showing'));
  }

  function outsideClickListener(event) {
    if (shouldCloseDropdown(event)) {
      removeAllShowing();
      hideAnnouncer();
      removeClickListener();
    }
  }

  function dropdownFunction(e) {
    var button = e.target.parentElement;
    var dropdownContent = button.parentElement.getElementsByClassName(
      'dropdown-content',
    )[0];
    if (dropdownContent.classList.contains('showing')) {
      dropdownContent.classList.remove('showing');
      removeClickListener();
      removeCopyListener();
      hideAnnouncer();
    } else {
      removeAllShowing();
      dropdownContent.classList.add('showing');
      const clipboardCopyElement = document.getElementsByTagName(
        'clipboard-copy',
      )[0];

      document.addEventListener('click', outsideClickListener);
      if (clipboardCopyElement) {
        clipboardCopyElement.addEventListener('click', copyArticleLink);
      }
    }
  }

  function addDropdownListener(dropdown) {
    dropdown.addEventListener('click', dropdownFunction);
  }

  function copyPermalinkButtonListener(copyPermalinkButton) {
    copyPermalinkButton.addEventListener('click', copyPermalink);
  }

  setTimeout(function addListeners() {
    getAllByClassName('dropbtn').forEach(addDropdownListener);

    getAllByClassName('permalink-copybtn').forEach(copyPermalinkButtonListener);
  }, 100);
}
