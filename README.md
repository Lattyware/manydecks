# [Many Decks][hosted]

[![Current Release Version](https://img.shields.io/github/v/tag/Lattyware/manydecks?label=release&sort=semver)](https://github.com/Lattyware/manydecks/releases)
[![Client Docker Build](https://img.shields.io/docker/cloud/build/massivedecks/manydecks-client?label=client%20docker%20build)][docker-client]
[![Server Docker Build](https://img.shields.io/docker/cloud/build/massivedecks/manydecks-server?label=server%20docker%20build)][docker-server]
[![License](https://img.shields.io/github/license/Lattyware/manydecks)](LICENSE)

Many Decks is a free, open source deck source that can be used to host decks for [Massive Decks][md], a comedy party game based on 
Cards against Humanity.

Please note this is a very early version and there will be rough edges, please do report bugs!

**[Many Decks][hosted]**

[hosted]: https://decks.rereadgames.com
[md]: https://github.com/Lattyware/massivedecks

## About

Many Decks is open source software available under [the AGPLv3 license](LICENSE) and written in [Elm][elm] and 
[TypeScript][typescript].

[elm]: https://elm-lang.org/
[typescript]: https://www.typescriptlang.org/

## Use

To use, [the hosted version][hosted] is easiest.

If you wish to deploy your own version, the easiest way is to use the docker images, which can be found on Docker Hub:
[Client][docker-client]/[Server][docker-server].

[docker-client]: https://hub.docker.com/r/massivedecks/manydecks-client
[docker-server]: https://hub.docker.com/r/massivedecks/manydecks-server

## APIs

If you would like to use Many Decks' data for your application, we welcome that, but please do get in contact before 
directing any non-trivial (i.e: other than testing) load on us, as currently we don't expect anyone to depend on 
the service, so it may cause issues for our servers, and we may change the API under your feet—breaking your 
application.

## Contributing

If you have any problems with the editor, please [raise an issue][issue]. If you would like to help develop it, pull
requests are welcome.

[issue]: https://github.com/Lattyware/massivedecks/issues/new

## Credits

### Maintainers

Many Decks is maintained by [Reread Games][reread].

[reread]: https://www.rereadgames.com/
