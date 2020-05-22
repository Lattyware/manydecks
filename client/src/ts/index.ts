import "../../elm-material/src/ts/material";
import * as Json5 from "json5";
import { Elm } from "src/elm/ManyDecks";

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
    const textField = document.getElementById(id);
    if (textField !== null && textField instanceof HTMLInputElement) {
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
        element.oninput = updateSelection;
        element.onkeydown = updateSelection;
      }
    }
  });
};

main().catch(console.error);

window.init = () => {
  gapi.load("auth2", () => {});
};
if (window["gapi"] !== undefined) {
  window.init();
}
