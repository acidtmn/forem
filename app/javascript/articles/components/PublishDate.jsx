import { h } from 'preact';
import PropTypes from 'prop-types';

/* global timeAgo */

export const PublishDate = ({
  readablePublishDate,
  publishedTimestamp,
  publishedAtInt,
}) => {
  const timeAgoIndicator = timeAgo({
    oldTimeInSeconds: publishedAtInt,
    formatter: (x) => x,
    maxDisplayedAge: 60 * 60 * 24 * 7,
  });

  return (
    <time dateTime={publishedTimestamp}>
      {readablePublishDate}
      {' '}
      (
      {timeAgoIndicator}
      )
    </time>
  );
};

PublishDate.defaultProps = {
  publishedTimestamp: null,
  publishedAtInt: null,
};

PublishDate.propTypes = {
  readablePublishDate: PropTypes.string.isRequired,
  publishedTimestamp: PropTypes.string,
  publishedAtInt: PropTypes.string,
};

PublishDate.displayName = 'PublishDate';
