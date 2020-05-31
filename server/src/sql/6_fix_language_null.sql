CREATE OR REPLACE VIEW manydecks.languages AS
    SELECT decks.deck->>'language' AS code
    FROM manydecks.decks
    WHERE ((decks.deck ? 'public') AND (decks.deck->'public')::bool) AND decks.deck->>'language' IS NOT NULL
    GROUP BY code
    ORDER BY count(*) DESC
