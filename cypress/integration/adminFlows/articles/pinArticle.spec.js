describe('Pin an article from the admin area', () => {
  beforeEach(() => {
    cy.testSetup();
    cy.fixture('users/adminUser.json').as('user');

    cy.get('@user').then((user) => {
      cy.loginUser(user).then(() => {
        cy.createArticle({
          title: 'Test Article',
          tags: ['beginner', 'ruby', 'go'],
          content: `This is a test article's contents.`,
          published: true,
        }).then(() => {
          cy.createArticle({
            title: 'Test Another Article',
            tags: ['beginner', 'ruby', 'go'],
            content: `This is another test article's contents.`,
            published: true,
          }).then(() => {
            cy.visit('/admin/content_manager/articles');
          });
        });
      });
    });
  });

  it('should pin an article when no other article is currently pinned', () => {
    // Simulate that there is no existing pinned post
    cy.intercept(`${Cypress.config().baseUrl}/stories/feed/pinned_article`, {
      statusCode: 404,
    });

    cy.findAllByRole('checkbox', { name: 'Pinned' }).first().check();
    cy.findAllByRole('button', { name: 'Submit' }).first().click();

    // Verify that the form has submitted and the page has changed to the confirmation page
    cy.url().should('contain', '/content_manager/articles/');

    cy.findAllByRole('checkbox', { name: 'Pinned' })
      .first()
      .should('be.checked');
  });

  it('should change the pinned article', () => {
    cy.findAllByRole('checkbox', { name: 'Pinned' }).first().check();
    cy.findAllByRole('button', { name: 'Submit' }).first().click();

    cy.visit('/admin/content_manager/articles');

    cy.findAllByRole('checkbox', { name: 'Pinned' }).last().check();
    cy.findAllByRole('button', { name: 'Pin new article' }).last().click();
    cy.findAllByRole('button', { name: 'Submit' }).last().click();

    cy.findAllByRole('checkbox', { name: 'Pinned' })
      .first()
      .as('pinnedCheckbox');
    cy.get('@pinnedCheckbox').should('be.checked');
  });

  it('should not change the pinned article', () => {
    cy.findAllByRole('checkbox', { name: 'Pinned' }).first().check();
    cy.findAllByRole('button', { name: 'Submit' }).first().click();

    cy.visit('/admin/content_manager/articles');

    cy.findAllByRole('checkbox', { name: 'Pinned' }).last().check();
    cy.findAllByRole('button', { name: 'Dismiss' }).last().click();
    cy.findAllByRole('button', { name: 'Submit' }).last().click();

    cy.findAllByRole('checkbox', { name: 'Pinned' })
      .first()
      .as('pinnedCheckbox');
    cy.get('@pinnedCheckbox').should('not.be.checked');
  });
});
