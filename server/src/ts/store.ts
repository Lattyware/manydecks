import { default as Migrate } from "postgres-migrations";
import { default as Pg, Pool } from "pg";
import * as Logging from "./logging";
import * as Deck from "./deck";
import * as Patch from "fast-json-patch";
import { default as JsonPatch } from "fast-json-patch";
import * as Errors from "./errors";
import * as uuid from "uuid";
import * as User from "./user";
import * as UserName from "./user/name";
import * as Code from "./deck/code";

export interface CreatedOrFoundUser {
  result: "Created" | "Found";
  user: User.User;
}

export function unknownResult(result: never): never {
  throw new Error(`Unknown result: "${result}".`);
}

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
    const db = config.database
      ? config.database
      : config.user
      ? config.user
      : "manydecks";
    await Migrate.createDb(db, { client }, migrateConfig);
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

  public languages: () => Promise<string[]> = async () =>
    await this.withClient(async (client) => {
      const result = await client.query(
        `SELECT code FROM manydecks.languages;`
      );
      return result.rows.map((row) => row.code);
    });

  public findOrCreateGoogleUser: (
    googleId: string,
    googleName?: string
  ) => Promise<CreatedOrFoundUser> = async (googleId, googleName) =>
    await this.withClient(async (client) => {
      const existingResult = await client.query(
        `SELECT id, name FROM manydecks.users WHERE google_id = $1;`,
        [googleId]
      );
      if (existingResult.rowCount > 0) {
        const [user] = existingResult.rows;
        return { result: "Found", user: { id: user.id, name: user.name } };
      } else {
        const newId = User.id();
        const newName =
          googleName === undefined ? UserName.random() : googleName;
        await client.query(
          `INSERT INTO manydecks.users (id, name, google_id) VALUES ($1, $2, $3);`,
          [newId, newName, googleId]
        );
        return { result: "Created", user: { id: newId, name: newName } };
      }
    });

  public findOrCreateTwitchUser: (
    twitchId: string,
    twitchName?: string
  ) => Promise<CreatedOrFoundUser> = async (twitchId, twitchName) =>
    await this.withClient(async (client) => {
      const existingResult = await client.query(
        `SELECT id, name FROM manydecks.users WHERE twitch_id = $1;`,
        [twitchId]
      );
      if (existingResult.rowCount > 0) {
        const [user] = existingResult.rows;
        return { result: "Found", user: { id: user.id, name: user.name } };
      } else {
        const newId = User.id();
        const newName =
          twitchName === undefined ? UserName.random() : twitchName;
        await client.query(
          `INSERT INTO manydecks.users (id, name, twitch_id) VALUES ($1, $2, $3);`,
          [newId, newName, twitchId]
        );
        return { result: "Created", user: { id: newId, name: newName } };
      }
    });

  public findOrCreateGuestUser: () => Promise<CreatedOrFoundUser> = async () =>
    await this.withClient(async (client) => {
      const existingResult = await client.query(
        `SELECT id, name FROM manydecks.users WHERE is_guest;`
      );
      if (existingResult.rowCount > 0) {
        const [user] = existingResult.rows;
        return { result: "Found", user: { id: user.id, name: user.name } };
      } else {
        const newId = User.id();
        const newName = UserName.random();
        await client.query(
          `INSERT INTO manydecks.users (id, name, is_guest) VALUES ($1, $2, True);`,
          [newId, newName]
        );
        return { result: "Created", user: { id: newId, name: newName } };
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

  public getDeck: (id: number) => Promise<Deck.Deck> = async (id) =>
    await this.withClient(async (client) => {
      const meta = await client.query(
        `
        SELECT users.name as author, decks.author as author_id, decks.deck, decks.version
        FROM manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author 
        WHERE decks.id = $1;
        `,
        [id]
      );
      if (meta.rowCount === 0) {
        throw new Errors.DeckNotFound();
      }
      const [metaRow] = meta.rows;
      return {
        ...metaRow.deck,
        author: {
          id: metaRow.author_id,
          name: metaRow.author,
        },
        version: metaRow.version,
      };
    });

  public getDecks: (user: string) => Promise<Deck.Deck[]> = async (user) =>
    await this.withClient(async (client) => {
      const decks = await client.query(
        `
          SELECT users.name as author, decks.author as author_id, decks.deck, decks.version
          FROM manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author 
          WHERE decks.author = $1;
        `,
        [user]
      );
      const results: Deck.Deck[] = [];
      for (const deck of decks.rows) {
        results.push({
          ...deck.deck,
          author: {
            id: deck.author_id,
            name: deck.author,
          },
          version: deck.version,
        });
      }
      return results;
    });

  public getSummary: (id: number) => Promise<Deck.Summary> = async (id) =>
    await this.withClient(async (client) => {
      const meta = await client.query(
        `
        SELECT name, author, author_id, language, calls, responses, public, version 
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
        author: {
          id: metaRow.author_id,
          name: metaRow.author,
        },
        language: metaRow.language,
        calls: metaRow.calls,
        responses: metaRow.responses,
        version: metaRow.version,
        public: metaRow.public,
      };
    });

  private static *summariesFromRows(
    result: Pg.QueryResult
  ): Iterable<Deck.CodeAndSummary> {
    for (const deck of result.rows) {
      const code = Code.encode(deck.id);
      yield {
        code,
        summary: {
          name: deck.name,
          author: {
            id: deck.author_id,
            name: deck.author,
          },
          language: deck.language,
          calls: deck.calls,
          responses: deck.responses,
          public: deck.public,
          version: deck.version,
        },
      };
    }
  }

  public getSummariesForUser: (
    user: string,
    publicOnly: boolean
  ) => Promise<Iterable<Deck.CodeAndSummary>> = async (
    user,
    publicOnly = true
  ) =>
    await this.withClient(async (client) => {
      const result = await client.query(
        `
        SELECT id, name, author_id, author, language, calls, responses, public, version
        FROM manydecks.summaries WHERE summaries.author_id = $1 AND (NOT $2 OR summaries.public)
        ORDER BY id DESC;
        `,
        [user, publicOnly]
      );
      return Store.summariesFromRows(result);
    });

  public browse: (
    query?: string,
    language?: string,
    page?: number
  ) => Promise<Iterable<Deck.CodeAndSummary>> = async (query, language, page) =>
    await this.withClient(async (client) => {
      const pageSize = 20;
      const p = page === undefined ? 0 : page;
      const l = language === undefined ? null : language;
      let result;
      if (query === undefined) {
        result = await client.query(
          `
            SELECT id, name, author_id, author, language, calls, responses, public, version
            FROM manydecks.summaries 
            WHERE summaries.public AND ($3::text IS NULL OR summaries.language = $3::text)
            ORDER BY id DESC 
            OFFSET $1::int * $2::int LIMIT $2
          `,
          [p, pageSize, l]
        );
      } else {
        result = await client.query(
          `
            SELECT id, name, author_id, author, language, calls, responses, public, version, ts_rank_cd(deck_search , query) AS rank
            FROM manydecks.summaries, plainto_tsquery($4) query 
            WHERE summaries.public  AND ($3::text IS NULL OR summaries.language = $3::text)
            AND query @@ summaries.deck_search 
            ORDER BY rank DESC 
            OFFSET $1::int * $2::int LIMIT $2
          `,
          [p, pageSize, l, query]
        );
      }
      return Store.summariesFromRows(result);
    });

  public updateDeck: (
    id: number,
    user: string,
    patch: Patch.Operation[]
  ) => Promise<Deck.Deck> = async (id, user, patch) =>
    await this.withClient(async (client) => {
      const deck = await this.getDeck(id);
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
      const result = await client.query(
        `
        UPDATE manydecks.decks SET deck = $1 WHERE id = $2 AND author = $3;
      `,
        [updated, id, user]
      );
      if (result.rowCount === 0) {
        throw new Errors.DeckNotFound();
      }
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
