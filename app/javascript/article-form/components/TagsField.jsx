import { h } from 'preact';
import PropTypes from 'prop-types';
import { useTagsField } from '../../hooks/useTagsField';
import { TagAutocompleteOption } from './TagAutocompleteOption';
import { TagAutocompleteSelection } from './TagAutocompleteSelection';
import { MultiSelectAutocomplete } from '@crayons';

/**
 * TagsField for the article form. Allows users to search and select up to 4 tags.
 *
 * @param {Function} onInput Callback to sync selections to article form state
 * @param {string} defaultValue Comma separated list of any currently selected tags
 * @param {Function} switchHelpContext Callback to switch the help context when the field is focused
 */
export const TagsField = ({ onInput, defaultValue, switchHelpContext }) => {
  const { defaultSelections, topTags, fetchSuggestions, syncSelections } =
    useTagsField({ defaultValue, onInput });

  return (
    <MultiSelectAutocomplete
      defaultValue={defaultSelections}
      fetchSuggestions={fetchSuggestions}
      staticSuggestions={topTags}
      staticSuggestionsHeading={
        <h2 className="crayons-article-form__top-tags-heading">Top tags</h2>
      }
      labelText="Add up to 4 tags"
      showLabel={false}
      placeholder="Add up to 4 tags..."
      border={false}
      maxSelections={4}
      SuggestionTemplate={TagAutocompleteOption}
      SelectionTemplate={TagAutocompleteSelection}
      onSelectionsChanged={syncSelections}
      onFocus={switchHelpContext}
      inputId="tag-input"
    />
  );
};

TagsField.propTypes = {
  onInput: PropTypes.func.isRequired,
  defaultValue: PropTypes.string,
  switchHelpContext: PropTypes.func,
};
