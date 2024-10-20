# BUILD STAGE
FROM debian:bullseye as build-stage

ENV BUILD_DIR /tmp/build
ENV NVM_DIR /root/.nvm
ENV NODE_VERSION v18.20.4
ENV NODE_ENV production
ENV NODE_PATH $NVM_DIR/$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

RUN apt-get update -y && apt-get install -y -q --no-install-recommends \
  apt-utils \
  build-essential \
  ca-certificates \
  python3 \
  python3-pip \
  curl \
  git \
  udev

RUN git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR" \
  && cd "$NVM_DIR" \
  && git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` \
  && . "$NVM_DIR/nvm.sh" \
  && nvm install "$NODE_VERSION" \
  && nvm alias default "$NODE_VERSION" \
  && nvm use --delete-prefix default

COPY ./dist/cncjs $BUILD_DIR/cncjs
COPY ./entrypoint $BUILD_DIR/cncjs/

WORKDIR $BUILD_DIR/cncjs
RUN npm install -g yarn && yarn --production

# FINAL STAGE
FROM debian:bullseye

ENV NVM_DIR /root/.nvm
ENV NODE_VERSION v18.20.4
ENV NODE_ENV production
ENV NODE_PATH $NVM_DIR/$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/$NODE_VERSION/bin:$PATH

RUN apt-get update -y && apt-get install -y -q --no-install-recommends \
  apt-utils \
  ca-certificates \
  udev

WORKDIR /opt/cncjs
EXPOSE 8000
ENTRYPOINT ["/opt/cncjs/entrypoint"]

COPY --from=build-stage /root/.nvm $NVM_DIR
COPY --from=build-stage /tmp/build/cncjs /opt/cncjs
