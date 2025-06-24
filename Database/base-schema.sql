CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TABLE IF NOT EXISTS country (
    id SERIAL PRIMARY KEY,                           -- Internal system ID
    name VARCHAR(128) NOT NULL,                      -- Country name (e.g., "United Kingdom")
    official_name VARCHAR(256),                      -- Official name (e.g., "United Kingdom of Great Britain and Northern Ireland")
    iso2 CHAR(2) NOT NULL UNIQUE,                    -- ISO 3166-1 alpha-2 (e.g., "GB")
    iso3 CHAR(3) NOT NULL UNIQUE,                    -- ISO 3166-1 alpha-3 (e.g., "GBR")
    numeric_code CHAR(3),                            -- ISO 3166-1 numeric code (e.g., "826")
    region VARCHAR(64),                              -- UN region (e.g., "Europe")
    subregion VARCHAR(64),                           -- UN subregion (e.g., "Northern Europe")
    independent BOOLEAN DEFAULT TRUE,                -- Whether the country is independent (e.g., not a territory)
    status VARCHAR(64),                              -- Status (e.g., "officially assigned")
    enabled BOOLEAN DEFAULT TRUE,                    -- Can be used in the system
    created_at TIMESTAMPTZ DEFAULT NOW(),  -- Timestamps for tracking
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS currency (
    id              SERIAL PRIMARY KEY,
    code            VARCHAR(3) UNIQUE NOT NULL,     -- ISO 4217 code, e.g. 'USD', 'EUR'
    name            VARCHAR(150) NOT NULL,          -- Full currency name, e.g. 'Unidad de Fomento'
    symbol          VARCHAR(20),                    -- Symbols like '$', '€', or emoji/multi-char symbols
    minor_unit      INTEGER NOT NULL DEFAULT 2,     -- Number of decimal places (e.g. 2 for cents)
    iso_numeric     VARCHAR(3),                     -- ISO numeric code, e.g. '840' for USD
    is_active       BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla base con títulos comunes en todo el mundo
CREATE TABLE IF NOT EXISTS titles (
    id SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL,
    comment TEXT  -- Descripción para ayudar a los devs
);
-- Ejemplos de títulos globales
INSERT INTO titles (label, comment) VALUES
('Mr', 'Common English honorific for men'),
('Mrs', 'Common English honorific for married women'),
('Ms', 'Common English honorific for women, neutral to marital status'),
('Dr', 'Used for people with doctorates or physicians'),
('Prof', 'Used for university professors');
-- Tabla con títulos opcionales según país
CREATE TABLE IF NOT EXISTS optional_titles (
    id SERIAL PRIMARY KEY,
    label VARCHAR(50) NOT NULL,
    country_code CHAR(2) NOT NULL,  -- Código ISO2 del país
    comment TEXT  -- Descripción del título o su uso
);
-- Ejemplos de títulos localizados
INSERT INTO optional_titles (label, country_code, comment) VALUES
('Sheikh', 'AE', 'Commonly used in UAE for nobility or religious leaders'),
('Baroness', 'GB', 'Noble title in the UK'),
('Sir', 'GB', 'Knighted individuals in the UK'),
('Herr', 'DE', 'Equivalent to Mr in German'),
('Madame', 'FR', 'Formal title for women in French-speaking regions');
-- Vista combinada de títulos
-- View: all_titles
-- This view merges global and localized titles into one unified list
-- Each row has a unique, prefixed ID:
--   'G-<id>' for global titles (from titles table)
--   'L-<id>' for localized titles (from optional_titles table)
-- 
-- Use full_id instead of numeric IDs when referencing titles in the UI or APIs.
-- Filtering by country_code will return only localized titles relevant to that country.
CREATE OR REPLACE VIEW all_titles AS
SELECT
    'G-' || id AS full_id,
    label,
    NULL::CHAR(2) AS country_code,
    comment,
    'global' AS source
FROM titles
UNION ALL
SELECT
    'L-' || id AS full_id,
    label,
    country_code,
    comment,
    'local' AS source
FROM optional_titles;
#Query: Get all titles available in a given country (e.g., 'GB')
SELECT *
FROM all_titles
WHERE country_code IS NULL OR country_code = 'GB'
ORDER BY source, label;

-- SYSTEM HEALTH / CARE

-- these tables are for the system to be able to see what is going on and by whom, and also to be proactive when errors happen. these are 'base' tables, they could stay as they are, change or get extended, really depends on what the system looks like
CREATE TABLE IF NOT EXISTS admin_action_logs (
    id SERIAL PRIMARY KEY, -- Primary key
    admin_user_id INTEGER NOT NULL REFERENCES admin_users (id), -- Which admin performed the action
    action_type VARCHAR(100) NOT NULL, -- e.g. UPDATE_USER, DELETE_CARD, etc.
    target_table VARCHAR(100) NOT NULL, -- The table affected by the action
    target_id INTEGER NOT NULL, -- The ID of the affected row in the target table
    changes JSONB, -- JSON showing before/after changes
    ip_address INET, -- IP address of the admin at the time
    user_agent TEXT, -- Device/browser user agent
    created_at TIMESTAMPTZ DEFAULT NOW() -- When the action occurred
);
CREATE TABLE IF NOT EXISTS job_logs (
    id SERIAL PRIMARY KEY, -- Primary key
    job_type VARCHAR(100) NOT NULL, -- Type of job, e.g. SendEmail
    payload JSONB, -- Input payload for the job (if any)
    status VARCHAR(20) NOT NULL CHECK (status IN ('PENDING', 'IN_PROGRESS', 'FAILED', 'COMPLETED')), -- Job execution status
    error_message TEXT, -- Error message if the job failed
    started_at TIMESTAMPTZ, -- When the job started
    finished_at TIMESTAMPTZ -- When the job ended
);
CREATE TABLE IF NOT EXISTS user_login_logs (
    id SERIAL PRIMARY KEY, -- Primary key
    user_id INTEGER NOT NULL REFERENCES users (id), -- User attempting to log in
    ip_address INET, -- IP address of the user
    user_agent TEXT, -- Device/browser used
    login_method VARCHAR(50), -- e.g. password, otp, oauth
    success BOOLEAN NOT NULL, -- Whether the login was successful
    created_at TIMESTAMPTZ DEFAULT NOW() -- When the login attempt occurred
);
CREATE TABLE IF NOT EXISTS system_settings (
    key VARCHAR(100) PRIMARY KEY, -- Unique setting key (e.g. default_currency)
    value TEXT NOT NULL, -- Value of the setting
    updated_by INTEGER REFERENCES admin_users (id), -- Admin who last updated the setting
    updated_at TIMESTAMPTZ DEFAULT NOW() -- When it was last updated
);
CREATE TABLE IF NOT EXISTS system_errors (
    id SERIAL PRIMARY KEY, -- Primary key
    user_id INTEGER REFERENCES users (id), -- Optional user context (if error is user-triggered)
    message TEXT NOT NULL, -- Error message or summary
    stack_trace TEXT, -- Full stack trace
    context JSONB, -- Extra debugging info
    occurred_at TIMESTAMPTZ DEFAULT NOW() -- When the error occurred
);
CREATE TABLE IF NOT EXISTS business_events (
    id SERIAL PRIMARY KEY, -- Primary key
    event_type VARCHAR(100) NOT NULL, -- e.g. UserRegistered, CardIssued
    user_id INTEGER REFERENCES users (id), -- Related user (if any)
    data JSONB, -- Event data payload
    triggered_by VARCHAR(50), -- Source: SYSTEM, ADMIN, API, etc.
    created_at TIMESTAMPTZ DEFAULT NOW() -- When the event was recorded
);

-- USER, PROFILE, AUTH, ROLE, PERMSISSION, ACCESS

CREATE TABLE IF NOT EXISTS user (
    id              BIGSERIAL PRIMARY KEY,
    email           VARCHAR(255) UNIQUE,
    status          VARCHAR(20) NOT NULL DEFAULT 'guest', -- guest, invited, active, inactive, banned
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS user_auth (
    user_id         BIGINT PRIMARY KEY REFERENCES user (id) ON DELETE CASCADE,
    password_hash   TEXT,
    auth_method     VARCHAR(50) DEFAULT 'email', -- email, oauth_google, sms, etc.
    mfa_secret      TEXT,
    last_login_at   TIMESTAMPTZ,
    password_reset_token  TEXT,
    password_reset_expiry TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS user_profile (
    user_id         BIGINT PRIMARY KEY REFERENCES user (id) ON DELETE CASCADE,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    phone           VARCHAR(20),
    language        VARCHAR(10),
    avatar_url      TEXT
);
CREATE TABLE IF NOT EXISTS role (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(50) UNIQUE NOT NULL,  -- e.g. 'client_admin', 'client_viewer', 'sys_admin'
    scope       VARCHAR(20) NOT NULL,         -- 'client' or 'admin'
    label       VARCHAR(100),                 -- e.g. 'Client Administrator'
    description TEXT
);
CREATE TABLE IF NOT EXISTS user_to_role (
    user_id      BIGINT NOT NULL,
    role_id      INT NOT NULL REFERENCES role (id),
    context_id   BIGINT,                      -- Nullable: used for client roles
    context_type VARCHAR(50),                 -- e.g. 'client'
    assigned_at  TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, role_id, context_id, context_type)
);
CREATE TABLE IF NOT EXISTS permission (
    id            SERIAL PRIMARY KEY,
    code          VARCHAR(100) UNIQUE NOT NULL,     -- e.g. 'can_view_balance', 'can_edit_users'
    label         VARCHAR(100),                     -- Human-readable name
    module        VARCHAR(50),                      -- Optional: 'clients', 'cards', 'admin', etc.
    description   TEXT
);
CREATE TABLE IF NOT EXISTS role_to_permission (
    role_id        INT REFERENCES role(id) ON DELETE CASCADE,
    permission_id  INT REFERENCES permission(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);
CREATE TABLE IF NOT EXISTS access (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(100) UNIQUE NOT NULL,   -- e.g. 'fx_module', 'admin_dashboard'
    label       VARCHAR(100),                   -- e.g. 'FX Module'
    description TEXT
);
CREATE TABLE IF NOT EXISTS role_to_access (
    role_id    INT REFERENCES role(id) ON DELETE CASCADE,
    access_id  INT REFERENCES access(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, access_id)
);
CREATE TABLE IF NOT EXISTS user_access_override (
    user_id    BIGINT,
    access_id  INT,
    is_allowed BOOLEAN DEFAULT TRUE,
    PRIMARY KEY (user_id, access_id)
);

-- ADDRESS

CREATE TABLE IF NOT EXISTS address (
    id                BIGSERIAL PRIMARY KEY,
    -- Main address components (can be adapted globally)
    address_line_1    TEXT NOT NULL,                  -- e.g. 123 Main St
    address_line_2    TEXT,                           -- e.g. Apt 4B, Suite 200
    city              VARCHAR(100),                   -- City, town, or village
    region            VARCHAR(100),                   -- State, province, or department
    postal_code       VARCHAR(20),                    -- ZIP or postcode
    -- ISO country code (joinable to a country table)
    country_code      CHAR(2) NOT NULL REFERENCES country (iso2),
    -- Optional geolocation support
    latitude          DOUBLE PRECISION,
    longitude         DOUBLE PRECISION,
    -- Notes for delivery, clarification, etc.
    notes             TEXT,
    -- Useful for logical deletion or historical management
    is_active         BOOLEAN DEFAULT TRUE,
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS address_link (
    id             BIGSERIAL PRIMARY KEY,
    entity_type    VARCHAR(50) NOT NULL,              -- 'user', 'client', etc.
    entity_id      BIGINT NOT NULL,
    address_id     BIGINT NOT NULL REFERENCES address (id) ON DELETE CASCADE,
    address_type_id  INT NOT NULL REFERENCES address_type (id),
    is_active      BOOLEAN DEFAULT TRUE,
    linked_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS address_type (
    id          SERIAL PRIMARY KEY,
    code        VARCHAR(50) UNIQUE NOT NULL,  -- e.g. 'registered', 'residential'
    label       VARCHAR(100),                 -- Display name
    description TEXT,
    is_unique   BOOLEAN DEFAULT TRUE          -- Whether only one 'current' of this type is allowed per entity
);

-- CLIENT

CREATE TABLE IF NOT EXISTS organization_subtype (
    id            SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL UNIQUE,     -- e.g. 'limited_company', 'charity'
    label         VARCHAR(100),                     -- Human-friendly label
    description   TEXT,
    allowed_type  VARCHAR(50) NOT NULL              -- Should be 'organization' for now
);
CREATE TABLE IF NOT EXISTS client (
    id             BIGSERIAL PRIMARY KEY,
    type           VARCHAR(50) NOT NULL CHECK ( type IN ('personal', 'organization') ),
    subtype_id     INTEGER REFERENCES organization_subtype (id),
    name           VARCHAR(255) NOT NULL,
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- ⚙️ Trigger Function to Enforce Type/Subtype Relationship
CREATE OR REPLACE FUNCTION validate_client_subtype()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.type = 'personal' AND NEW.subtype_id IS NOT NULL THEN
        RAISE EXCEPTION 'Personal clients cannot have a subtype';
    END IF;
    IF NEW.type = 'organization' AND NEW.subtype_id IS NOT NULL THEN
        -- Ensure the subtype is valid for 'organization'
        IF NOT EXISTS (
            SELECT 1 FROM organization_subtype
            WHERE id = NEW.subtype_id AND allowed_type = 'organization'
        ) THEN
            RAISE EXCEPTION 'Invalid subtype for organization client';
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- 🔗 Trigger Setup
CREATE TRIGGER trg_validate_client_subtype
BEFORE INSERT OR UPDATE ON client
FOR EACH ROW EXECUTE FUNCTION validate_client_subtype();

-- ORGANIZATION PROFILE, EXTENSIONS (I.E. CHARITY, BUSINESS)

CREATE TABLE IF NOT EXISTS organization_profile (
    id BIGSERIAL PRIMARY KEY,
    client_id BIGINT NOT NULL UNIQUE REFERENCES client (id) ON DELETE CASCADE,
    legal_name VARCHAR(255) NOT NULL,                         -- Registered legal name
    registration_identifier VARCHAR(100),                    -- e.g. VAT, CUIT, TIN, ABN or other registration number
    registration_identifier_type VARCHAR(50),                -- e.g. 'CUIT', 'TIN', 'VAT', 'EIN' or other
    incorporation_date DATE,
    industry VARCHAR(100),
    website VARCHAR(255),
    phone VARCHAR(50),
    email VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
-- examples of 'extensions (see documentation for more details)
CREATE TABLE IF NOT EXISTS charity_profile (
    client_id            BIGINT PRIMARY KEY REFERENCES client (id) ON DELETE CASCADE,
    mission_statement    TEXT,
    funding_sources      TEXT,
    governing_body       VARCHAR(255),
    registered_charity_no VARCHAR(100),
    created_at           TIMESTAMPTZ DEFAULT NOW(),
    updated_at           TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS business_profile (
    client_id        BIGINT PRIMARY KEY REFERENCES client (id) ON DELETE CASCADE,
    industry         VARCHAR(100),
    num_employees    INT,
    annual_revenue   NUMERIC(15, 2),
    vat_number       VARCHAR(100),
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- WALLET, BALANCE, TRANSACTION

CREATE TABLE IF NOT EXISTS wallet (
  id UUID PRIMARY KEY,
  client_id UUID REFERENCES client(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS wallet_balance (
  id UUID PRIMARY KEY,
  wallet_id UUID REFERENCES wallet(id),
  currency VARCHAR(3),
  amount NUMERIC(18, 4),  -- this is the "pot" value
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS transaction (
  id UUID PRIMARY KEY,
  wallet_id UUID REFERENCES wallet(id),
  user_id UUID REFERENCES user(id),
  currency VARCHAR(3),
  amount NUMERIC(18, 4),  -- can be positive or negative
  type VARCHAR(20),       -- top_up, payment, refund, fx, etc.
  reference_id UUID,      -- optional FK to top_up/payment/etc.
  created_at TIMESTAMPTZ DEFAULT NOW()
);

/*
🧠 Why this is powerful:
You always know the real current balance (wallet_balance).
You never lose the audit trail (transaction).
You can reconstruct any balance by summing transactions if needed.
You can validate the wallet_balance by comparing to the SUM() of transaction.
⚠️ Caution
Whenever a new transaction is inserted:
It must also update the matching row in wallet_balance.
Or, if that row doesn’t exist yet (e.g. first time in that currency), it must be created.
*/

-- This table tracks funds that are reserved, not yet settled, but must be subtracted from the available balance.
CREATE TABLE IF NOT EXISTS wallet_authorization (
    id UUID PRIMARY KEY, -- Unique identifier for the hold
    wallet_id UUID NOT NULL REFERENCES wallet (id), -- Whose wallet
    currency VARCHAR(3) NOT NULL, -- Same as wallet_balance
    amount NUMERIC(18, 4) NOT NULL, -- Positive value = amount held
    status VARCHAR(20) NOT NULL, -- AUTHORIZED, CAPTURED, CANCELLED, EXPIRED
    internal_ref UUID, -- Internal Calu reference
    external_request_ref VARCHAR(100), -- ID we send to 3rd party
    external_response_ref VARCHAR(100), -- ID we receive from 3rd party
    expires_at TIMESTAMPTZ, -- Optional: automatic release after this
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS user_wallet_balance (
    id UUID PRIMARY KEY,
    wallet_id UUID NOT NULL REFERENCES wallet(id),
    user_id UUID NOT NULL REFERENCES users(id),
    currency VARCHAR(3) NOT NULL,
    amount NUMERIC(18, 4) NOT NULL, -- Current user balance
    updated_at TIMESTAMPTZ DEFAULT NOW() -- not sure if this one is correct
);

-- WALLLET LIMITS

CREATE TABLE IF NOT EXISTS wallet_limits (
    id                SERIAL PRIMARY KEY,
    -- Who the rule applies to
    target_type       VARCHAR(20) NOT NULL CHECK (
                          target_type IN ('user_wallet', 'client_wallet', 'wallet')
                      ),
    target_id         BIGINT NOT NULL,
    -- Rule identifier (semantic label)
    rule_key VARCHAR(100) NOT NULL REFERENCES wallet_limit_definitions (key)
 -- e.g. 'txns_over_500', 'daily_limit'
    -- Rule definition
    rule_type         VARCHAR(30) NOT NULL CHECK (
                          rule_type IN ('count', 'amount', 'frequency', 'special', 'bonus')
                      ),
    direction         VARCHAR(5) NOT NULL CHECK (
                          direction IN ('max', 'min')
                      ),
    timeframe         VARCHAR(10) CHECK (
                          timeframe IN ('txn', 'minute', 'hour', 'day', 'week', 'month', 'year')
                      ),
    value             BIGINT NOT NULL,       -- Amount (in pennies) or count
    condition_amount  BIGINT,                -- Optional: only apply if txn ≥ this amount
    currency VARCHAR(3) REFERENCES currency (code) ON UPDATE CASCADE ON DELETE SET NULL -- Optional: if NULL, the rule applies to all currencies
    -- Rule status
    is_active         BOOLEAN DEFAULT TRUE,
    valid_from        TIMESTAMPTZ,
    valid_until       TIMESTAMPTZ,
    -- Audit
    created_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_at        TIMESTAMPTZ DEFAULT NOW(),
    updated_by        INTEGER REFERENCES admin_users (id)
);
-- Unique constraint for active rule keys:
CREATE UNIQUE INDEX uq_wallet_limits_active_rule
ON wallet_limits (target_type, target_id, rule_key)
WHERE is_active = TRUE;
CREATE TABLE IF NOT EXISTS wallet_limit_definitions (
    key           VARCHAR(100) PRIMARY KEY,  -- e.g. 'txns_over_500'
    label         VARCHAR(100) NOT NULL,     -- UI-friendly name
    description   TEXT,                      -- Admin explanation
    default_value BIGINT,                    -- Optional: suggested value
    default_currency VARCHAR(3)              -- Optional: only relevant for amount-type rules
);
-- ✅ Seed Data for wallet_limit_definitions 
INSERT INTO wallet_limit_definitions (key, label, description, default_value, default_currency) VALUES
-- General daily caps
('daily_limit', 'Daily Spend Limit', 'Maximum total amount that can be spent per day', 100000, 'GBP'),
('daily_txn_count', 'Daily Transaction Count', 'Maximum number of transactions allowed per day', 20, NULL),
-- Transaction-specific limits
('txn_amount_limit', 'Max Amount Per Transaction', 'Maximum allowed amount for a single transaction', 50000, 'GBP'),
('min_time_between_txns', 'Minimum Time Between Transactions', 'Minimum time in seconds between each transaction', 10, NULL),
-- Conditional limits
('txns_over_500', 'Large Transaction Count (Over £500)', 'Max number of transactions allowed per day when the amount is £500 or more', 3, 'GBP'),
-- Weekly limits
('weekly_limit', 'Weekly Spend Limit', 'Maximum total amount that can be spent in a 7-day window', 300000, 'GBP'),
('weekly_txn_count', 'Weekly Transaction Count', 'Maximum number of transactions per week', 50, NULL),
-- Withdrawal/top-up
('daily_withdrawal_limit', 'Daily Withdrawal Limit', 'Total allowed amount withdrawn per day', 100000, 'GBP'),
('withdrawal_txn_count', 'Daily Withdrawal Count', 'Max number of withdrawal transactions per day', 5, NULL),
('topup_txn_count', 'Daily Top-Up Count', 'Maximum number of top-ups allowed per day', 3, NULL),
-- Bonus use
('bonus_usage_limit', 'Bonus Usage Limit', 'Max amount of bonus funds that can be used per day', 25000, 'GBP');

-- Attach the set_updated_at trigger to tables with updated_at column, e.g.:
-- CREATE TRIGGER trg_update_table_name
-- BEFORE UPDATE ON table_name
-- FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Attach triggers for updated_at columns
CREATE TRIGGER trg_update_country
BEFORE UPDATE ON country
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_currency
BEFORE UPDATE ON currency
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_system_settings
BEFORE UPDATE ON system_settings
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_user
BEFORE UPDATE ON user
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_address
BEFORE UPDATE ON address
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_client
BEFORE UPDATE ON client
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_organization_profile
BEFORE UPDATE ON organization_profile
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_charity_profile
BEFORE UPDATE ON charity_profile
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_business_profile
BEFORE UPDATE ON business_profile
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_user_wallet_balance
BEFORE UPDATE ON user_wallet_balance
FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_update_wallet_limits
BEFORE UPDATE ON wallet_limits
FOR EACH ROW EXECUTE FUNCTION set_updated_at();
