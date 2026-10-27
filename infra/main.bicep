targetScope = 'subscription'

@description('Azure region for basecamp resources.')
param location string = 'eastus2'

@description('Value for the expires tag (yyyy-mm-dd). Basecamp is long-lived.')
param expires string = '2027-10-21'

@description('Monthly subscription budget in the billing currency.')
param budgetAmount int = 100

@description('Addresses that receive budget alerts.')
@minLength(1)
param budgetContactEmails array

@description('Object ID of the user granted Claude inference on the Foundry account.')
param principalId string

@description('Name (GUID) of the Cognitive Services User assignment. Set to the existing name when adopting a live assignment.')
param cognitiveUserAssignmentName string = ''

@description('Create the Claude Haiku deployment. Off by default; deploying accepts Anthropic\'s terms (see modelProviderData).')
param deployHaiku bool = false

@description('Haiku deployment capacity in thousands of tokens per minute. A rate limit, not a charge.')
param haikuCapacity int = 10

// modelProviderData: required by Foundry for Claude deployments. Creating the
// deployment accepts Anthropic's commercial terms for this organization.
@description('Organization name sent to Anthropic via modelProviderData.')
param claudeOrganizationName string

@description('Two-letter ISO country code (e.g. US, GB, DE).')
@minLength(2)
@maxLength(2)
param claudeCountryCode string = 'US'

@description('Industry. Must be lowercase to match the Foundry portal dropdown.')
@allowed([
  'technology'
  'finance'
  'healthcare'
  'education'
  'retail'
  'manufacturing'
  'government'
  'media'
  'other'
])
param claudeIndustry string = 'technology'

var level = 'basecamp'

var tags = {
  owner: 'steve'
  env: 'sandbox'
  level: level
  expires: expires
}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: 'rg-sandbox-basecamp'
  location: location
  tags: tags
}

// Keys match the names the Consumption API generated for the live budget;
// different keys would show up in what-if as delete + create.
var budgetNotification = {
  enabled: true
  operator: 'GreaterThanOrEqualTo'
  contactEmails: budgetContactEmails
  contactGroups: []
  contactRoles: []
}

// Budgets can't take tags or carry a description; listed as a tag exception.
resource budget 'Microsoft.Consumption/budgets@2024-08-01' = {
  name: 'budget-sandbox-monthly'
  properties: {
    amount: budgetAmount
    category: 'Cost'
    timeGrain: 'Monthly'
    timePeriod: {
      // Must be the first of a month; hardcoded so what-if stays stable.
      startDate: '2026-10-01T00:00:00Z'
      // Explicit, or the API's 10-year default shows as drift.
      endDate: '2036-10-01T00:00:00Z'
    }
    notifications: {
      'actual_GreaterThanOrEqualTo_50.000000_Percent': union(budgetNotification, { threshold: 50, thresholdType: 'Actual' })
      'actual_GreaterThanOrEqualTo_80.000000_Percent': union(budgetNotification, { threshold: 80, thresholdType: 'Actual' })
      'actual_GreaterThanOrEqualTo_100.000000_Percent': union(budgetNotification, { threshold: 100, thresholdType: 'Actual' })
      'forecasted_GreaterThanOrEqualTo_100.000000_Percent': union(budgetNotification, { threshold: 100, thresholdType: 'Forecasted' })
    }
  }
}

module basecamp 'modules/basecamp.bicep' = {
  name: 'basecamp'
  scope: rg
  params: {
    location: location
    tags: tags
    level: level
    principalId: principalId
    cognitiveUserAssignmentName: cognitiveUserAssignmentName
    deployHaiku: deployHaiku
    haikuCapacity: haikuCapacity
    claudeOrganizationName: claudeOrganizationName
    claudeCountryCode: claudeCountryCode
    claudeIndustry: claudeIndustry
  }
}

output foundryAccountName string = basecamp.outputs.foundryAccountName

@description('Claude SDK base URL. The SDK appends /v1/messages.')
output claudeBaseUrl string = basecamp.outputs.claudeBaseUrl

@description('Pass as the model name in Claude API calls. Empty when deployHaiku = false.')
output haikuDeploymentName string = basecamp.outputs.haikuDeploymentName
