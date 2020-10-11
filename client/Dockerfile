FROM node:14-alpine

RUN ["apk", "add", "--no-cache", "--virtual", ".gyp", "python", "make", "g++"]

ARG VERSION=dev
ENV MD_VERSION $VERSION

WORKDIR /md

COPY ["./package.json", "./package-lock.json", "./"]
COPY ["./elm-material/package.json", "./elm-material/package-lock.json", "./elm-material/"]

RUN ["npm", "ci"]

COPY ["./tsconfig.json", "./webpack.config.js", "./postcss.config.js", "./elm.json", "./"]
COPY ["./src", "./src"]
COPY ["./elm-material/src", "./elm-material/src"]
COPY ["./assets", "./assets"]
RUN ["npm", "run", "build"]

FROM nginx:mainline-alpine

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=dev

EXPOSE 8080

LABEL org.label-schema.name="massivedecks/manydecks-client"
LABEL org.label-schema.description="The web client for Many Decks, a deck source for Massive Decks."
LABEL org.label-schema.url="https://github.com/Lattyware/manydecks"
LABEL org.label-schema.vcs-url="https://github.com/Lattyware/manydecks"
LABEL org.label-schema.vendor="Reread Games"
LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.build-date=$BUILD_DATE
LABEL org.label-schema.vcs-ref=$VCS_REF
LABEL org.label-schema.version=$VERSION

COPY --from=0 ["/md/dist", "/usr/share/nginx/html/"]
COPY ["./nginx.conf", "/etc/nginx/nginx.conf"]
