import HttpStatus from "http-status-codes";

export abstract class ManyDecksError extends Error {
  public abstract readonly type: string;
  public abstract readonly status: number;

  protected constructor(message: string) {
    super(message);
  }

  public error(): object {
    return {
      error: this.type,
      ...this.details(),
    };
  }

  protected details(): object {
    return {};
  }
}

export class PatchTestFailed extends ManyDecksError {
  public readonly type = "PatchTestFailed";
  public readonly status = HttpStatus.PRECONDITION_FAILED;

  public constructor() {
    super("There was a conflict.");
  }
}

export class BadDeck extends ManyDecksError {
  public readonly type = "BadDeck";
  public readonly status = HttpStatus.BAD_REQUEST;

  public constructor() {
    super("The given deck was invalid.");
  }
}

export class BadPatch extends ManyDecksError {
  public readonly type = "BadPatch";
  public readonly status = HttpStatus.BAD_REQUEST;

  public constructor() {
    super("The given patch was invalid or produced invalid results.");
  }
}

export class DeckNotFound extends ManyDecksError {
  public readonly type = "DeckNotFound";
  public readonly status = HttpStatus.NOT_FOUND;

  public constructor() {
    super("Deck not found.");
  }
}

export class AuthFailure extends ManyDecksError {
  public readonly type = "AuthFailure";
  public readonly status = HttpStatus.BAD_REQUEST;

  public constructor() {
    super("Authentication failure.");
  }
}
