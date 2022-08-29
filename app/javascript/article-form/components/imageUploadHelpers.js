import { handleImageFailure } from './dragAndDropHelpers';

// Placeholder text displayed while an image is uploading
const UPLOADING_IMAGE_PLACEHOLDER = '![Uploading image](...)';

export function handleImageUploadSuccess(textAreaRef) {
  return function (response) {
    // Function is within the component to be able to access
    // textarea ref.
    const editableBodyElement = textAreaRef.current;
    const { links } = response;

    const markdownImageLink = `![Image description](${links[0]})`;
    const { selectionStart, selectionEnd, value } = editableBodyElement;
    if (value.includes(UPLOADING_IMAGE_PLACEHOLDER)) {
      const newSelectedStart =
        value.indexOf(UPLOADING_IMAGE_PLACEHOLDER, 0) +
        markdownImageLink.length;

      editableBodyElement.value = value.replace(
        UPLOADING_IMAGE_PLACEHOLDER,
        markdownImageLink,
      );
      editableBodyElement.selectionStart = newSelectedStart;
      editableBodyElement.selectionEnd = newSelectedStart;
    } else {
      const before = value.substring(0, selectionStart);
      const after = value.substring(selectionEnd, value.length);

      editableBodyElement.value = `${before}\n${markdownImageLink}\n${after}`;
      editableBodyElement.selectionStart =
        selectionStart + markdownImageLink.length;
      editableBodyElement.selectionEnd = editableBodyElement.selectionStart;
    }
  };
}

export function handleImageUploading(textAreaRef) {
  return function () {
    // Function is within the component to be able to access
    // textarea ref.
    const editableBodyElement = textAreaRef.current;

    const { selectionStart, selectionEnd, value } = editableBodyElement;
    const before = value.substring(0, selectionStart);
    const after = value.substring(selectionEnd, value.length);
    const newSelectionStart = `${before}\n${UPLOADING_IMAGE_PLACEHOLDER}`
      .length;

    editableBodyElement.value = `${before}\n${UPLOADING_IMAGE_PLACEHOLDER}\n${after}`;
    editableBodyElement.selectionStart = newSelectionStart;
    editableBodyElement.selectionEnd = newSelectionStart;
  };
}

export function handleImageUploadFailure(textAreaRef) {
  return function (message) {
    // Function is within the component to be able to access
    // textarea ref.
    handleImageFailure(message);
    const editableBodyElement = textAreaRef.current;

    const { value } = editableBodyElement;
    if (value.includes(`\n${UPLOADING_IMAGE_PLACEHOLDER}\n`)) {
      const newSelectionStart = value.indexOf(
        `\n${UPLOADING_IMAGE_PLACEHOLDER}\n`,
        0,
      );

      editableBodyElement.value = value.replace(
        `\n${UPLOADING_IMAGE_PLACEHOLDER}\n`,
        '',
      );
      editableBodyElement.selectionStart = newSelectionStart;
      editableBodyElement.selectionEnd = newSelectionStart;
    }
  };
}
