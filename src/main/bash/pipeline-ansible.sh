#!/bin/bash

set -o errexit
set -o errtrace
set -o pipefail

# synopsis {{{
# Contains all Ansible related deployment functions
# }}}

__ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_INVENTORY_DIR="${ANSIBLE_INVENTORY_DIR:-ansible-inventory}"
ANSIBLE_PLAYBOOKS_DIR="${ANSIBLE_PLAYBOOKS_DIR:-${__ROOT}/ansible}"
ANSIBLE_CUSTOM_PLAYBOOKS_DIR="${ANSIBLE_CUSTOM_PLAYBOOKS_DIR:-${__ROOT}/ansible/custom}"
PIPELINE_DESCRIPTOR="$( pwd )/${PIPELINE_DESCRIPTOR}"
ENVIRONMENT="${ENVIRONMENT:?}"

ANSIBLE_INVENTORY_BIN="${ANSIBLE_INVENTORY_BIN:-ansible-inventory}"
ANSIBLE_PLAYBOOK_BIN="${ANSIBLE_PLAYBOOK_BIN:-ansible-playbook}"
JQ_BIN="${JQ_BIN:-jq}"

# FUNCTION: __ansible_inventory {{{
# Loads the Ansible inventory from the given [ANSIBLE_INVENTORY_DIR]. The convention is such
# that every environment has its own file with the name of the environment. E.g. for environment
# [test] the inventory file would be [${ANSIBLE_INVENTORY_DIR}/test].
function __ansible_inventory() {
	local environment

	environment="$( toLowerCase "${ENVIRONMENT}" )"
	if [[ ! -f "${ANSIBLE_INVENTORY_DIR}/${environment}" ]]; then
		echo "Could not find inventory!"
		exit 1
	fi
	"${ANSIBLE_INVENTORY_BIN}" -i "${ANSIBLE_INVENTORY_DIR}/${environment}" "$@"
} # }}}

# FUNCTION: __ansible_playbook {{{
# Given the presence of the Ansible inventory will first try to load a custom
# playbook from [${ANSIBLE_CUSTOM_PLAYBOOKS_DIR}/${playbook_name}]. E.g.
# for playbook with name [deploy-jvm-service.yml] will search by default for
# [${__ROOT}/ansible/custom/deploy-jvm-service.yml] to apply first. If there's
# no such file will continue applying the defaultplaybook  [${__ROOT}/ansible/deploy-jvm-service.yml]
function __ansible_playbook() {
	local playbook_name="$1"
	local environment
	local playbook_path
	shift
	environment="$( toLowerCase "${ENVIRONMENT}" )"
	if [[ ! -f "${ANSIBLE_INVENTORY_DIR}/${environment}" ]]; then
		echo "Could not find inventory!"
		exit 1
	fi
	playbook_path="${ANSIBLE_PLAYBOOKS_DIR}/${playbook_name}"
	if [[ -f "${ANSIBLE_CUSTOM_PLAYBOOKS_DIR}/${playbook_name}" ]]; then
		echo "Found custom playbook [${playbook_name}]"
		playbook_path="${ANSIBLE_CUSTOM_PLAYBOOKS_DIR}/${playbook_name}"
	else
		echo "No custom playbook found under [${ANSIBLE_CUSTOM_PLAYBOOKS_DIR}/${playbook_name}]"
	fi
	echo "Executing playbook [${playbook_path}]"
	ANSIBLE_HOST_KEY_CHECKING="False" \
	ANSIBLE_STDOUT_CALLBACK="debug" \
	"${ANSIBLE_PLAYBOOK_BIN}" -D -i "${ANSIBLE_INVENTORY_DIR}/${environment}" \
		"${playbook_path}" "$@"
} # }}}

# FUNCTION: logInToPaas {{{
# Since there's no concept of explicit logging in in Ansible, this method does nothing
function logInToPaas() {
	:
} # }}}

# FUNCTION: testDeploy {{{
# Implementation of the Ansible deployment to test
function testDeploy() {
	local appName

	appName="$( retrieveAppName )"

	__ansible_playbook bootstrap-environment.yml \
		-e "force_clean=true"

	__ansible_playbook deploy-stubrunner.yml \
		-e "app_name=${appName}" \
		-e "stubrunner_ids=$( retrieveStubRunnerIds )"

	__ansible_playbook "deploy-${LANGUAGE_TYPE}-service.yml" \
		-e "app_name=${appName}" \
		-e "app_group_id=$( retrieveGroupId )" \
		-e "app_version=${PIPELINE_VERSION}"
} # }}}

# FUNCTION: testRollbackDeploy {{{
# Implementation of the Ansible deployment to test for rollback tests
function testRollbackDeploy() {
	local latestProdTag="${1}"
	local latestProdVersion
	local appName
	appName=$(retrieveAppName)

	latestProdVersion="${latestProdTag#prod/${appName}/}"

	rm -rf -- "${OUTPUT_FOLDER}/test.properties"
	mkdir -p "${OUTPUT_FOLDER}"

	echo "Last prod version equals ${latestProdVersion}"

	__ansible_playbook "deploy-${LANGUAGE_TYPE}-service.yml" \
		-e "app_name=${appName}" \
		-e "app_group_id=$( retrieveGroupId )" \
		-e "app_version=${latestProdVersion}"

	# get the application and stubrunner URLs
	prepareForSmokeTests

	cat <<-EOF > "${OUTPUT_FOLDER}/test.properties"
	APPLICATION_URL=${APPLICATION_URL}
	STUBRUNNER_URL=${STUBRUNNER_URL}
	LATEST_PROD_TAG=${latestProdTag}
	EOF
} # }}}

# FUNCTION: prepareForSmokeTests {{{
# Ansible implementation of prepare for smoke tests
function prepareForSmokeTests() {
	local applicationHost
	local applicationPort
	local stubrunnerHost
	local stubrunnerPort
	local appName

	appName="$( retrieveAppName )"

	# we assume that we have only one test instance
	applicationHost="$( __ansible_inventory --list | "${JQ_BIN}" -r '.app_server.hosts[0]' )"
	applicationPort="$( __ansible_inventory --host "${applicationHost}" | "${JQ_BIN}" -r ".\"${appName}_port\"" )"

	# and we assume that stubrunner should run on the same host
	stubrunnerHost="${applicationHost}"
	stubrunnerPort="$( __ansible_inventory --host "${stubrunnerHost}" | "${JQ_BIN}" -r ".\"${appName}_stubrunner_port\"" )"

	export APPLICATION_URL="${applicationHost}:${applicationPort}"
	export STUBRUNNER_URL="${stubrunnerHost}:${stubrunnerPort}"
} # }}}

# FUNCTION: stageDeploy {{{
# Implementation of the Ansible deployment to stage
function stageDeploy() {
	__ansible_playbook bootstrap-environment.yml

	__ansible_playbook "deploy-${LANGUAGE_TYPE}-service.yml" \
		-e "app_name=$( retrieveAppName )" \
		-e "app_group_id=$( retrieveGroupId )" \
		-e "app_version=${PIPELINE_VERSION}"
} # }}}

# FUNCTION: prepareForE2eTests {{{
# Ansible implementation of prepare for e2e tests
function prepareForE2eTests() {
	local applicationHost
	local applicationPort
	local appName

	appName="$( retrieveAppName )"

	# we assume that we have only one test instance
	applicationHost="$( __ansible_inventory --list | "${JQ_BIN}" -r '.app_server.hosts[0]' )"
	applicationPort="$( __ansible_inventory --host "${applicationHost}" | "${JQ_BIN}" -r ".\"${appName}_port\"" )"

	export APPLICATION_URL="${applicationHost}:${applicationPort}"
} # }}}

# FUNCTION: prodDeploy {{{
# Implementation of the Ansible deployment to prod
function prodDeploy() {
	__ansible_playbook bootstrap-environment.yml

	__ansible_playbook "deploy-${LANGUAGE_TYPE}-service.yml" \
		-e "app_name=$( retrieveAppName )" \
		-e "app_group_id=$( retrieveGroupId )" \
		-e "app_version=${PIPELINE_VERSION}" \
		-e "target=blue"
} # }}}

# FUNCTION: completeSwitchOver {{{
# Implementation of the Ansible switch over on production
function completeSwitchOver() {
	__ansible_playbook "deploy-${LANGUAGE_TYPE}-service.yml" \
		-e "app_name=$( retrieveAppName )" \
		-e "app_group_id=$( retrieveGroupId )" \
		-e "app_version=${PIPELINE_VERSION}" \
		-e "target=green"
} # }}}

# FUNCTION: rollbackToPreviousVersion {{{
# Implementation of the Ansible rolling back on production to previous version
function rollbackToPreviousVersion() {
	local appName
	appName=$(retrieveAppName)
	# Find latest prod version
	latestProdTag="$(findLatestProdTag)"
	if [[ "${latestProdTag}" != "" ]]; then
		latestProdVersion="${latestProdTag#prod/${appName}/}"
		echo "Last prod version equals ${latestProdVersion}"
		__ansible_playbook "deploy-${LANGUAGE_TYPE}-service.yml" \
			-e "app_name=$( retrieveAppName )" \
			-e "app_group_id=$( retrieveGroupId )" \
			-e "app_version=${latestProdVersion}"
		return 0
	else
		echo "No latest prod tag found"
		return 1
	fi
} # }}}
