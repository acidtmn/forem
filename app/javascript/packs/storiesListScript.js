function hasClass(el, cls) {
  return (
    el.className && new RegExp(`(\\s|^)${  cls  }(\\s|$)`).test(el.className)
  );
}
const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
if (isTouchDevice) {
  const activeLinks = document.getElementsByClassName('active');
  Array.prototype.forEach.call(activeLinks, (el) => {
    el.classList.remove('active');
  });

  document
    .getElementById('main-content')
    .addEventListener('click', (event) => {
      const clickedEl = event.target;
      if (
        hasClass(clickedEl, 'bm-initial') ||
        hasClass(clickedEl, 'bm-success')
      ) {
        //do nothing
      } else if (hasClass(clickedEl.parentNode, 'crayons-story')) {
        clickedEl.parentNode.classList.add('active');
      } else if (hasClass(clickedEl.parentNode.parentNode, 'crayons-story')) {
        clickedEl.parentNode.parentNode.classList.add('active');
      } else if (
        hasClass(clickedEl.parentNode.parentNode.parentNode, 'crayons-story')
      ) {
        clickedEl.parentNode.parentNode.parentNode.classList.add('active');
      }
    });
}

// A custom event that gets dispatched to notify search forms to synchronize their state.
window.dispatchEvent(
  new CustomEvent('syncSearchForms', {
    detail: { querystring: location.search },
  }),
);
