/// <reference types="cypress" />
/* eslint-env node */

const { spawn } = require('child_process');
const fetch = require('node-fetch');

// ***********************************************************
// This example plugins/index.js can be used to load plugins
//
// You can change the location of this file or turn off loading
// the plugins file with the 'pluginsFile' configuration option.
//
// You can read more here:
// https://on.cypress.io/plugins-guide
// ***********************************************************

// This function is called when a project is opened or re-opened (e.g. due to
// the project's config changing)

/**
 * @type {Cypress.PluginConfig}
 */
module.exports = (on, config) => {
  // `on` is used to hook into various events Cypress emits
  // `config` is the resolved Cypress config
  config.env = {
    ...config.env,
    ...process.env,
  };

  on('task', {
    async resetData() {
      const clearSearchIndices = fetch(`${config.env.ELASTICSEARCH_URL}/*`, {
        method: 'DELETE',
      });

      const truncateDB = new Promise((resolve, reject) => {
        // Clear the DB for the next test run.
        const child = spawn('bundle', ['exec', 'rails db:truncate_all']);

        child.on('error', (error) => {
          reject(error);
        });

        child.on('exit', (status, code) => {
          if (status !== 0) {
            reject(
              new Error(
                `bundle exec rails db:truncate_all exited with status ${status} and code ${code}.`,
              ),
            );
          }

          resolve(status === 0);
        });
      });

      const [clearSearchIndicesResponse, clearedDB] = await Promise.all([
        clearSearchIndices,
        truncateDB.catch((error) => {
          throw new Error(error);
        }),
      ]);
      const {
        acknowledged = false,
        error,
      } = await clearSearchIndicesResponse.json();

      if (!acknowledged || error) {
        throw new Error(
          `There was an error clearing indices in Elastic Search:\n${
            error ? JSON.stringify(error, null, '\t') : ''
          }`,
        );
      }

      if (!clearedDB) {
        throw new Error(`The database did not truncate successfully`);
      }

      // Nothing to do, we're all good.
      // Cypress tasks require a return value, so returning null.
      return null;
    },
  });

  return config;
};
