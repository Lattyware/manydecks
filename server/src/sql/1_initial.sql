CREATE SCHEMA IF NOT EXISTS manydecks;

CREATE TABLE IF NOT EXISTS manydecks.meta (
  id bool PRIMARY KEY DEFAULT TRUE,
  issuer UUID NOT NULL,
  CONSTRAINT id CHECK (id)
);

CREATE TABLE IF NOT EXISTS manydecks.users (
    id TEXT NOT NULL PRIMARY KEY,
    name TEXT NOT NULL,
    google_id TEXT NOT NULL,
    UNIQUE (google_id)
);

CREATE TABLE IF NOT EXISTS manydecks.decks (
    id SERIAL PRIMARY KEY,
    version INTEGER NOT NULL DEFAULT 0,
    author TEXT NOT NULL,
    deck JSONB NOT NULL,
    FOREIGN KEY (author) REFERENCES manydecks.users (id) ON DELETE CASCADE
);

CREATE OR REPLACE VIEW manydecks.summaries AS
    SELECT
        decks.id,
        users.name as author,
        users.id as author_id,
        decks.version,
        decks.deck->'name' as name,
        decks.deck->'language' as language,
        jsonb_array_length(decks.deck->'calls') as calls,
        jsonb_array_length(decks.deck->'responses') as responses
    FROM
        manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author;

CREATE OR REPLACE FUNCTION increment_version()
RETURNS TRIGGER AS $$
    BEGIN
        NEW.version = OLD.version + 1;
        return NEW;
    end;
$$ language plpgsql;

BEGIN;
    DROP TRIGGER IF EXISTS increment_version ON manydecks.decks;

    CREATE TRIGGER increment_version
        BEFORE UPDATE ON manydecks.decks
            FOR EACH ROW EXECUTE PROCEDURE increment_version();
COMMIT;
