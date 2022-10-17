
describe('Test Login Process', () => {
    it('should be able to log in the Test Site and show correct information', () => {
      cy.visit(Cypress.env('url') + '#/user/login');
  
      const username = Cypress.env('username');
      const password = Cypress.env('password');
      cy.get('input#username').clear().type(username);
      cy.get('input#password').clear().type(password).type('{enter}');
  
      cy.url().should('include', 'dashboard');
  
      cy.get('h2').should('include.text', 'Hello and Welcome to CloudStack');
      cy.visit(Cypress.env('url') + '#/account', {
        onBeforeLoad(win) {
            cy.spy(win.navigator.clipboard, 'writeText').as('copy');
        },
    });
      cy.get('tbody.ant-table-tbody tr:first-child a').first().click();
      cy.get('a').contains('View Users').click();
      cy.get('tbody.ant-table-tbody tr:first-child a').first().click();

      cy.get('i.anticon-file-protect').parent().click();

      // For older, slower machines, we need to pause for a hot sec so we don't accidentally pick up outstanding requests for our spy
      cy.wait(2000);

      cy.intercept({
        method: 'GET',
        url: '/client/api/*',
      }).as(
        'apiSpy'
      );

      cy.get('div.ant-modal-footer button.ant-btn-primary').click();

      cy.wait('@apiSpy').then((interception) => {
        const apiKey = interception.response.body.registeruserkeysresponse.userkeys.apikey;
        const secretKey = interception.response.body.registeruserkeysresponse.userkeys.secretkey;
        cy.log('API KEY = ' + apiKey);
        cy.log('SECRET KEY = ' + secretKey);
        let contents = `\nAPI_KEY=${apiKey}\nSECRET_KEY=${secretKey}\n`;
        cy.writeFile('../.env', contents, { flag: 'a+' });
      });
     
    });
  });