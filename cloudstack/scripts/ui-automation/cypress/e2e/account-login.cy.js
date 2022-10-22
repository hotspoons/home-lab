
describe('Automate credentials scraping from cloudstack', () => {
    it('should be able to log in the Test Site and show correct information', () => {
      let cs_ver = "4.17";
      let gen_key_selector = 'span.anticon-file-protect';
      let ok_button_selector = 'div.ant-modal-body button.ant-btn-primary';
      if(Cypress.env('CLOUDSTACK_VERSION') !== undefined){
        cs_ver = Cypress.env('CLOUDSTACK_VERSION');
      }

      switch(cs_ver){
        case "4.15":
        case "4.16":
          gen_key_selector = 'i.anticon-file-protect';
          ok_button_selector = 'div.ant-modal-footer button.ant-btn-primary';
          break;
        case "4.17":
        default:
          gen_key_selector = 'span.anticon-file-protect';
          ok_button_selector = 'div.ant-modal-body button.ant-btn-primary';
          break;
      }

      cy.visit(Cypress.env('url') + '#/user/login');
  
      const username = Cypress.env('username');
      const password = Cypress.env('password');
      cy.get('input#username').clear().type(username);
      cy.get('input#password').clear().type(password).type('{enter}');
  
      cy.url().should('include', 'dashboard');
  
      //cy.get('h2').should('include.text', 'Hello and welcome to CloudStack™');
      cy.visit(Cypress.env('url') + '#/account');
      cy.get('tbody.ant-table-tbody tr:first-child a').first().click();
      cy.get('a').contains('View Users').click();
      cy.get('tbody.ant-table-tbody tr:first-child a').first().click();

      cy.get(gen_key_selector).parent().click();

      // For older, slower machines, we need to pause for a hot sec so we don't accidentally pick up outstanding requests for our spy
      cy.wait(2000);

      cy.intercept({
        method: 'GET',
        url: '/client/api/*',
      }).as(
        'apiSpy'
      );

      cy.get(ok_button_selector).click();

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