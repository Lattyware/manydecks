import "../../elm-material/src/ts/material";
import * as Json5 from "json5";
import { Elm } from "src/elm/ManyDecks";
import * as Languages from "./languages";

declare global {
  interface Window {
    init: () => void;
  }
}

const main = async () => {
  const { Elm } = await import(
    /* webpackChunkName: "many-decks" */ "../elm/ManyDecks"
  );

  const savedAuth = localStorage.getItem("auth");

  const app: Elm.ManyDecks.App = Elm.ManyDecks.init({
    flags: {
      auth: savedAuth === null ? null : JSON.parse(savedAuth),
      lang: navigator.language,
    },
  });

  app.ports.tryGoogleAuth.subscribe((clientId) => {
    if (gapi.auth2 !== undefined) {
      gapi.auth2.authorize(
        {
          client_id: clientId,
          scope: "profile openid",
          response_type: "id_token",
        },
        (response) => {
          app.ports.googleAuthResult.send(
            response.error !== undefined
              ? { error: response.error }
              : { code: response.id_token }
          );
        }
      );
    } else {
      app.ports.googleAuthResult.send({
        error: "Could not connect to Google.",
      });
    }
  });

  app.ports.json5Decode.subscribe((raw) => {
    app.ports.json5Decoded.send(Json5.parse(raw));
  });

  app.ports.storeAuth.subscribe((auth) => {
    if (auth !== undefined) {
      localStorage.setItem("auth", JSON.stringify(auth));
    } else {
      localStorage.removeItem("auth");
    }
  });

  app.ports.copy.subscribe((id) => {
    const element = document.getElementById(id);
    if (element !== null) {
      const textField = element as HTMLInputElement;
      textField.focus();
      textField.select();
      const value = textField.value;
      textField.setSelectionRange(0, value.length);
      try {
        navigator.clipboard.writeText(value).catch(console.error);
      } catch (err) {
        document.execCommand("copy");
      }
    }
  });

  app.ports.focus.subscribe((id) => {
    window.requestAnimationFrame(() => {
      const element = document.getElementById(id);
      if (element !== null) {
        const textarea = element as HTMLTextAreaElement;
        textarea.focus();
        // @ts-ignore
        const last = element.textLength;
        textarea.setSelectionRange(last, last);
      }
    });
  });

  app.ports.setCallInputGhostSelection.subscribe(({ start, end }) => {
    const element = document.getElementById("call-input-ghost");
    if (element !== null) {
      const textarea = element as HTMLTextAreaElement;
      textarea.focus();
      textarea.setSelectionRange(start, end);
      if (!element.oninput) {
        const updateSelection = () => {
          app.ports.getCallInputGhostSelection.send({
            start: textarea.selectionStart,
            end: textarea.selectionEnd,
          });
        };
        textarea.oninput = updateSelection;
        textarea.onkeydown = updateSelection;
      }
    }
  });

  Languages.registerPorts(
    app.ports.languageSearch,
    app.ports.languageResults,
    app.ports.languageExpand,
    app.ports.languageExpanded
  );
};

main().catch(console.error);

window.init = () => {
  gapi.load("auth2", () => {});
};
if (window["gapi"] !== undefined) {
  window.init();
}
