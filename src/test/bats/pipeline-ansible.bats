#!/usr/bin/env bats

load 'test_helper'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup() {
	export TEMP_DIR="$( mktemp -d )"

	export MAVENW_BIN="mockMvnw"

	export ENVIRONMENT="TEST"
	export LANGUAGE_TYPE="dummy"
	export PAAS_TYPE="ANSIBLE"
	export REPO_WITH_BINARIES="http://foo"

	cp -a "${FIXTURES_DIR}/gradle" "${FIXTURES_DIR}/maven" "${FIXTURES_DIR}/generic" "${TEMP_DIR}"
	ln -s "${FIXTURES_DIR}/pipeline-dummy.sh" "${SOURCE_DIR}"
	ln -s "${FIXTURES_DIR}/pipeline-dummy.sh" "${SOURCE_DIR}/projectType/"
}

teardown() {
	rm -f "${SOURCE_DIR}/projectType/pipeline-dummy.sh"
	rm -f "${SOURCE_DIR}/pipeline-dummy.sh"
	rm -rf "${TEMP_DIR}"
}

function curl_stub {
	echo "curl $*"
}

function tar_stub {
	echo "tar $*"
}

export -f curl_stub
export -f tar_stub

teardown() {
	rm -f "${SOURCE_DIR}/pipeline-dummy.sh"
	rm -f "${SOURCE_DIR}/projectType/pipeline-dummy.sh"
	rm -rf "${TEMP_DIR}"
}

@test "should throw an exception when inventory is not found while trying to load it [ansible]" {
	cd "${TEMP_DIR}/gradle"
	source "${SOURCE_DIR}/pipeline.sh"

	run __ansible_inventory

	assert_failure
	assert_output --partial "Could not find inventory!"
}

@test "should throw an exception when inventory is not found while trying to use a playbook [ansible]" {
	cd "${TEMP_DIR}/gradle"
	source "${SOURCE_DIR}/pipeline.sh"

	run __ansible_playbook "foo"

	assert_failure
	assert_output --partial "Could not find inventory!"
}
