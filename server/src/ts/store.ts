import { default as Migrate } from "postgres-migrations";
import { default as Pg, Pool } from "pg";
import * as Logging from "./logging";
import * as Deck from "./deck";
import * as Patch from "fast-json-patch";
import { default as JsonPatch } from "fast-json-patch";
import * as Errors from "./errors";
import * as uuid from "uuid";
import * as User from "./user";
import * as Code from "./deck/code";

const migrateConfig = {
  logger: (msg: string) => Logging.logger.info(msg),
};

export const init = async (config: Pg.PoolConfig): Promise<Store> => {
  const pool = new Pg.Pool(config);
  let issuer;
  const client = await pool.connect();
  try {
    await client.query(
      "CREATE SCHEMA IF NOT EXISTS manydecks; SET search_path = manydecks;"
    );
    await Migrate.createDb("manydecks", { client }, migrateConfig);
    await Migrate.migrate({ client }, "src/sql", migrateConfig);

    await client.query(
      `
      INSERT INTO manydecks.meta (issuer) VALUES ($1) ON CONFLICT DO NOTHING;
    `,
      [uuid.v4()]
    );

    const meta = await client.query(`
      SELECT issuer FROM manydecks.meta;
    `);

    const [row] = meta.rows;
    issuer = row.issuer;
  } finally {
    client.release();
  }

  return new Store(pool, issuer);
};

export class Store {
  public readonly issuer: string;
  private readonly pool: Pg.Pool;

  public constructor(pool: Pool, issuer: string) {
    this.pool = pool;
    this.issuer = issuer;
  }

  public findOrCreateUser: (
    googleId: string,
    googleName: string | undefined
  ) => Promise<User.User> = async (googleId, googleName) =>
    await this.withClient(async (client) => {
      const existingResult = await client.query(
        `SELECT id, name FROM manydecks.users WHERE google_id = $1;`,
        [googleId]
      );
      if (existingResult.rowCount > 0) {
        const [user] = existingResult.rows;
        return { id: user.id, name: user.name };
      } else {
        const newId = User.id();
        const newName = googleName === undefined ? "New User" : googleName;
        await client.query(
          `INSERT INTO manydecks.users (id, name, google_id) VALUES ($1, $2, $3);`,
          [newId, newName, googleId]
        );
        return { id: newId, name: newName };
      }
    });

  public findOrCreateGuestUser: () => Promise<User.User> = async () =>
    await this.withClient(async (client) => {
      const existingResult = await client.query(
        `SELECT id, name FROM manydecks.users WHERE is_guest;`
      );
      if (existingResult.rowCount > 0) {
        const [user] = existingResult.rows;
        return { id: user.id, name: user.name };
      } else {
        const newId = User.id();
        const newName = "Guest";
        await client.query(
          `INSERT INTO manydecks.users (id, name, is_guest) VALUES ($1, $2, True);`,
          [newId, newName]
        );
        return { id: newId, name: newName };
      }
    });

  public changeUser: (user: string, name: string) => Promise<void> = async (
    user,
    name
  ) =>
    await this.withClient(async (client) => {
      await client.query(`UPDATE manydecks.users SET name=$2 WHERE id=$1;`, [
        user,
        name,
      ]);
    });

  public deleteUser: (user: string) => Promise<void> = async (user) =>
    await this.withClient(async (client) => {
      await client.query(`DELETE FROM manydecks.users WHERE id=$1`, [user]);
    });

  public create: (
    d: Deck.EditableDeck,
    user: string
  ) => Promise<number> = async (d, user) =>
    await this.withClient(async (client) => {
      let deck;
      try {
        deck = Deck.validate(d);
      } catch (error) {
        throw new Errors.BadDeck();
      }
      const insert = await client.query(
        `
        INSERT INTO manydecks.decks (deck, author) VALUES ($1, $2) RETURNING id;
      `,
        [deck, user]
      );
      const [inserted] = insert.rows;
      return inserted.id;
    });

  public getDeck: (id: number, user?: string) => Promise<Deck.Deck> = async (
    id,
    user = undefined
  ) =>
    await this.withClient(async (client) => {
      const meta = await (user === undefined
        ? client.query(
            `
        SELECT users.name as author, decks.deck, decks.version
        FROM manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author 
        WHERE decks.id = $1;
        `,
            [id]
          )
        : client.query(
            `
        SELECT users.name as author, decks.deck, decks.version
        FROM manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author 
        WHERE decks.id = $1 AND decks.author = $2;
        `,
            [id, user]
          ));
      if (meta.rowCount === 0) {
        throw new Errors.DeckNotFound();
      }
      const [metaRow] = meta.rows;
      return {
        ...metaRow.deck,
        author: metaRow.author,
        version: metaRow.version,
      };
    });

  public getDecks: (user: string) => Promise<Deck.Deck[]> = async (user) =>
    await this.withClient(async (client) => {
      const decks = await client.query(
        `
          SELECT users.name as author, decks.deck, decks.version
          FROM manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author 
          WHERE decks.author = $1;
        `,
        [user]
      );
      const results: Deck.Deck[] = [];
      for (const deck of decks.rows) {
        results.push({
          ...deck.deck,
          author: deck.author,
          version: deck.version,
        });
      }
      return results;
    });

  public getSummary: (id: number) => Promise<Deck.Summary> = async (id) =>
    await this.withClient(async (client) => {
      const meta = await client.query(
        `
        SELECT name, author, language, calls, responses, version 
        FROM manydecks.summaries WHERE summaries.id = $1;
        `,
        [id]
      );
      if (meta.rowCount === 0) {
        throw new Errors.DeckNotFound();
      }
      const [metaRow] = meta.rows;
      return {
        name: metaRow.name,
        author: metaRow.author,
        language: metaRow.language,
        calls: metaRow.calls,
        responses: metaRow.responses,
        version: metaRow.version,
      };
    });

  public getSummariesForUser: (
    user: string
  ) => Promise<Deck.SummaryAndCode[]> = async (user) =>
    await this.withClient(async (client) => {
      const result = await client.query(
        `
        SELECT id, name, author, language, calls, responses, version 
        FROM manydecks.summaries WHERE summaries.author_id = $1;
        `,
        [user]
      );
      const summaries = [];
      for (const deck of result.rows) {
        const code = Code.encode(deck.id);
        summaries.push({
          code,
          summary: {
            name: deck.name,
            author: deck.author,
            language: deck.language,
            calls: deck.calls,
            responses: deck.responses,
            version: deck.version,
          },
        });
      }
      return summaries;
    });

  public updateDeck: (
    id: number,
    user: string,
    patch: Patch.Operation[]
  ) => Promise<Deck.Deck> = async (id, user, patch) =>
    await this.withClient(async (client) => {
      const deck = await this.getDeck(id, user);
      try {
        JsonPatch.applyPatch(deck, patch);
      } catch (error) {
        if (
          error instanceof JsonPatch.JsonPatchError &&
          error.name === "TEST_OPERATION_FAILED"
        ) {
          throw new Errors.PatchTestFailed();
        } else {
          throw new Errors.BadPatch();
        }
      }
      let updated;
      try {
        updated = Deck.validate({
          ...deck,
          author: undefined,
          version: undefined,
        });
      } catch (error) {
        throw new Errors.BadPatch();
      }
      await client.query(
        `
        UPDATE manydecks.decks SET deck = $1 WHERE id = $2;
      `,
        [updated, id]
      );
      return deck;
    });

  public deleteDeck: (id: number, user: string) => Promise<void> = async (
    id,
    user
  ) =>
    await this.withClient(async (client) => {
      const result = await client.query(
        `DELETE FROM manydecks.decks WHERE id = $1 AND author = $2`,
        [id, user]
      );
      if (result.rowCount === 0) {
        throw new Errors.DeckNotFound();
      }
    });

  private async withClient<Result>(
    f: (client: Pg.PoolClient) => Promise<Result>
  ): Promise<Result> {
    const client = await this.pool.connect();
    try {
      return await f(client);
    } finally {
      client.release();
    }
  }
}
