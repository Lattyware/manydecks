// This is just a hack-y type def to stop compiler complaints, obviously not complete.

declare namespace Express {
  export interface Response {
    zip(options: {
      filename: string;
      files: { name: string; content: string }[];
    }): this;
  }
}

declare module "express-easy-zip" {
  import type { RequestHandler } from "express";

  export const Zip: () => RequestHandler;

  export default Zip;
}
