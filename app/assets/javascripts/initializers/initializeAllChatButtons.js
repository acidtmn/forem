function attachModalListeners(modalElm) {
  modalElm.querySelector('.close-modal').addEventListener('click', toggleModal);
  modalElm.querySelector('.overlay').addEventListener('click', toggleModal);
}

function detachModalListeners(modalElm) {
  modalElm.querySelector('.close-modal').removeEventListener('click', toggleModal);
  modalElm.querySelector('.overlay').removeEventListener('click', toggleModal);
}

function toggleModal() {
  var modal = document.querySelector('.modal');
  var currentState = modal.style.display;

  if (currentState === 'none') { // show
    modal.style.display = 'block';
    document.getElementById('new-message').focus();
    attachModalListeners(modal);
  } else { // hide
    modal.style.display = 'none';
    detachModalListeners(modal);
  }
}

// finds all elements with chat action button class
function initializeAllChatButtons() {
  var buttons = document.getElementsByClassName('chat-action-button');
  var modal = document.getElementById('new-message-form');
  if (!modal) {
    return;
  }
  var modalInfo = JSON.parse(modal.dataset.info);

  var i;
  for (i = 0; i < buttons.length; i += 1) {
    initializeChatButton(buttons[i], modalInfo);
  }
}

function initializeChatButton(button, modalInfo) {
  // if user logged out, do nothing
  var user = userData();
  if (user === null || user.id === modalInfo.id) {
    return;
  }
  fetchButton(button, modalInfo);
}

function fetchButton(button, modalInfo) {
  var dataRequester;
  // button.dataset.fetched = 'fetched'; // telling initialize that this button has been fetched
  if (window.XMLHttpRequest) {
      dataRequester = new XMLHttpRequest();
  } else {
      dataRequester = new ActiveXObject('Microsoft.XMLHTTP');
  }
  dataRequester.onreadystatechange = function() {
    if (dataRequester.readyState === XMLHttpRequest.DONE && dataRequester.status === 200) {
      addButtonClickHandle(dataRequester.response, button, modalInfo);
    }
  }
  dataRequester.open('GET', '/follows/' + modalInfo.id + '?followable_type=' + modalInfo.className);
  dataRequester.send();
}

function addButtonClickHandle(response, button, modalInfo) {
  // currently lacking error handling

  button.classList.add('showing');
  var linkWrap = document.getElementById("user-connect-redirect");
  if (modalInfo.showChat === "open" && response !== "mutual") {
    linkWrap.removeAttribute("href") // remove link
    button.addEventListener('click', toggleModal);
    button.style.display = 'initial'; // show button
    linkWrap.style.display = 'initial'; // show button
    var form = document.getElementById('new-message-form');
    form.onsubmit = function() {handleChatButtonPress(form); return false;};
  } else if (response === 'mutual') {
    button.removeEventListener('click', toggleModal);
    button.style.display = 'initial'; // show button
    linkWrap.style.display = 'initial'; // show button
  }
}

function handleChatButtonPress(form) {
  var message = document.getElementById('new-message').value;

  if (message.length === 0) {
    alert("can't send empty message!")
    return;
  }

  var formDataInfo = JSON.parse(form.dataset.info);
  var formData = new FormData();

  formData.append('user_id', formDataInfo.id);
  formData.append('message', message);
  formData.append('controller', 'chat_channels');

  getCsrfToken()
    .then(sendFetch('chat-creation', formData))
    .then(() => {
      window.location.href = `/connect/@${formDataInfo.username}`;
    });
}
