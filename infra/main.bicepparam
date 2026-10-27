using 'main.bicep'

// Adopted from the live assignment; a fresh deploy would leave this empty.
param principalId = '5adb1a04-f2b5-4d62-8001-dc61dea8a238'
param cognitiveUserAssignmentName = '8137da55-683e-4498-35f3-98b07e82d23a'

// Personal details stay out of git; set these in the shell before deploying.
param budgetContactEmails = [readEnvironmentVariable('BUDGET_CONTACT_EMAIL')]
param claudeOrganizationName = readEnvironmentVariable('CLAUDE_ORGANIZATION_NAME')
