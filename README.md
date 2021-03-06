# [Many Decks][hosted]

[![Current Release Version](https://img.shields.io/github/v/tag/Lattyware/manydecks?label=release&sort=semver)](https://github.com/Lattyware/manydecks/releases)
[![Build Status](https://img.shields.io/github/workflow/status/Lattyware/manydecks/Build)](https://github.com/Lattyware/manydecks/actions)
[![License](https://img.shields.io/github/license/Lattyware/manydecks)](LICENSE)
[![Follow on Twitter for Status & Updates](https://img.shields.io/twitter/follow/Massive_Decks?label=Status%20%26%20Updates&style=social)](https://twitter.com/Massive_Decks)

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

If you wish to deploy your own version, the easiest way is to use the docker images: 
[the client image][client-image], and [the server image][server-image].

[client-image]: https://github.com/users/Lattyware/packages/container/package/manydecks%2Fclient
[server-image]: https://github.com/users/Lattyware/packages/container/package/manydecks%2Fserver

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
