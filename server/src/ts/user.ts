import * as uuid from "uuid";

export type Id = string;

export const id: () => Id = uuid.v4;

export interface User {
  id: Id;
  name: string;
}
