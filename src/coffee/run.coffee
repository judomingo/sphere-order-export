_ = require 'underscore'
Mapping = require '../lib/mapping'
SphereClient = require 'sphere-node-client'
package_json = require '../package.json'
fs = require 'fs'
argv = require('optimist')
  .usage('Usage: $0 --projectKey key --clientId id --clientSecret secret')
  .default('timeout', 60000)
  .default('fetchHours', 0) # by default don't restrict on modifications
  .describe('projectKey', 'your SPHERE.IO project-key')
  .describe('clientId', 'your OAuth client id for the SPHERE.IO API')
  .describe('clientSecret', 'your OAuth client secret for the SPHERE.IO API')
  .describe('timeout', 'Set timeout for requests')
  .describe('fetchHours', 'Number of hours to fetch modified orders')
  .demand(['projectKey', 'clientId', 'clientSecret'])
  .argv

options =
  config:
    project_key: argv.projectKey
    client_id: argv.clientId
    client_secret: argv.clientSecret
  timeout: argv.timeout
  user_agent: "#{package_json.name} - #{package_json.version}"

sphere = new SphereClient options
options.sphere_client = sphere
mapping = new Mapping options

sphere.orders.last("#{argv.fetchHours}h").perPage(0).fetch().then (result) ->
  mapping.processOrders(result.body.results)
  .then (xmlOrders) ->
    _.each xmlOrders, (entry) ->
      content = entry.xml.end(pretty: true, indent: '  ', newline: "\n")
      fileName = "#{entry.id}.xml"
      fs.writeFile fileName, content, (err) ->
        if err
          console.error err
          process.exit 2

.fail (res) ->
  console.error res
  process.exit 1
