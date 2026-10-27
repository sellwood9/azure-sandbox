param location string
param tags object
param level string
param principalId string
param cognitiveUserAssignmentName string
param deployHaiku bool
param haikuCapacity int
param claudeOrganizationName string
param claudeCountryCode string
param claudeIndustry string

// Literal because the live suffix is sha1(subscription ID), which Bicep can't
// compute; uniqueString() would rename (and so replace) the account.
var accountName = 'aif-sandbox-2bf861a4'

var haikuModel = 'claude-haiku-5-5'

// Least-privilege role for Claude inference via Entra ID.
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'

resource foundry 'Microsoft.CognitiveServices/accounts@2025-10-01-preview' = {
  name: accountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: 'S0'
  }

  // Project management requires an identity.
  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    // Entra tokens are only issued for a custom subdomain endpoint.
    customSubDomainName: accountName

    // Entra ID only: API keys are rejected by the data plane.
    disableLocalAuth: true

    // Can't be turned off without replacing the account.
    allowProjectManagement: true

    publicNetworkAccess: 'Enabled'
    restrictOutboundNetworkAccess: false
    dynamicThrottlingEnabled: false
  }
}

// Role assignments can't take tags; carry them in the description instead.
resource meCognitiveServicesUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: empty(cognitiveUserAssignmentName) ? guid(foundry.id, principalId, cognitiveServicesUserRoleId) : cognitiveUserAssignmentName
  scope: foundry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalId: principalId
    principalType: 'User'
    description: 'owner=steve level=${level}: Claude inference via Entra ID'
  }
}

// Pattern from https://github.com/Azure-Samples/claude/tree/main/infra-bicep
resource claudeHaiku 'Microsoft.CognitiveServices/accounts/deployments@2025-10-01-preview' = if (deployHaiku) {
  parent: foundry
  name: haikuModel
  tags: tags
  sku: {
    name: 'GlobalStandard'
    capacity: haikuCapacity
  }
  properties: {
    model: {
      format: 'Anthropic'
      name: haikuModel
      version: '2'
    }
    // Accepted by the API but missing from the published type schema
    // (same gap as hashicorp/terraform-provider-azurerm#31140).
    #disable-next-line BCP037
    modelProviderData: {
      organizationName: claudeOrganizationName
      countryCode: claudeCountryCode
      industry: claudeIndustry
    }
    // Only upgrade when v2 is retired, so the pinned version doesn't drift.
    versionUpgradeOption: 'OnceCurrentVersionExpired'
    raiPolicyName: 'Microsoft.DefaultV2'
  }

  // The role PUT returns in seconds but data-plane RBAC takes minutes to
  // propagate; the deployment LRO covers that wait.
  dependsOn: [
    meCognitiveServicesUser
  ]
}

output foundryAccountName string = foundry.name
output claudeBaseUrl string = 'https://${foundry.properties.customSubDomainName}.services.ai.azure.com/anthropic'
output haikuDeploymentName string = deployHaiku ? claudeHaiku.name : ''
