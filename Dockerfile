# Visual Studio Code build image. Based on Microsoft's instructions:
# https://github.com/Microsoft/vscode/wiki/How-to-Contribute#build-and-run
ARG NODE_VERSION

FROM docker.io/library/node:${NODE_VERSION}
ENV NODE_OPTIONS --max-old-space-size=4096

RUN apt update \
&&  apt install -y \
        jq \
        yarn \
        python \
        make \
        pkg-config \
        g++ \
        libx11-dev \
        libxkbfile-dev \
        libsecret-1-dev \
        fakeroot \
        rpm \
&&  rm -rf /var/lib/apt/lists/*
