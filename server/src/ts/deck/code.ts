import Hashids from "hashids";
import * as Errors from "../errors";

const hashIds = new Hashids(
  "manydecks",
  5,
  "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
);

export const decode = (code: string): number => {
  try {
    return Number(hashIds.decode(code)[0]);
  } catch (error) {
    throw new Errors.DeckNotFound();
  }
};

export const encode = (id: number): string => hashIds.encode(id);
