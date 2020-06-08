import { h } from 'preact';
import PropTypes from 'prop-types';
import Membership from './Membership';

const RequestedMembershipSection = ({
  requestedMemberships,
  removeRequestedMembership,
  chatChannelAcceptMembership,
  currentMembershipRole
}) => {
    if (!requestedMemberships && requestedMemberships.lenght === 0 ) {
      return null;
    }


    if (currentMembershipRole !== 'mod') {
      return null;
    }

  return (
    <div className="p-4 grid gap-2 crayons-card mb-4">
      <h3 className="mb-2">Joining Request</h3>
      {requestedMemberships.map(pendingMembership => 
        (
          <Membership 
            membership={pendingMembership}
            removeMembership={removeRequestedMembership}
            chatChannelAcceptMembership={chatChannelAcceptMembership}
            membershipType="requested"
            currentMembershipRole={currentMembershipRole}
          /> 
        ) 
      )}
    </div>
  )
}


RequestedMembershipSection.propTypes = {
  requestedMemberships: PropTypes.arrayOf(PropTypes.shape({
    name: PropTypes.string.isRequired,
    membership_id: PropTypes.number.isRequired,
    user_id: PropTypes.number.isRequired,
    role: PropTypes.string.isRequired,
    image: PropTypes.string.isRequired,
    username: PropTypes.string.isRequired,
    status: PropTypes.string.isRequired,
  })).isRequired,
  removeRequestedMembership: PropTypes.func.isRequired,
  chatChannelAcceptMembership: PropTypes.func.isRequired,
  currentMembershipRole: PropTypes.func.isRequired
}

export default RequestedMembershipSection;

