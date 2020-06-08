import { h } from 'preact';
import PropTypes from 'prop-types';

const ModFaqSection = ({
  currentMembershipRole
}) => {

  if (currentMembershipRole !== 'mod') {
    return null;
  }

  return (
    <div className="crayons-card grid gap-2 p-4">
      <p>
        Questions about Connect Channel moderation? Contact
        <a
          href="mailto:yo@dev.to"
          target="_blank"
          rel="noopener noreferrer"
          className="mx-2"
        >
          yo@dev.to
        </a>
      </p>
    </div>
  )
}

ModFaqSection.propTypes = {
  currentMembershipRole: PropTypes.string.isRequired
}

export default ModFaqSection;
