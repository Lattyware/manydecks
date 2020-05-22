type Token = string;

interface Auth {
  token: Token;
  name: string;
}

interface Flags {
  auth?: Auth;
}

type GoogleAuthResult = { code: string } | { error: string };

export interface InboundPort<T> {
  subscribe(callback: (data: T) => void): void;
}

export interface OutboundPort<T> {
  send(data: T): void;
}

export namespace Elm {
  namespace ManyDecks {
    export interface App {
      ports: {
        tryGoogleAuth: InboundPort<string>;
        googleAuthResult: OutboundPort<GoogleAuthResult>;
        json5Decode: InboundPort<string>;
        json5Decoded: OutboundPort<object>;
        storeAuth: InboundPort<Auth | undefined>;
        copy: InboundPort<string>;
      };
    }
    export function init(options: {
      node?: HTMLElement | null;
      flags: Flags;
    }): Elm.ManyDecks.App;
  }
}
