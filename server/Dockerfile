FROM node:15-alpine

WORKDIR /md

COPY ["./package.json", "./package-lock.json", "./"]
RUN ["npm", "ci"]

COPY ["./src", "./src"]
COPY ["./types", "./types"]
COPY ["./tsconfig.json", "./"]
RUN ["npm", "run", "build"]

FROM node:15.0-alpine
LABEL maintainer="team@rereadgames.com"

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=dev

ENV MD_VERSION $VERSION

LABEL org.label-schema.name="massivedecks/manydecks-server"
LABEL org.label-schema.description="The web server for Many Decks, a deck source for Massive Decks."
LABEL org.label-schema.url="https://github.com/Lattyware/manydecks"
LABEL org.label-schema.vcs-url="https://github.com/Lattyware/manydecks"
LABEL org.label-schema.vendor="Reread Games"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.version=$VERSION

WORKDIR /md

COPY ["./package.json", "./package-lock.json", "./"]
RUN ["npm", "ci", "--only=production"]

COPY ["./src/sql", "./src/sql"]
COPY ["./config.json5", "./"]
COPY --from=0 ["/md/dist", "./"]

EXPOSE 8081
USER node
CMD ["node", "--es-module-specifier-resolution=node", "./index.js"]
