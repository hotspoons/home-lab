const { defineConfig } = require("cypress");

module.exports = defineConfig({
  e2e: {
    "chromeWebSecurity": false,
    defaultCommandTimeout: 300000,
    requestTimeout: 300000,
    setupNodeEvents(on, config) {
      // implement node event listeners here
    
    },
  },
});
