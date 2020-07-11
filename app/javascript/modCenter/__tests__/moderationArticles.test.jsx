import { h } from 'preact';
import { render, fireEvent } from '@testing-library/preact';
import { ModerationArticles } from '../moderationArticles';

const getTestArticles = () => {
  const articles = [
    {
      id: 1,
      title: 'An article title',
      path: 'an-article-title-di3',
      published_at: '2019-06-22T16:11:10.590Z',
      cached_tag_list: 'discuss, javascript, beginners',
      user: {
        articles_count: 1,
        name: 'hello',
        id: 1,
      },
    },
    {
      id: 2,
      title:
        'An article title that is quite very actually rather extremely long with all things considered',
      path:
        'an-article-title-that-is-quite-very-actually-rather-extremely-long-with-all-things-considered-fi8',
      published_at: '2019-06-24T09:32:10.590Z',
      cached_tag_list: '',
      user: {
        articles_count: 3,
        name: 'howdy',
        id: 2,
      },
    },
  ];
  return JSON.stringify(articles);
};

describe('<ModerationArticles />', () => {
  beforeEach(() => {
    render(
      <div
        class="mod-index-list"
        id="mod-index-list"
        data-articles={getTestArticles()}
      >
        {/* Mimics the markup generated in articles/show.html.erb */}
        <div
          data-testid="flag-user-modal-container"
          class="flag-user-modal-container hidden"
        />
      </div>,
    );
  });

  it('renders a list of 2 articles', () => {
    render(<   />, document.getElementById('mod-index-list'));

    const listOfArticles = document.querySelectorAll(
      '[data-testid^="mod-article-"]',
    );
    expect(listOfArticles.length).toEqual(2);
  });

  it('renders the iframes on click', () => {
    const { getByTestId } = render(
      <ModerationArticles />,
      document.getElementById('mod-index-list'),
    );
    const singleArticle = getByTestId('mod-article-1');
    singleArticle.click();
    const iframes = singleArticle.querySelectorAll('iframe');
    expect(iframes.length).toEqual(2);
  });

  it('toggles the "opened" class when opening or closing an article', () => {
    const { getByTestId } = render(
      <ModerationArticles />,
      document.getElementById('mod-index-list'),
    );
    const singleArticle = getByTestId('mod-article-2');

    fireEvent.click(singleArticle);
    expect(
      singleArticle.querySelector('.article-iframes-container').classList,
    ).toContain('opened');

    fireEvent.click(singleArticle);
    expect(
      singleArticle.querySelector('.article-iframes-container').classList,
    ).not.toContain('opened');
  });

  it('adds the FlagUser Modal HTML associated with author when article opened', async () => {
    const { getByTestId, queryByTestId, findByTestId } = render(
      <ModerationArticles />,
      document.getElementById('mod-index-list'),
    );

    expect(queryByTestId('flag-user-modal')).toBeNull();

    const singleArticle = getByTestId('mod-article-2');
    singleArticle.click();

    expect(await findByTestId('flag-user-modal')).toBeDefined();

    expect(
      document.querySelector('.flag-user-modal input').dataset.reactableId,
    ).toEqual('2');
  });
});
