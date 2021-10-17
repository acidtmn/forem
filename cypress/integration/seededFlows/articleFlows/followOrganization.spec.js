describe('Follow organization from article sidebar', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.viewport('macbook-16');
    cy.fixture('users/articleEditorV1User.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginAndVisit(
        user,
        '/admin_mcadmin/test-organization-article-slug',
      ).then(() => {
        cy.get('[data-follow-clicks-initialized]');
        cy.findByRole('heading', { name: 'Organization test article' });
      });
    });
  });

  it('Follows and unfollows an organization from the sidebar', () => {
    cy.intercept('/follows').as('followRequest');

    cy.findByRole('complementary', { name: 'Author details' }).within(() => {
      cy.findByRole('button', { name: 'Follow organization: Bachmanity' }).as(
        'followButton',
      );
    });

    // Follow
    cy.get('@followButton').click();
    cy.get('@followButton').should('have.text', 'Following');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    // Check that the state persists after refresh
    cy.visitAndWaitForUserSideEffects(
      '/admin_mcadmin/test-organization-article-slug',
    );
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'true');

    // Unfollow
    cy.get('@followButton').click();
    cy.get('@followButton').should('have.text', 'Follow');
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');

    // Check that the state persists after refresh
    cy.visitAndWaitForUserSideEffects(
      '/admin_mcadmin/test-organization-article-slug',
    );
    cy.get('@followButton').should('have.attr', 'aria-pressed', 'false');
  });
});
