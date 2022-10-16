describe('Test Login Process', () => {
    it('should be able to log in the Test Site and show correct information', () => {
      cy.visit(Cypress.env('URL') + '#/user/login');
  
      const username = Cypress.env('username');
      const password = Cypress.env('password');
      cy.get('input#username').clear().type(username);
      cy.get('input#password').clear().type(password).type('{enter}');
  
      cy.url().should('include', 'dashboard');
  
      cy.get('h2').should('include.text', 'Hello and Welcome to CloudStack');
      cy.visit(Cypress.env('URL') + '#/account');
      cy.get('tbody.ant-table-tbody tr:first-child a').first().click();
      cy.get('a').contains('View Users').click();
      cy.get('tbody.ant-table-tbody tr:first-child a').first().click();
      cy.get('i.anticon-file-protect').parent().click();
      cy.get('div.ant-modal-footer button.ant-btn-primary').click();
    });
  });