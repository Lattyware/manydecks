import { Tag as LanguageTag } from "../../ts/languages";

type Token = string;

interface Auth {
  token: Token;
  name: string;
}

interface Flags {
  auth?: Auth;
  lang: string;
}

interface Span {
  start: number;
  end: number;
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
        focus: InboundPort<string>;
        setCallInputGhostSelection: InboundPort<Span>;
        getCallInputGhostSelection: OutboundPort<Span>;
        languageSearch: InboundPort<string>;
        languageResults: OutboundPort<LanguageTag[]>;
        languageExpand: InboundPort<string>;
        languageExpanded: OutboundPort<LanguageTag[]>;
      };
    }
    export function init(options: {
      node?: HTMLElement | null;
      flags: Flags;
    }): Elm.ManyDecks.App;
  }
}
