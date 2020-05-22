import { default as t } from "io-ts";
import { default as PathReporter } from "io-ts/lib/PathReporter";
import { default as Either } from "fp-ts/lib/Either";

const Style = t.keyof({
  Em: null,
  Strong: null,
});
export type Style = t.TypeOf<typeof Style>;

const Transform = t.keyof({
  UpperCase: null,
  Capitalize: null,
});
export type Transform = t.TypeOf<typeof Transform>;

const Slot = t.partial({
  transform: Transform,
  style: Style,
});
export type Slot = t.TypeOf<typeof Slot>;

const Styled = t.intersection([
  t.strict({
    text: t.string,
  }),
  t.partial({ style: Style }),
]);
export type Styled = t.TypeOf<typeof Styled>;

const Part = t.union([t.string, Styled, Slot]);
export type Part = t.TypeOf<typeof Part>;

const EditableDeck = t.intersection([
  t.strict({
    name: t.string,
    calls: t.array(t.array(t.array(Part))),
    responses: t.array(t.string),
  }),
  t.partial({ language: t.string }),
]);
export type EditableDeck = t.TypeOf<typeof EditableDeck>;

const Deck = t.intersection([
  EditableDeck,
  t.strict({
    author: t.string,
    version: t.Int,
  }),
]);
export type Deck = t.TypeOf<typeof Deck>;

const Summary = t.strict({
  name: t.string,
  author: t.string,
  language: t.string,
  calls: t.Int,
  responses: t.Int,
  version: t.Int,
});
export type Summary = t.TypeOf<typeof Summary>;

const SummaryAndCode = t.strict({
  code: t.string,
  summary: Summary,
});
export type SummaryAndCode = t.TypeOf<typeof SummaryAndCode>;

const hasSlot = (call: Part[][]) => {
  for (const line of call) {
    for (const part of line) {
      if (typeof part !== "string" && !part.hasOwnProperty("text")) {
        return true;
      }
    }
  }
  return false;
};

export const validate: (maybeDeck: object) => EditableDeck = (maybeDeck) => {
  const result = EditableDeck.decode(maybeDeck);
  const report = PathReporter.PathReporter.report(result);
  if (Either.isLeft(result)) {
    throw new Error(report.join("\n"));
  } else {
    for (const call of result.right.calls) {
      if (!hasSlot(call)) {
        throw new Error("Calls must contain at least one slot.");
      }
    }
    return result.right;
  }
};
