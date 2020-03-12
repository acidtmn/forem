import { h } from 'preact';
import { storiesOf } from '@storybook/react';

import './typography.scss';

storiesOf('Base/Components/Navigation', module).add('Main Navigation', () => (
  <div className="container">
    <div className="body">
      <h2>Navigation: Main nav</h2>
      <p>Used as main nav in left sidebar or dropdowns...</p>
      <p>Can contain icons.</p>
    </div>

    <div className="p-6 bg-smoke-10">
      <a href="#" className="crayons-nav-block crayons-nav-block--current">
        <span className="crayons-icon">🏡</span>
        Home
      </a>
      <a href="#" className="crayons-nav-block">
        <span className="crayons-icon">📻</span>
        Podcasts
      </a>
      <a href="#" className="crayons-nav-block">
        <span className="crayons-icon">🏷</span>
        Tags
      </a>
      <a href="#" className="crayons-nav-block">
        <span className="crayons-icon">📑</span>
        Listings <span className="crayons-indicator">3</span>
      </a>
      <a href="#" className="crayons-nav-block">
        <span className="crayons-icon">👍</span>
        Code of Conduct
      </a>
      <a href="#" className="crayons-nav-block crayons-nav-block--indented">
        More...
      </a>
    </div>

    <pre>
      <a href="#" className="crayons-nav-block">
        ...
      </a>
      <a href="#" className="crayons-nav-block crayons-nav-block--current">
        ...
      </a>

      {/* icon inside */}
      <a href="#" className="crayons-nav-block">
        <span className="crayons-icon">📻</span>
        ...
      </a>
      <a href="#" className="crayons-nav-block">
        <svg className="crayons-icon">...</svg>
        ...
      </a>

      {/* indicator inside */}
      <a href="#" className="crayons-nav-block">
        ...
        <span className="crayons-indicator">3</span>
      </a>

      {/* indented */}
      <a href="#" className="crayons-nav-block crayons-nav-block--indented">
        More...
      </a>
    </pre>
  </div>
));
