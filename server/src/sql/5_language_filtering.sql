DROP VIEW manydecks.summaries;

CREATE VIEW manydecks.summaries AS
    SELECT
        decks.id,
        users.name as author,
        users.id as author_id,
        decks.version,
        decks.deck->>'name' as name,
        decks.deck->>'language' as language,
        jsonb_array_length(decks.deck->'calls') as calls,
        jsonb_array_length(decks.deck->'responses') as responses,
        ((decks.deck ? 'public') and (decks.deck->'public')::bool) as public,
        (setweight(to_tsvector('english', coalesce(decks.deck->>'name', '')), 'A') ||
         setweight(to_tsvector('english', decks.deck->'calls'), 'D') ||
         setweight(to_tsvector('english', decks.deck->'responses'), 'D')
        ) as deck_search
    FROM
        manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author;


CREATE OR REPLACE VIEW manydecks.languages AS
    SELECT decks.deck->>'language' AS code
    FROM manydecks.decks
    WHERE ((decks.deck ? 'public') AND (decks.deck->'public')::bool)
    GROUP BY code
    ORDER BY count(*) DESC
