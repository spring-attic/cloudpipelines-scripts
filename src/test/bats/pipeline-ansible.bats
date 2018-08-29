#!/usr/bin/env bats

load 'test_helper'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
	export TEMP_DIR="$( mktemp -d )"

	export ANSIBLE_INVENTORY_BIN="ansible_inventory_stub"
	export ANSIBLE_PLAYBOOK_BIN="ansible_playbook_stub"
	export JQ_BIN="jq_stub"

	export ENVIRONMENT="TEST"
	export LANGUAGE_TYPE="dummy"
	export PAAS_TYPE="ANSIBLE"
	export REPO_WITH_BINARIES="http://foo"
	export ANSIBLE_INVENTORY_DIR="${FIXTURES_DIR}/ansible/ansible-inventory"
	export SCRIPTS_DIR="${TEMP_DIR}"/scripts

	cp -a "${FIXTURES_DIR}/gradle" "${FIXTURES_DIR}/maven" "${FIXTURES_DIR}/generic" "${FIXTURES_DIR}/ansible" "${TEMP_DIR}"
	cp -a "${SOURCE_DIR}" "${SCRIPTS_DIR}"
	cp -a "${FIXTURES_DIR}/ansible/custom" "${SCRIPTS_DIR}/ansible/custom"
	cp "${FIXTURES_DIR}/pipeline-dummy.sh" "${SCRIPTS_DIR}"
	cp "${FIXTURES_DIR}/pipeline-dummy.sh" "${SCRIPTS_DIR}/projectType/"
}

teardown() {
	rm -f "${SOURCE_DIR}/projectType/pipeline-dummy.sh"
	rm -f "${SOURCE_DIR}/pipeline-dummy.sh"
	rm -rf "${TEMP_DIR}"
}

function ansible_inventory_stub {
	echo "ansible_inventory $*"
}

function ansible_playbook_stub {
	echo "ansible_playbook $*"
}

function jq_stub {
	echo "jq $*"
}

export -f ansible_inventory_stub
export -f ansible_playbook_stub
export -f jq_stub

teardown() {
	rm -f "${SOURCE_DIR}/pipeline-dummy.sh"
	rm -f "${SOURCE_DIR}/projectType/pipeline-dummy.sh"
	rm -rf "${TEMP_DIR}"
}

@test "should throw an exception when inventory is not found while trying to load it [ansible]" {
	export ANSIBLE_INVENTORY_DIR="${FIXTURES_DIR}/fake/"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run __ansible_inventory

	assert_failure
	assert_output --partial "Could not find inventory!"
}

@test "should throw an exception when inventory is not found while trying to use a playbook [ansible]" {
	export ANSIBLE_INVENTORY_DIR="${FIXTURES_DIR}/fake/"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run __ansible_playbook "foo"

	assert_failure
	assert_output --partial "Could not find inventory!"
}

@test "should load ansible inventory [ansible]" {
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run __ansible_inventory

	assert_success
	refute_output --partial "Could not find inventory!"
	assert_output --partial "ansible_inventory -i ${FIXTURES_DIR}/ansible/ansible-inventory/test"
}

@test "should load a custom ansible playbook [ansible]" {
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run __ansible_playbook "deploy-jvm-service.yml"

	assert_success
	refute_output --partial "Could not find inventory!"
	assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/test ${SCRIPTS_DIR}/ansible/custom/deploy-jvm-service.yml"
}

@test "should load a default ansible playbook [ansible]" {
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run __ansible_playbook "foo.yml"

	assert_success
	refute_output --partial "Could not find inventory!"
	assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/test ${SCRIPTS_DIR}/ansible/foo.yml"
}

@test "should do nothing on login to PAAS [ansible]" {
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run logInToPaas

	assert_success
}

@test "should deploy to test [ansible]" {
	export PROJECT_NAME="foo"
	export PIPELINE_VERSION="1.0.0"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run testDeploy

	assert_success
	assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/test ${SCRIPTS_DIR}/ansible/bootstrap-environment.yml -e force_clean=true"
    assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/test ${SCRIPTS_DIR}/ansible/deploy-stubrunner.yml -e app_name=foo -e stubrunner_ids=com.example:foo:1.0.0.RELEASE:stubs:1234"
    assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/test ${SCRIPTS_DIR}/ansible/deploy-dummy-service.yml -e app_name=foo -e app_group_id=com.example -e app_version=1.0.0"
}

@test "should deploy for rollback tests [ansible]" {
	export PROJECT_NAME="foo"
	export APPLICATION_URL="http://foo/bar"
	export STUBRUNNER_URL="http://bar/baz"
	export PIPELINE_VERSION="1.0.0"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run testRollbackDeploy "prod/foo/0.0.1"

	assert_success
    assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/test ${SCRIPTS_DIR}/ansible/deploy-dummy-service.yml -e app_name=foo -e app_group_id=com.example -e app_version=0.0.1"
    assert [ -f "${TEMP_DIR}/gradle/target/test.properties" ]
}

@test "should deploy to stage [ansible]" {
	export ENVIRONMENT="stage"
	export PROJECT_NAME="foo"
	export PIPELINE_VERSION="1.0.0"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run stageDeploy

	assert_success
	assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/stage ${SCRIPTS_DIR}/ansible/bootstrap-environment.yml"
    assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/stage ${SCRIPTS_DIR}/ansible/deploy-dummy-service.yml -e app_name=foo -e app_group_id=com.example -e app_version=1.0.0"
}

@test "should prepare for e2e [ansible]" {
	export ENVIRONMENT="stage"
	export PROJECT_NAME="foo"
	export PIPELINE_VERSION="1.0.0"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run prepareForE2eTests

	assert_success
}

@test "should deploy to prod [ansible]" {
	export ENVIRONMENT="prod"
	export PROJECT_NAME="foo"
	export PIPELINE_VERSION="1.0.0"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run prodDeploy

	assert_success
	assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/prod ${SCRIPTS_DIR}/ansible/bootstrap-environment.yml"
    assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/prod ${SCRIPTS_DIR}/ansible/deploy-dummy-service.yml -e app_name=foo -e app_group_id=com.example -e app_version=1.0.0 -e target=blue"
}

@test "should complete switch over on prod [ansible]" {
	export ENVIRONMENT="prod"
	export PROJECT_NAME="foo"
	export PIPELINE_VERSION="1.0.0"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run completeSwitchOver

	assert_success
    assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/prod ${SCRIPTS_DIR}/ansible/deploy-dummy-service.yml -e app_name=foo -e app_group_id=com.example -e app_version=1.0.0 -e target=green"
}

@test "should rollback on prod [ansible]" {
	export ENVIRONMENT="prod"
	export PROJECT_NAME="foo"
	export LATEST_PROD_TAG="1.0.0"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run rollbackToPreviousVersion

	assert_success
	refute_output --partial "green"
	refute_output --partial "blue"
    assert_output --partial "ansible_playbook -D -i ${FIXTURES_DIR}/ansible/ansible-inventory/prod ${SCRIPTS_DIR}/ansible/deploy-dummy-service.yml -e app_name=foo -e app_group_id=com.example -e app_version=1.0.0"
}

@test "should not rollback on prod when there is no prod tag [ansible]" {
	export ENVIRONMENT="prod"
	export PROJECT_NAME="foo"
	cd "${TEMP_DIR}/gradle"
	source "${SCRIPTS_DIR}/pipeline.sh"

	run rollbackToPreviousVersion

	assert_failure
	refute_output --partial "green"
	refute_output --partial "blue"
    refute_output --partial "ansible_playbook"
}
