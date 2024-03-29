# More robust scripts
export SHELL = /bin/bash
export SHELLOPTS := errexit:pipefail:nounset
# Use one shell instance to execute all steps in a target.
.ONESHELL:

VSCODE_PACKAGE = rpm
VSCODE_VERSION = 1.64.1
NODE_VERSION = 16

VSCODE_SRC_DIR = src/vscode-${VSCODE_VERSION}
VSCODE_SRC_URL = https://github.com/Microsoft/vscode

TARGET_DIR = target

.DEFAULT_GOAL = build

.PHONY: patch-json container build

${VSCODE_SRC_DIR}:
	mkdir --parents ${VSCODE_SRC_DIR}
	git clone ${VSCODE_SRC_URL} ${VSCODE_SRC_DIR} --branch ${VSCODE_VERSION} --depth 1

patch-json: ${VSCODE_SRC_DIR}
	jq --slurp ".[0] * .[1]" ${VSCODE_SRC_DIR}/product.json product.patch.json > product.json
	mv product.json ${VSCODE_SRC_DIR}/product.json

container: ${VSCODE_SRC_DIR}
	podman build --rm \
		--file Dockerfile \
		--tag vscode-build:${NODE_VERSION} \
		--build-arg NODE_VERSION=${NODE_VERSION}

build: patch-json container ${TARGET_DIR}
	podman run --rm -ti \
		--ulimit=nofile=8192:8192 \
		--volume ${PWD}/${VSCODE_SRC_DIR}:/vscode:z \
		--volume ${PWD}/${TARGET_DIR}:/${TARGET_DIR}:z \
		--env npm_config_scripts_prepend_node_path=true \
		--workdir /vscode \
		vscode-build:${NODE_VERSION} \
		/bin/bash -c "
			yarn \
			&& yarn run gulp vscode-linux-x64-min \
			&& yarn run gulp vscode-linux-x64-build-${VSCODE_PACKAGE} \
			&& mv /vscode/.build/linux/${VSCODE_PACKAGE}/x86_64/vscode*.${VSCODE_PACKAGE} /${TARGET_DIR}/
		"

clean:
	rm -rf ./src/* ./${TARGET_DIR}/

${TARGET_DIR}:
	mkdir -p ${TARGET_DIR}
