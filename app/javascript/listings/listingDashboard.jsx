import { h, Component } from 'preact';
import { ListingRow } from './dashboard/listingRow';

export class ListingDashboard extends Component {
  state = {
    listings: [],
    listingsMirror: [],
    orgListings: [],
    orgs: [],
    userCredits: 0,
    selectedListings: 'user',
    filter: 'All',
  };

  componentDidMount() {
    const t = this;
    const container = document.getElementById('classifieds-listings-dashboard');
    let listings = [];
    let orgs = [];
    let orgListings = [];
    listings = JSON.parse(container.dataset.listings);
    const listingsMirror = listings;
    orgs = JSON.parse(container.dataset.orgs);
    orgListings = JSON.parse(container.dataset.orglistings);
    const userCredits = container.dataset.usercredits;
    t.setState({ listings, listingsMirror, orgListings, orgs, userCredits });
  }

  render() {
    const {
      listings,
      listingsMirror,
      orgListings,
      userCredits,
      orgs,
      selectedListings,
      filter,
    } = this.state;

    const showListings = (selected, userListings, organizationListings, listingsCopy, selectedFilter) => {
      let displayedListings;
      if (selected === 'user') {
        displayedListings = userListings;
        if (selectedFilter === "Expired") {
          displayedListings = userListings.filter(listing => listing.published === false)
        } else if (selectedFilter === "Active") {
          displayedListings = userListings.filter(listing => listing.published === true)
        }
        return displayedListings.map(listing => <ListingRow listing={listing} />)
      }
      displayedListings = organizationListings;
      if (selectedFilter === "Expired") {
        displayedListings = organizationListings.filter(listing => listing.published === false)
      } else if (selectedFilter === "Active") {
        displayedListings = organizationListings.filter(listing => listing.published === true)
      }
      return displayedListings.map(listing =>
        listing.organization_id === selected ? (
          <ListingRow listing={listing} />
        ) : (
          ''
        ),
      );
    };

    const filterButtons = (
      <div className="listings-dashboard-filter-buttons">
        <span
          onClick={(event) => {this.setState( {filter:event.target.textContent} )}}
          className={`rounded-btn ${filter === 'All' ? 'active' : ''}`}
          role="button" 
          tabIndex="0">
          All
        </span>
        <span
          onClick={(event) => {this.setState( {filter:event.target.textContent} )}}
          className={`rounded-btn ${filter === 'Active' ? 'active' : ''}`}
          role="button" 
          tabIndex="0">
          Active
        </span>
        <span
          onClick={(event) => {this.setState( {filter:event.target.textContent} )}}
          className={`rounded-btn ${filter === 'Expired' ? 'active' : ''}`}
          role="button" 
          tabIndex="0">
          Expired
        </span>
      </div>
    );

    const orgButtons = orgs.map(org => (
      <span
        onClick={() => this.setState({ selectedListings: org.id })}
        className={`rounded-btn ${selectedListings === org.id ? 'active' : ''}`}
        role="button" 
        tabIndex="0"
      >
        {org.name}
      </span>
    ));

    const listingLength = (selected, userListings, organizationListings) => {
      return selected === 'user' ? (
        <h4>
          Listings Made:
          {' '}
          {userListings.length}
        </h4>
      ) : (
        <h4>
          Listings Made:
          {' '}
          {
            organizationListings.filter(
              listing => listing.organization_id === selected,
            ).length
          }
        </h4>
      );
    };

    const creditCount = (selected, userCreds, organizations) => {
      return selected === 'user' ? (
        <h4>
          Credits Available:
          {' '}
          {userCredits}
        </h4>
      ) : (
        <h4>
          Credits Available:
          {' '}
          {organizations.find(org => org.id === selected).unspent_credits_count}
        </h4>
      );
    };

    return (
      <div className="dashboard-listings-container">
        <span
          onClick={() => this.setState({ selectedListings: 'user' })}
          className={`rounded-btn ${
            selectedListings === 'user' ? 'active' : ''
          }`}
        >
          Personal
        </span>
        {orgButtons}
        <div className="dashboard-listings-header-wrapper">
          <div className="dashboard-listings-header">
            <h3>Listings</h3>
            {listingLength(selectedListings, listings, orgListings)}
            <a href="/listings/new">Create a Listing</a>
          </div>
          <div className="dashboard-listings-header">
            <h3>Credits</h3>
            {creditCount(selectedListings, userCredits, orgs)}
            <a href="/credits/purchase" data-no-instant>
              Buy Credits
            </a>
          </div>
        </div>
        {filterButtons}
        <div className="dashboard-listings-view">
          {showListings(selectedListings, listings, orgListings, listingsMirror, filter)}
        </div>
      </div>
    );
  }
}
