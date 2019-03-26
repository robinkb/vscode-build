VSCODE_PACKAGE = rpm
VSCODE_VERSION = 1.32.3

VSCODE_SRC_DIR = src/vscode-${VSCODE_VERSION}
VSCODE_SRC_URL = https://github.com/Microsoft/vscode/archive/${VSCODE_VERSION}.tar.gz

TARGET_DIR = target

.DEFAULT_GOAL = build
.ONESHELL:

.PHONY: patch-json container build

${VSCODE_SRC_DIR}:
	mkdir --parents ${VSCODE_SRC_DIR}
	curl --location ${VSCODE_SRC_URL} \
		| tar --extract --gzip --directory ${VSCODE_SRC_DIR} --strip-components=1

patch-json: ${VSCODE_SRC_DIR}
	jq --slurp ".[0] * .[1]" ${VSCODE_SRC_DIR}/product.json product.patch.json > product.json
	mv product.json ${VSCODE_SRC_DIR}/product.json

container: ${VSCODE_SRC_DIR}
	NODE_VERSION=$(shell cat ${VSCODE_SRC_DIR}/.nvmrc)
	podman build --rm \
		--file Dockerfile \
		--tag vscode-build:$$NODE_VERSION \
		--build-arg NODE_VERSION=$$NODE_VERSION

build: patch-json container
	NODE_VERSION=$(shell cat ${VSCODE_SRC_DIR}/.nvmrc)
	podman run --rm -ti \
		--ulimit=nofile=4096:4096 \
		--volume ${PWD}/${VSCODE_SRC_DIR}:/vscode:z \
		--volume ${PWD}/${TARGET_DIR}:/target:z \
		--workdir /vscode \
		vscode-build:$$NODE_VERSION \
		/bin/bash -c "
			yarn \
			&& yarn run gulp vscode-linux-x64-min \
			&& yarn run gulp vscode-linux-x64-build-${VSCODE_PACKAGE} \
			&& mv /vscode/.build/linux/${VSCODE_PACKAGE}/x86_64/vscode-${VSCODE_VERSION}-*.${VSCODE_PACKAGE} /target/
		"

clean:
	rm -rf src/* target/*
