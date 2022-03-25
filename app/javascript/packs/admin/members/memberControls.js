import { INTERACTIVE_ELEMENTS_QUERY } from '@utilities/dropdownUtils';

const expandSearchButton = document.getElementById('expand-search-btn');
const expandFilterButton = document.getElementById('expand-filter-btn');
const searchSection = document.getElementById('search-users');
const filterSection = document.getElementById('filter-users');

if (
  expandSearchButton &&
  expandFilterButton &&
  searchSection &&
  filterSection
) {
  expandSearchButton.addEventListener('click', () => {
    collapseControlsSection({
      section: filterSection,
      triggerButton: expandFilterButton,
    });

    expandOrCollapseControlsSection({
      section: searchSection,
      triggerButton: expandSearchButton,
    });
  });

  expandFilterButton.addEventListener('click', () => {
    collapseControlsSection({
      section: searchSection,
      triggerButton: expandSearchButton,
    });

    expandOrCollapseControlsSection({
      section: filterSection,
      triggerButton: expandFilterButton,
    });
  });
}

/**
 * Ensures the given controls section is closed.
 *
 * @param {HTMLElement} section The controls section to be closed
 * @param {HTMLElement} triggerButton The button responsible for opening and closing the section
 */
const collapseControlsSection = ({ section, triggerButton }) => {
  if (!section) {
    return;
  }

  section.classList.add('hidden');
  triggerButton.setAttribute('aria-expanded', false);
};

/**
 * Expands the given section if it's currently closed. Otherwise closes it.
 *
 * @param {HTMLElement} section The controls section to be toggled
 * @param {HTMLElement} triggerButton The button responsible for opening and closing the section
 */
const expandOrCollapseControlsSection = ({ section, triggerButton }) => {
  if (!section) {
    return;
  }

  const isExpanded = triggerButton.getAttribute('aria-expanded') === 'true';
  if (isExpanded) {
    section.classList.add('hidden');
    triggerButton.setAttribute('aria-expanded', false);
  } else {
    section.classList.remove('hidden');
    triggerButton.setAttribute('aria-expanded', true);
    sendFocusToFirstInteractiveItem(section);
  }
};

/**
 * Helps provide a more seamless search/filter experience by sending keyboard focus directly to a newly expanded form
 *
 * @param {HTMLElement} element The element to send focus into (e.g. search form)
 */
const sendFocusToFirstInteractiveItem = (element) => {
  element.querySelector(INTERACTIVE_ELEMENTS_QUERY)?.focus();
};
