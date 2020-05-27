CREATE INDEX deck_search ON manydecks.decks USING GIN ((
    setweight(to_tsvector('english', coalesce(decks.deck->'name', '""')), 'A') ||
    setweight(to_tsvector('english', decks.deck->'calls'), 'D') ||
    setweight(to_tsvector('english', decks.deck->'responses'), 'D')
));

CREATE OR REPLACE VIEW manydecks.summaries AS
    SELECT
        decks.id,
        users.name as author,
        users.id as author_id,
        decks.version,
        decks.deck->'name' as name,
        decks.deck->'language' as language,
        jsonb_array_length(decks.deck->'calls') as calls,
        jsonb_array_length(decks.deck->'responses') as responses,
        ((decks.deck ? 'public') and (decks.deck->'public')::bool) as public,
        (setweight(to_tsvector('english', coalesce(decks.deck->'name', '""')), 'A') ||
            setweight(to_tsvector('english', decks.deck->'calls'), 'D') ||
            setweight(to_tsvector('english', decks.deck->'responses'), 'D')
        ) as deck_search
    FROM
        manydecks.decks INNER JOIN manydecks.users ON users.id = decks.author;
