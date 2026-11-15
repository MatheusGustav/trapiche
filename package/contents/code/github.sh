#!/bin/sh
# Dados do GitHub pelo login do gh. Três linhas: JSON do perfil, notificações não lidas, PRs abertos do usuário.
gh api graphql -f query='query { viewer { login contributionsCollection { contributionCalendar { weeks { contributionDays { contributionCount date } } } } repositories(ownerAffiliations: OWNER, first: 100) { nodes { stargazerCount } } } }' \
    -q '{login: .data.viewer.login, estrelas: ([.data.viewer.repositories.nodes[].stargazerCount] | add // 0), dias: [.data.viewer.contributionsCollection.contributionCalendar.weeks[].contributionDays[].contributionCount]}' || exit 1
gh api notifications -q 'length' || exit 1
gh api 'search/issues?q=is:pr+is:open+author:@me' -q .total_count || exit 1
