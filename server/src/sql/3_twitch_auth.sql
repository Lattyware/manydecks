                            -- Users can now log in with a twitch account.
ALTER TABLE manydecks.users ADD COLUMN twitch_id TEXT,
                            -- One account per twitch account.
                            ADD UNIQUE (twitch_id),
                            -- Replace our check that the user has at least one login method to allow for twitch-only accounts.
                            DROP CONSTRAINT can_login,
                            ADD CONSTRAINT can_login CHECK (google_id IS NOT NULL OR twitch_id IS NOT NULL OR is_guest);
