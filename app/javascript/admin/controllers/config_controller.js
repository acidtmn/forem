import { Controller } from 'stimulus';
import adminModal from '../adminModal';

const recaptchaFields = document.getElementById('recaptchaContainer');
const emailRegistrationCheckbox = document.getElementById(
  'email-registration-checkbox',
);
const emailAuthSettingsSection = document.getElementById(
  'email-auth-settings-section',
);
const emailAuthModalTitle = 'Disable Email address registration';
// TODO: Remove the sentence "You must update site config to save this action!"
// once we build more robust flow for Admin/Config
const emailAuthModalBody = `
  <p>If you disable Email address as a registration option, people cannot create an account with their email address.</p>
  <p>However, people who have already created an account using their email address can continue to login.</p>
  <p><strong>You must confirm and update site config to save below this action.</strong></p>`;

export default class ConfigController extends Controller {
  static targets = [
    'authenticationProviders',
    'authSectionForm',
    'collectiveNoun',
    'configModalAnchor',
    'emailAuthSettingsBtn',
    'enabledIndicator',
    'inviteOnlyMode',
    'requireCaptchaForEmailPasswordRegistration',
  ];

  // GENERAL FUNCTIONS START

  disableTargetField(event) {
    const targetElementName = event.target.dataset.disableTarget;
    const targetElement = this[`${targetElementName}Target`];
    const newValue = event.target.checked;
    targetElement.disabled = newValue;

    // Disable the button generated by ERB for select tags
    if (targetElement.nodeName === 'SELECT') {
      const snakeCaseName = targetElementName.replace(
        /[A-Z]/g,
        (letter) => `_${letter.toLowerCase()}`,
      );
      document.querySelector(
        `button[data-id=site_config_${snakeCaseName}]`,
      ).disabled = newValue;
    }
  }

  closeAdminModal() {
    const authSectionUpdateConfigBtn = this.authSectionFormTarget.querySelector(
      'input[type="submit"]',
    );

    this.configModalAnchorTarget.innerHTML = '';
    document.body.style.height = 'inherit';
    document.body.style.overflowY = 'inherit';

    if (authSectionUpdateConfigBtn.hasAttribute('disabled')) {
      authSectionUpdateConfigBtn.removeAttribute('disabled');
    }
  }

  positionModalOnPage() {
    if (document.getElementsByClassName('crayons-modal')[0]) {
      document.body.style.height = '100vh';
      document.body.style.overflowY = 'hidden';
    }
  }

  // GENERAL FUNCTIONS END

  // EMAIL AUTH FUNCTIONS START

  toggleGoogleRecaptchaFields() {
    if (this.requireCaptchaForEmailPasswordRegistrationTarget.checked) {
      recaptchaFields.classList.remove('hidden');
    } else {
      recaptchaFields.classList.add('hidden');
    }
  }

  enableOrEditEmailAuthSettings(event) {
    event.preventDefault();
    if (this.emailAuthSettingsBtnTarget.dataset.buttonText === 'enable') {
      emailRegistrationCheckbox.checked = true;
      this.emailAuthSettingsBtnTarget.setAttribute('data-button-text', 'edit');
      this.enabledIndicatorTarget.classList.add('visible');
    }
    this.emailAuthSettingsBtnTarget.classList.add('hidden');
    emailAuthSettingsSection.classList.remove('hidden');
  }

  hideEmailAuthSettings(event) {
    event.preventDefault();
    this.emailAuthSettingsBtnTarget.classList.remove('hidden');
    emailAuthSettingsSection.classList.add('hidden');
  }

  activateEmailAuthModal(event) {
    event.preventDefault();
    this.configModalAnchorTarget.innerHTML = adminModal(
      emailAuthModalTitle,
      emailAuthModalBody,
      'Confirm disable',
      'disableEmailAuthFromModal',
      'Cancel',
      'closeAdminModal',
      'crayons-btn crayons-btn--danger',
      'crayons-btn crayons-btn--secondary',
    );
    this.positionModalOnPage();
  }

  disableEmailAuthFromModal(event) {
    event.preventDefault();
    this.disableEmailAuth(event);
    this.closeAdminModal(event);
  }

  disableEmailAuth(event) {
    event.preventDefault();
    emailRegistrationCheckbox.checked = false;
    this.emailAuthSettingsBtnTarget.innerHTML = 'Enable';
    this.emailAuthSettingsBtnTarget.setAttribute('data-button-text', 'enable');
    this.enabledIndicatorTarget.classList.remove('visible');
    this.hideEmailAuthSettings(event);
  }

  // EMAIL AUTH FUNCTIONS END

  // AUTH PROVIDERS FUNCTIONS START

  enableOrEditAuthProvider(event) {
    event.preventDefault();
    const provider = event.target.dataset.authProviderEnable;
    const enabledIndicator = document.getElementById(
      `${provider}-enabled-indicator`,
    );

    document
      .getElementById(`${provider}-auth-settings`)
      .classList.remove('hidden');
    event.target.classList.add('hidden');

    if (event.target.dataset.buttonText === 'enable') {
      enabledIndicator.classList.add('visible');
      event.target.setAttribute('data-enable-auth', 'true');
      this.listAuthToBeEnabled();
    }
  }

  disableAuthProvider(event) {
    event.preventDefault();
    const provider = event.target.dataset.authProvider;
    const enabledIndicator = document.getElementById(
      `${provider}-enabled-indicator`,
    );
    const authEnableButton = document.querySelector(
      `[data-auth-provider-enable="${provider}"]`,
    );
    authEnableButton.setAttribute('data-enable-auth', 'false');
    enabledIndicator.classList.remove('visible');
    this.listAuthToBeEnabled(event);
    this.hideAuthProviderSettings(event);
  }

  authProviderModalTitle(provider) {
    return `Disable ${provider} login`;
  }

  authProviderModalBody(provider) {
    return `<p>If you disable ${provider} as a login option, people cannot authenticate with ${provider}.</p><p><strong>You must update Site Config to save this action!</strong></p>`;
  }

  activateAuthProviderModal(event) {
    event.preventDefault();
    const provider = event.target.dataset.authProvider;
    const official_provider = event.target.dataset.authProviderOfficial;
    this.configModalAnchorTarget.innerHTML = adminModal(
      this.authProviderModalTitle(official_provider),
      this.authProviderModalBody(official_provider),
      'Confirm disable',
      'disableAuthProviderFromModal',
      'Cancel',
      'closeAdminModal',
      'crayons-btn crayons-btn--danger',
      'crayons-btn crayons-btn--secondary',
      'auth-provider',
      provider,
    );
    this.positionModalOnPage();
  }

  disableAuthProviderFromModal(event) {
    event.preventDefault();
    const provider = event.target.dataset.authProvider;
    const authEnableButton = document.querySelector(
      `[data-auth-provider-enable="${provider}"]`,
    );
    const enabledIndicator = document.getElementById(
      `${provider}-enabled-indicator`,
    );
    authEnableButton.setAttribute('data-enable-auth', 'false');
    this.listAuthToBeEnabled(event);
    this.checkForAndGuardSoleAuthProvider();
    enabledIndicator.classList.remove('visible');
    this.hideAuthProviderSettings(event);
    this.closeAdminModal(event);
  }

  checkForAndGuardSoleAuthProvider() {
    if (
      document.querySelectorAll('[data-enable-auth="true"]').length === 1 &&
      document
        .getElementById('email-auth-enable-edit-btn')
        .getAttribute('data-button-text') === 'enable'
    ) {
      const targetAuthDisableBtn = document.querySelector(
        '[data-enable-auth="true"]',
      );
      targetAuthDisableBtn.parentElement.classList.add('crayons-tooltip');
      targetAuthDisableBtn.parentElement.setAttribute(
        'data-tooltip',
        'To edit this, you must first enable Email address as a registration option',
      );
      targetAuthDisableBtn.setAttribute('disabled', true);
    }
  }

  hideAuthProviderSettings(event) {
    event.preventDefault();
    const provider = event.target.dataset.authProvider;
    document
      .getElementById(`${provider}-auth-settings`)
      .classList.add('hidden');
    document.getElementById(`${provider}-auth-btn`).classList.remove('hidden');
  }

  listAuthToBeEnabled() {
    const enabledProviderArray = [];
    document
      .querySelectorAll('[data-enable-auth="true"]')
      .forEach((provider) => {
        enabledProviderArray.push(provider.dataset.authProviderEnable);
      });
    document.getElementById(
      'auth_providers_to_enable',
    ).value = enabledProviderArray;
  }

  adjustAuthenticationOptions() {
    if (this.inviteOnlyModeTarget.checked) {
      document.getElementById('auth_providers_to_enable').value = '';
      emailRegistrationCheckbox.checked = false;
    } else {
      emailRegistrationCheckbox.checked = true;
    }
  }
  // AUTH PROVIDERS FUNCTIONS END

  enabledProvidersWithMissingKeys() {
    const providersWithMissingKeys = [];
    document
      .querySelectorAll('[data-enable-auth="true"]')
      .forEach((provider) => {
        const providerName = provider.dataset.authProviderEnable;
        const officialName = provider.dataset.authProviderOfficial;
        if (
          !document.getElementById(`site_config_${providerName}_key`).value ||
          !document.getElementById(`site_config_${providerName}_secret`).value
        ) {
          providersWithMissingKeys.push(officialName);
        }
      });

    return providersWithMissingKeys;
  }

  generateProvidersList(providers) {
    let list = '';
    providers.forEach((provider) => {
      list += `<li>${provider}</li>`;
    });
    return list;
  }

  missingKeysModalBody(providers) {
    return `<p>You haven't filled out all of the required fields properly to save these settings, specifically for: <ul>${this.generateProvidersList(
      providers,
    )}</ul></p>`;
  }

  submitForm() {
    this.authSectionFormTarget.submit();
  }

  activateMissingKeysModal(providers) {
    this.configModalAnchorTarget.innerHTML = adminModal(
      'Setup not complete',
      this.missingKeysModalBody(providers),
      'Continue editing',
      'closeAdminModal',
      'Save anyway',
      'submitForm',
      'crayons-btn',
      'crayons-btn crayons-btn--secondary',
    );
  }

  configUpdatePrecheck(event) {
    if (this.enabledProvidersWithMissingKeys().length > 0) {
      event.preventDefault();
      this.activateMissingKeysModal(this.enabledProvidersWithMissingKeys());
    } else {
      event.target.submit();
    }
  }
}
