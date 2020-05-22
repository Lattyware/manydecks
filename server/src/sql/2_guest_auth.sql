                            -- We now allow accounts that don't have a google_id attached.
ALTER TABLE manydecks.users ALTER COLUMN google_id DROP NOT NULL,
                            -- We now allow a guest account to exist.
                            ADD COLUMN is_guest BOOLEAN NOT NULL DEFAULT FALSE,
                            -- We require that accounts have at least one authorization method.
                            ADD CONSTRAINT can_login CHECK (google_id IS NOT NULL OR is_guest = True);

-- Only allow a single guest account.
CREATE UNIQUE INDEX ON manydecks.users (is_guest) WHERE users.is_guest;
