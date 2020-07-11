/* eslint-disable jest/expect-expect */
import { h } from 'preact';
import { axe } from 'jest-axe';
import { render, getNodeText } from '@testing-library/preact';
import SingleArticle from '../index';

const getTestArticle = () => ({
  id: 1,
  title: 'An article title',
  path: 'an-article-title-di3',
  publishedAt: '2019-06-22T16:11:10.590Z',
  cachedTagList: 'discuss, javascript, beginners',
  user: {
    articles_count: 1,
    name: 'hello',
  },
});

function TestFlagModalUserContainer() {
  // Mimics the markup generated in articles/show.html.erb
  return (
    <div
      data-testid="flag-user-modal"
      class="flag-user-modal-container hidden"
    />
  );
}

describe('<SingleArticle />', () => {
  it('should have no a11y violations', async () => {
    const { container } = render(
      <>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('renders the article title', () => {
    const { queryByText } = render(
      <>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );

    expect(queryByText(getTestArticle().title)).toBeDefined();
  });

  it('renders the tags', () => {
    const { queryByText } = render(
      <>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );

    expect(queryByText('discuss')).toBeDefined();
    expect(queryByText('javascript')).toBeDefined();
    expect(queryByText('beginners')).toBeDefined();
  });

  it('renders no tags or # symbol when article has no tags', () => {
    const article = {
      id: 2,
      title:
        'An article title that is quite very actually rather extremely long with all things considered',
      path:
        'an-article-title-that-is-quite-very-actually-rather-extremely-long-with-all-things-considered-fi8',
      publishedAt: '2019-06-24T09:32:10.590Z',
      cachedTagList: '',
      user: {
        articles_count: 1,
        name: 'howdy',
      },
    };
    const { container } = render(
      <>
        <SingleArticle {...article} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );
    const text = getNodeText(container.querySelector('.article-title'));
    expect(text).not.toContain('#');
  });

  it('renders the author name', () => {
    const { container } = render(
      <>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );
    const text = getNodeText(container.querySelector('.article-author'));
    expect(text).toContain(getTestArticle().user.name);
  });

  it('renders the hand wave emoji if the author has less than 3 articles ', () => {
    const { container } = render(
      <>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );
    const text = getNodeText(container.querySelector('.article-author'));
    expect(text).toContain('👋');
  });

  it('renders the correct formatted published date', () => {
    const { queryByText } = render(
      <>
        <SingleArticle {...getTestArticle()} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );

    expect(queryByText('Jun 22')).toBeDefined();
  });

  it('renders the correct formatted published date as a time if the date is the same day', () => {
    const article = getTestArticle();
    const publishDate = new Date('Wed Jul 08 2020 12:11:27 GMT-0400');
    article.publishedAt = publishDate.toISOString();

    render(
      <>
        <SingleArticle {...article} toggleArticle={jest.fn()} />
        <TestFlagModalUserContainer />
      </>,
    );

    const readableTime = publishDate
      .toLocaleTimeString()
      .replace(/:\d{2}\s/, ' '); // looks like 8:05 PM

    expect(document.querySelector('time').getAttribute('datetime')).toEqual(
      '2020-07-08T16:11:27.000Z',
    );

    expect(readableTime).toEqual('4:11 PM');
  });

  it('toggles the article when clicked', () => {
    const toggleArticle = jest.fn();
    const article = getTestArticle();
    const { getByTestId } = render(
      <>
        <SingleArticle {...article} toggleArticle={toggleArticle} />
        <TestFlagModalUserContainer />
      </>,
    );

    const button = getByTestId(`mod-article-${article.id}`);
    button.click();

    expect(toggleArticle).toHaveBeenCalledTimes(1);
  });
});
