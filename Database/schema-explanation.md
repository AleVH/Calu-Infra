# Calu Platform Database Schema  
*Comprehensive Technical Documentation*  
_Last generated: 2025-06-26_

---

## **Index**

- [Calu Platform Database Schema](#calu-platform-database-schema)
  - [**Index**](#index)
  - [1. **Overview**](#1-overview)
  - [2. **Entity-Relationship Diagram (ERD)**](#2-entity-relationship-diagram-erd)
    - [3.1 Reference Tables](#31-reference-tables)
      - [**country**](#country)
      - [**currency**](#currency)
      - [**titles / optional\_titles / all\_titles (view)**](#titles--optional_titles--all_titles-view)
    - [3.2 User \& Identity Management](#32-user--identity-management)
      - [**user**](#user)
      - [**admin\_user**](#admin_user)
      - [**user\_auth**](#user_auth)
      - [**user\_profile**](#user_profile)
      - [**Role-Based Access Control (RBAC)**](#role-based-access-control-rbac)
    - [3.3 Address System](#33-address-system)
      - [**address**](#address)
      - [**address\_type**](#address_type)
      - [**address\_link**](#address_link)
    - [3.4 Client \& Organization](#34-client--organization)
      - [**client**](#client)
      - [**organization\_subtype**](#organization_subtype)
      - [**organization\_profile**](#organization_profile)
      - [**charity\_profile**](#charity_profile)
      - [**business\_profile**](#business_profile)
    - [3.5 Wallet \& Finance](#35-wallet--finance)
      - [**wallet**](#wallet)
      - [**wallet\_balance**](#wallet_balance)
      - [**transaction**](#transaction)
      - [**wallet\_authorization**](#wallet_authorization)
      - [**user\_wallet\_balance**](#user_wallet_balance)
      - [**wallet\_limit\_definitions**](#wallet_limit_definitions)
      - [**wallet\_limits**](#wallet_limits)
    - [3.6 System Health / Logging](#36-system-health--logging)
      - [**admin\_action\_logs**](#admin_action_logs)
      - [**job\_logs**](#job_logs)
      - [**user\_login\_logs**](#user_login_logs)
      - [**system\_settings**](#system_settings)
      - [**system\_errors**](#system_errors)
      - [**business\_events**](#business_events)
  - [4. Triggers, Views \& Functions](#4-triggers-views--functions)
    - [**set\_updated\_at** (Trigger Function)](#set_updated_at-trigger-function)
    - [**validate\_client\_subtype** (Trigger Function)](#validate_client_subtype-trigger-function)
    - [**all\_titles** (View)](#all_titles-view)
    - [**Other Notes**](#other-notes)
  - [5. Design Rationale \& Notes](#5-design-rationale--notes)
  - [6. Sample Queries](#6-sample-queries)

---

## 1. **Overview**

The Calu platform schema is designed for modularity, extensibility, and strong normalization.

**Major domains:**

- _Reference data_: Countries, currencies, global and local titles
- _User & identity_: User accounts, authentication, roles, permissions, profiles
- _Client management_: Individual & organizational clients with extensible profiles
- _Address management_: Flexible address linking by entity and type
- _Wallet & transactions_: Multi-currency wallet, balance tracking, robust audit trails
- _System health_: Logging, settings, admin actions, errors, business events

---

## 2. **Entity-Relationship Diagram (ERD)**

Paste the following into [dbdiagram.io](https://dbdiagram.io) for a graphical overview:

```dbml
Table country {
  id serial [pk]
  name varchar
  official_name varchar
  iso2 char [unique]
  iso3 char [unique]
  numeric_code char
  region varchar
  subregion varchar
  independent boolean
  status varchar
  enabled boolean
  created_at timestamptz
  updated_at timestamptz
}

Table currency {
  id serial [pk]
  code varchar [unique]
  name varchar
  symbol varchar
  minor_unit integer
  iso_numeric varchar
  is_active boolean
  created_at timestamptz
  updated_at timestamptz
}

Table titles {
  id serial [pk]
  label varchar [unique]
  comment text
}

Table optional_titles {
  id serial [pk]
  label varchar
  country_code char [ref: > country.iso2]
  comment text
}

Table "user" {
  id uuid [pk]
  email varchar [unique]
  status varchar
  is_verified boolean
  created_at timestamptz
  updated_at timestamptz
}

Table admin_user {
  id uuid [pk]
  user_id uuid [unique, ref: > user.id]
  role varchar
  created_at timestamptz
}

Table user_auth {
  user_id uuid [pk, ref: > user.id]
  password_hash text
  auth_method varchar
  mfa_secret text
  last_login_at timestamptz
  password_reset_token text
  password_reset_expiry timestamptz
}

Table user_profile {
  user_id uuid [pk, ref: > user.id]
  title_full_id varchar
  first_name varchar
  last_name varchar
  phone varchar
  language varchar
  avatar_url text
}

Table role {
  id serial [pk]
  code varchar [unique]
  scope varchar
  label varchar
  description text
}

Table user_to_role {
  user_id uuid [ref: > user.id]
  role_id int [ref: > role.id]
  context_id bigint
  context_type varchar
  assigned_at timestamptz
  indexes {
    (user_id, role_id, context_id, context_type) [pk]
  }
}

Table permission {
  id serial [pk]
  code varchar [unique]
  label varchar
  module varchar
  description text
}

Table role_to_permission {
  role_id int [ref: > role.id]
  permission_id int [ref: > permission.id]
  indexes {
    (role_id, permission_id) [pk]
  }
}

Table access {
  id serial [pk]
  code varchar [unique]
  label varchar
  description text
}

Table role_to_access {
  role_id int [ref: > role.id]
  access_id int [ref: > access.id]
  indexes {
    (role_id, access_id) [pk]
  }
}

Table user_access_override {
  user_id uuid [ref: > user.id]
  access_id int
  is_allowed boolean
  indexes {
    (user_id, access_id) [pk]
  }
}

Table address {
  id uuid [pk]
  address_line_1 text
  address_line_2 text
  city varchar
  region varchar
  postal_code varchar
  country_code char [ref: > country.iso2]
  latitude double
  longitude double
  notes text
  is_active boolean
  created_at timestamptz
  updated_at timestamptz
}

Table address_type {
  id serial [pk]
  code varchar [unique]
  label varchar
  description text
  is_unique boolean
}

Table address_link {
  id bigserial [pk]
  entity_type varchar
  entity_id uuid
  address_id uuid [ref: > address.id]
  address_type_id int [ref: > address_type.id]
  is_active boolean
  linked_at timestamptz
}

Table organization_subtype {
  id serial [pk]
  name varchar [unique]
  label varchar
  description text
  allowed_type varchar
}

Table client {
  id uuid [pk]
  type varchar
  subtype_id int [ref: > organization_subtype.id]
  name varchar
  created_at timestamptz
  updated_at timestamptz
}

Table organization_profile {
  id bigserial [pk]
  client_id uuid [unique, ref: > client.id]
  legal_name varchar
  registration_identifier varchar
  registration_identifier_type varchar
  incorporation_date date
  industry varchar
  website varchar
  phone varchar
  email varchar
  created_at timestamptz
  updated_at timestamptz
}

Table charity_profile {
  client_id uuid [pk, ref: > client.id]
  mission_statement text
  funding_sources text
  governing_body varchar
  registered_charity_no varchar
  created_at timestamptz
  updated_at timestamptz
}

Table business_profile {
  client_id uuid [pk, ref: > client.id]
  industry varchar
  num_employees int
  annual_revenue numeric
  vat_number varchar
  created_at timestamptz
  updated_at timestamptz
}

Table wallet {
  id uuid [pk]
  client_id uuid [ref: > client.id]
  created_at timestamptz
}

Table wallet_balance {
  id uuid [pk]
  wallet_id uuid [ref: > wallet.id]
  currency varchar [ref: > currency.code]
  amount numeric
  updated_at timestamptz
}

Table transaction {
  id uuid [pk]
  wallet_id uuid [ref: > wallet.id]
  user_id uuid [ref: > user.id]
  currency varchar [ref: > currency.code]
  amount numeric
  type varchar
  reference_id uuid
  created_at timestamptz
}

Table wallet_authorization {
  id uuid [pk]
  wallet_id uuid [ref: > wallet.id]
  currency varchar [ref: > currency.code]
  amount numeric
  status varchar
  internal_ref uuid
  external_request_ref varchar
  external_response_ref varchar
  expires_at timestamptz
  created_at timestamptz
}

Table user_wallet_balance {
  id uuid [pk]
  wallet_id uuid [ref: > wallet.id]
  user_id uuid [ref: > user.id]
  currency varchar [ref: > currency.code]
  amount numeric
  updated_at timestamptz
}

Table wallet_limit_definitions {
  key varchar [pk]
  label varchar
  description text
  default_value bigint
  default_currency varchar
}

Table wallet_limits {
  id serial [pk]
  target_type varchar
  target_id bigint
  rule_key varchar [ref: > wallet_limit_definitions.key]
  rule_type varchar
  direction varchar
  timeframe varchar
  value bigint
  condition_amount bigint
  currency varchar [ref: > currency.code]
  is_active boolean
  valid_from timestamptz
  valid_until timestamptz
  created_at timestamptz
  updated_at timestamptz
  updated_by uuid [ref: > admin_user.id]
}

Table admin_action_logs {
  id uuid [pk]
  admin_id uuid [ref: > admin_user.id]
  action_type varchar
  target_table varchar
  target_id integer
  changes jsonb
  ip_address inet
  user_agent text
  created_at timestamptz
}

Table job_logs {
  id uuid [pk]
  job_type varchar
  payload jsonb
  status varchar
  result jsonb
  started_at timestamptz
  finished_at timestamptz
}

Table user_login_logs {
  id uuid [pk]
  user_id uuid [ref: > user.id]
  is_admin boolean
  ip_address inet
  user_agent text
  login_method varchar
  success boolean
  created_at timestamptz
}

Table system_settings {
  key varchar [pk]
  value text
  updated_by uuid [ref: > admin_user.id]
  updated_at timestamptz
}

Table system_errors {
  id uuid [pk]
  user_id uuid [ref: > user.id]
  service varchar
  level varchar
  message text
  stack_trace text
  context jsonb
  occurred_at timestamptz
}

Table business_events {
  id serial [pk]
  event_type varchar
  user_id uuid [ref: > user.id]
  reference_id uuid
  data jsonb
  triggered_by varchar
  created_at timestamptz
}
```

---

### 3.1 Reference Tables

---

#### **country**

| Column         | Type           | Description                                  |
|:-------------- |:-------------- |:---------------------------------------------|
| id             | SERIAL         | Internal system PK                           |
| name           | VARCHAR(128)   | Display name                                 |
| official_name  | VARCHAR(256)   | Formal full name                             |
| iso2           | CHAR(2)        | ISO alpha-2 (unique, FK for other tables)    |
| iso3           | CHAR(3)        | ISO alpha-3 (unique)                         |
| numeric_code   | CHAR(3)        | ISO numeric                                  |
| region         | VARCHAR(64)    | UN region (e.g., Europe)                     |
| subregion      | VARCHAR(64)    | UN subregion                                 |
| independent    | BOOLEAN        | TRUE if a country, FALSE if territory        |
| status         | VARCHAR(64)    | Assignment status                            |
| enabled        | BOOLEAN        | If available for use in the system           |
| created_at     | TIMESTAMPTZ    | Created timestamp                            |
| updated_at     | TIMESTAMPTZ    | Updated timestamp                            |

- **Purpose:** Universal set for reference, joins, and selection.

---

#### **currency**

| Column      | Type           | Description                       |
|:----------- |:-------------- |:----------------------------------|
| id          | SERIAL         | PK                                |
| code        | VARCHAR(3)     | ISO 4217 code (unique)            |
| name        | VARCHAR(150)   | Currency name                     |
| symbol      | VARCHAR(20)    | Symbol(s)                         |
| minor_unit  | INTEGER        | Decimal places (2 for cents, etc) |
| iso_numeric | VARCHAR(3)     | ISO numeric code                  |
| is_active   | BOOLEAN        | Used in system?                   |
| created_at  | TIMESTAMPTZ    | Created                           |
| updated_at  | TIMESTAMPTZ    | Updated                           |

- **Purpose:** Central reference for all currency use.

---

#### **titles / optional_titles / all_titles (view)**

**titles**:  
_Global set of honorifics (Mr, Mrs, Dr, etc.)_

**optional_titles**:  
_Locale-specific titles, linked to countries (e.g., 'Herr' for Germany)_

**all_titles (view)**:  
_Union of global and localized titles. Each row has a unique prefixed ID ('G-1', 'L-42')._  
- Use `country_code` to filter for country-specific.

```sql
SELECT * FROM all_titles WHERE country_code IS NULL OR country_code = 'GB';
```
- **Purpose:**
    - **titles:** Default, global honorifics
    - **optional_titles:** Local/custom per country
    - **all_titles:** Unified, for easy filtering and UI

---

### 3.2 User & Identity Management

---

#### **user**

| Column       | Type         | Description                    |
|:------------ |:------------ |:------------------------------|
| id           | UUID (PK)    | Primary key                   |
| email        | VARCHAR(255) | User's email                  |
| status       | VARCHAR(20)  | guest, invited, active, etc.  |
| is_verified  | BOOLEAN      | Email verified?               |
| created_at   | TIMESTAMPTZ  | Creation time                 |
| updated_at   | TIMESTAMPTZ  | Updated                       |

- **Purpose:** Canonical user accounts.

---

#### **admin_user**

| Column    | Type      | Description                     |
|:--------- |:--------- |:-------------------------------|
| id        | UUID (PK) | PK                             |
| user_id   | UUID      | FK to user                     |
| role      | VARCHAR   | Admin role (for backoffice)    |
| created_at| TIMESTAMPTZ | Creation time                |

- **Purpose:** Elevated users for system administration.

---

#### **user_auth**

| Column                | Type         | Description                          |
|:--------------------- |:------------ |:-------------------------------------|
| user_id               | UUID (PK)    | FK to user                           |
| password_hash         | TEXT         | Hashed password                      |
| auth_method           | VARCHAR(50)  | e.g. email, oauth_google, sms        |
| mfa_secret            | TEXT         | Multi-factor auth secret             |
| last_login_at         | TIMESTAMPTZ  | Last login time                      |
| password_reset_token  | TEXT         | Token for password reset             |
| password_reset_expiry | TIMESTAMPTZ  | Expiry of reset token                |

- **Purpose:** Authentication data, password management, and MFA.

---

#### **user_profile**

| Column         | Type         | Description                                        |
|:-------------- |:------------ |:---------------------------------------------------|
| user_id        | UUID (PK)    | FK to user                                         |
| title_full_id  | VARCHAR(8)   | Reference to `all_titles` (e.g., 'G-1', 'L-42')    |
| first_name     | VARCHAR(100) | User’s first name                                  |
| last_name      | VARCHAR(100) | User’s last name                                   |
| phone          | VARCHAR(20)  | User’s phone number                                |
| language       | VARCHAR(10)  | Preferred language                                 |
| avatar_url     | TEXT         | URL to avatar image                                |

- **Purpose:** Display/profile data for users.
- **Note:** `title_full_id` is not a foreign key but should match a value in the `all_titles` view.

---

#### **Role-Based Access Control (RBAC)**

- **role**
    - role types and description
- **user_to_role**
    - user-role assignments (optionally scoped by client)
- **permission**
    - action codes (e.g. 'can_view_balance')
- **role_to_permission**
    - links permissions to roles
- **access**
    - modules or UI features (e.g. 'admin_dashboard')
- **role_to_access**
    - links accesses to roles
- **user_access_override**
    - per-user overrides

**Sample: How to find all users with a certain role (e.g. 'sys_admin'):**

    SELECT u.email
    FROM "user" u
    JOIN user_to_role ur ON ur.user_id = u.id
    JOIN role r ON r.id = ur.role_id
    WHERE r.code = 'sys_admin';

---

- **Purpose:**  
    - Role/permission system is flexible and extensible for both global and context-specific access control.

---

### 3.3 Address System

---

#### **address**

| Column            | Type           | Description                                 |
|:----------------- |:-------------- |:--------------------------------------------|
| id                | UUID (PK)      | Primary key                                 |
| address_line_1    | TEXT           | Main street address                         |
| address_line_2    | TEXT           | Secondary info (apt, suite, etc.)           |
| city              | VARCHAR(100)   | City, town, or village                      |
| region            | VARCHAR(100)   | State, province, or department              |
| postal_code       | VARCHAR(20)    | ZIP or postcode                             |
| country_code      | CHAR(2)        | FK to `country` (iso2)                      |
| latitude          | DOUBLE         | Geolocation (optional)                      |
| longitude         | DOUBLE         | Geolocation (optional)                      |
| notes             | TEXT           | Delivery notes or clarifications            |
| is_active         | BOOLEAN        | For logical deletion/history                |
| created_at        | TIMESTAMPTZ    | Created timestamp                           |
| updated_at        | TIMESTAMPTZ    | Updated timestamp                           |

- **Purpose:** Canonical, normalized address record. Suitable for all entity types.

---

#### **address_type**

| Column      | Type          | Description                                   |
|:----------- |:------------- |:----------------------------------------------|
| id          | SERIAL (PK)   | Primary key                                   |
| code        | VARCHAR(50)   | Unique code (e.g., 'registered', 'delivery')  |
| label       | VARCHAR(100)  | Display name                                  |
| description | TEXT          | Optional description                          |
| is_unique   | BOOLEAN       | Only one active of this type per entity?      |

- **Purpose:** Predefined address "roles" (residential, delivery, etc.)

---

#### **address_link**

| Column          | Type         | Description                                 |
|:--------------- |:------------ |:--------------------------------------------|
| id              | BIGSERIAL PK | Primary key                                 |
| entity_type     | VARCHAR(50)  | Polymorphic type (e.g., 'user', 'client')   |
| entity_id       | UUID         | ID of the entity                            |
| address_id      | UUID         | FK to address                               |
| address_type_id | INT          | FK to address_type                          |
| is_active       | BOOLEAN      | Active link?                                |
| linked_at       | TIMESTAMPTZ  | When the link was made                      |

- **Purpose:**  
    - Links any entity (user, client, etc.) to addresses of various types.
    - Allows for multiple addresses per entity, and multiple types per address.

---

**Usage Example:**  
_To get all addresses for a client:_

    SELECT a.*
    FROM address a
    JOIN address_link al ON al.address_id = a.id
    WHERE al.entity_type = 'client' AND al.entity_id = '<client_id>';

---

### 3.4 Client & Organization

---

#### **client**

| Column      | Type         | Description                                            |
|:----------- |:------------ |:------------------------------------------------------|
| id          | UUID (PK)    | Primary key                                           |
| type        | VARCHAR(50)  | 'personal' or 'organization'                          |
| subtype_id  | INTEGER      | FK to `organization_subtype` (only for organizations) |
| name        | VARCHAR(255) | Display/legal name                                    |
| created_at  | TIMESTAMPTZ  | Created timestamp                                     |
| updated_at  | TIMESTAMPTZ  | Updated timestamp                                     |

- **Purpose:** Root entity for both individuals and organizations.
- **Note:** Trigger ensures subtype_id is only set for organizations, never personals.

---

#### **organization_subtype**

| Column       | Type         | Description                                    |
|:------------ |:------------ |:-----------------------------------------------|
| id           | SERIAL (PK)  | Primary key                                    |
| name         | VARCHAR(100) | e.g. 'limited_company', 'charity'              |
| label        | VARCHAR(100) | Human-friendly label                           |
| description  | TEXT         | Description                                    |
| allowed_type | VARCHAR(50)  | e.g. 'organization'                            |

- **Purpose:** Defines subtypes for organizations (not used for personals).

---

#### **organization_profile**

| Column                     | Type           | Description                       |
|:-------------------------- |:-------------- |:----------------------------------|
| id                         | BIGSERIAL (PK) | Primary key                       |
| client_id                  | UUID           | FK to client                      |
| legal_name                 | VARCHAR(255)   | Registered legal name             |
| registration_identifier    | VARCHAR(100)   | e.g., VAT, CUIT, TIN, ABN         |
| registration_identifier_type | VARCHAR(50)  | e.g., 'VAT', 'TIN', 'EIN'         |
| incorporation_date         | DATE           | Incorporation date                |
| industry                   | VARCHAR(100)   | Industry type                     |
| website                    | VARCHAR(255)   | Website                           |
| phone                      | VARCHAR(50)    | Phone                             |
| email                      | VARCHAR(255)   | Email                             |
| created_at                 | TIMESTAMPTZ    | Created timestamp                 |
| updated_at                 | TIMESTAMPTZ    | Updated timestamp                 |

- **Purpose:** Organization-specific extension with legal and registration info.

---

#### **charity_profile**

| Column               | Type         | Description                     |
|:-------------------- |:------------ |:--------------------------------|
| client_id            | UUID (PK)    | FK to client                    |
| mission_statement    | TEXT         | Mission statement               |
| funding_sources      | TEXT         | Main funding sources            |
| governing_body       | VARCHAR(255) | Governing body                  |
| registered_charity_no| VARCHAR(100) | Official charity number         |
| created_at           | TIMESTAMPTZ  | Created timestamp               |
| updated_at           | TIMESTAMPTZ  | Updated timestamp               |

- **Purpose:** Optional charity-specific extension, only for certain subtypes.

---

#### **business_profile**

| Column         | Type           | Description                |
|:-------------- |:-------------- |:--------------------------|
| client_id      | UUID (PK)      | FK to client              |
| industry       | VARCHAR(100)   | Industry type             |
| num_employees  | INT            | Number of employees       |
| annual_revenue | NUMERIC(15,2)  | Annual revenue            |
| vat_number     | VARCHAR(100)   | VAT number                |
| created_at     | TIMESTAMPTZ    | Created timestamp         |
| updated_at     | TIMESTAMPTZ    | Updated timestamp         |

- **Purpose:** Optional business-specific extension for organizations.

---

**Summary of relationships:**

- Each `client` can be a person or organization.
- Organizations can have:
    - A subtype (`organization_subtype`)
    - An organization profile (`organization_profile`)
    - Optionally, a `charity_profile` and/or `business_profile` for more data.

---

### 3.5 Wallet & Finance

---

#### **wallet**

| Column     | Type        | Description                 |
|:---------- |:----------- |:---------------------------|
| id         | UUID (PK)   | Primary key                |
| client_id  | UUID        | FK to client               |
| created_at | TIMESTAMPTZ | Created timestamp          |

- **Purpose:** Represents a wallet (account) for a client (can be individual or organization).

---

#### **wallet_balance**

| Column     | Type        | Description                         |
|:---------- |:----------- |:------------------------------------|
| id         | UUID (PK)   | Primary key                         |
| wallet_id  | UUID        | FK to wallet                        |
| currency   | VARCHAR(3)  | FK to currency (code)               |
| amount     | NUMERIC(18,4) | Current wallet balance ("pot")     |
| updated_at | TIMESTAMPTZ | Updated timestamp                   |

- **Purpose:** Tracks current balance per wallet per currency.
- **Note:** Always reflects the latest, authoritative amount.

---

#### **transaction**

| Column        | Type          | Description                                    |
|:------------- |:------------- |:-----------------------------------------------|
| id            | UUID (PK)     | Primary key                                    |
| wallet_id     | UUID          | FK to wallet                                   |
| user_id       | UUID          | FK to user (who caused the txn)                |
| currency      | VARCHAR(3)    | FK to currency (code)                          |
| amount        | NUMERIC(18,4) | Can be positive or negative                    |
| type          | VARCHAR(20)   | Transaction type (top_up, payment, refund, etc.)|
| reference_id  | UUID          | Optional FK to related top_up/payment/etc.     |
| created_at    | TIMESTAMPTZ   | Created timestamp                             |

- **Purpose:** Immutable audit trail for all money movements.
- **Note:** You can always reconstruct `wallet_balance` from all `transaction` rows.

---

#### **wallet_authorization**

| Column                | Type          | Description                                    |
|:--------------------- |:------------- |:-----------------------------------------------|
| id                    | UUID (PK)     | Primary key                                    |
| wallet_id             | UUID          | FK to wallet                                   |
| currency              | VARCHAR(3)    | FK to currency (code)                          |
| amount                | NUMERIC(18,4) | Positive = amount held (pending auth)           |
| status                | VARCHAR(20)   | AUTHORIZED, CAPTURED, CANCELLED, EXPIRED        |
| internal_ref          | UUID          | Internal Calu reference                         |
| external_request_ref  | VARCHAR(100)  | External (3rd party) request reference          |
| external_response_ref | VARCHAR(100)  | External (3rd party) response reference         |
| expires_at            | TIMESTAMPTZ   | When the hold expires                           |
| created_at            | TIMESTAMPTZ   | Created timestamp                               |

- **Purpose:** Track funds held/reserved but not yet settled.
- **Usage:** Subtract from available balance until settled or released.

---

#### **user_wallet_balance**

| Column     | Type          | Description                         |
|:---------- |:------------- |:------------------------------------|
| id         | UUID (PK)     | Primary key                         |
| wallet_id  | UUID          | FK to wallet                        |
| user_id    | UUID          | FK to user                          |
| currency   | VARCHAR(3)    | FK to currency (code)               |
| amount     | NUMERIC(18,4) | User’s personal balance             |
| updated_at | TIMESTAMPTZ   | Updated timestamp                   |

- **Purpose:** Tracks balance for each user, per wallet and currency (e.g., for joint wallets, staff/child cards).

---

#### **wallet_limit_definitions**

| Column          | Type         | Description                     |
|:--------------- |:------------ |:--------------------------------|
| key             | VARCHAR(100) | Rule code (e.g., 'daily_limit') |
| label           | VARCHAR(100) | UI-friendly name                |
| description     | TEXT         | Explanation of the rule         |
| default_value   | BIGINT       | Suggested default value         |
| default_currency| VARCHAR(3)   | For amount rules, default curr. |

- **Purpose:** Master list of possible wallet/user limits.

---

#### **wallet_limits**

| Column          | Type          | Description                                   |
|:--------------- |:------------- |:----------------------------------------------|
| id              | SERIAL (PK)   | Primary key                                   |
| target_type     | VARCHAR(20)   | user_wallet, client_wallet, or wallet         |
| target_id       | BIGINT        | ID of the target entity                       |
| rule_key        | VARCHAR(100)  | FK to wallet_limit_definitions (rule code)    |
| rule_type       | VARCHAR(30)   | count, amount, frequency, etc.                |
| direction       | VARCHAR(5)    | max, min                                      |
| timeframe       | VARCHAR(10)   | txn, minute, day, week, etc.                  |
| value           | BIGINT        | Value for the rule                            |
| condition_amount| BIGINT        | Applies only if txn >= this amount (optional) |
| currency        | VARCHAR(3)    | FK to currency (optional)                     |
| is_active       | BOOLEAN       | Whether rule is active                        |
| valid_from      | TIMESTAMPTZ   | Start of validity                             |
| valid_until     | TIMESTAMPTZ   | End of validity                               |
| created_at      | TIMESTAMPTZ   | Created timestamp                             |
| updated_at      | TIMESTAMPTZ   | Updated timestamp                             |
| updated_by      | UUID          | FK to admin_user                              |

- **Purpose:** Assigns actual limit rules to wallets or users.
- **Usage:** Enforce and audit financial controls.

---

**Key design notes:**
- **wallet_balance** and **transaction** are always in sync; all money movements are tracked forever.
- **wallet_authorization** prevents over-spending by accounting for pending/held funds.
- **wallet_limits** makes the rules enforceable and flexible per client/user.

---

### 3.6 System Health / Logging

---

#### **admin_action_logs**

| Column        | Type        | Description                                  |
|:------------- |:----------- |:---------------------------------------------|
| id            | UUID (PK)   | Primary key                                  |
| admin_id      | UUID        | FK to admin_user                             |
| action_type   | VARCHAR(100)| e.g. UPDATE_USER, DELETE_CARD, etc.          |
| target_table  | VARCHAR(100)| Name of affected table                       |
| target_id     | INTEGER     | ID of affected row in target table           |
| changes       | JSONB       | JSON before/after state                      |
| ip_address    | INET        | IP address of admin                          |
| user_agent    | TEXT        | Device/browser info                          |
| created_at    | TIMESTAMPTZ | When the action occurred                     |

- **Purpose:** Tracks all admin actions for security, audit, and troubleshooting.

---

#### **job_logs**

| Column       | Type        | Description                                  |
|:------------ |:----------- |:---------------------------------------------|
| id           | UUID (PK)   | Primary key                                  |
| job_type     | VARCHAR(100)| e.g. SendEmail                               |
| payload      | JSONB       | Input payload for the job (if any)           |
| status       | VARCHAR(20) | PENDING, IN_PROGRESS, FAILED, COMPLETED      |
| result       | JSONB       | Result or error details                      |
| started_at   | TIMESTAMPTZ | When the job started                         |
| finished_at  | TIMESTAMPTZ | When the job finished                        |

- **Purpose:** Audit and monitor background/async jobs.

---

#### **user_login_logs**

| Column        | Type        | Description                                  |
|:------------- |:----------- |:---------------------------------------------|
| id            | UUID (PK)   | Primary key                                  |
| user_id       | UUID        | FK to user                                   |
| is_admin      | BOOLEAN     | TRUE if admin login                          |
| ip_address    | INET        | IP address of user                           |
| user_agent    | TEXT        | Device/browser info                          |
| login_method  | VARCHAR(50) | password, otp, oauth, etc.                   |
| success       | BOOLEAN     | Whether the login was successful             |
| created_at    | TIMESTAMPTZ | When login was attempted                     |

- **Purpose:** Track all login attempts for monitoring and security.

---

#### **system_settings**

| Column       | Type         | Description                                   |
|:------------ |:------------ |:----------------------------------------------|
| key          | VARCHAR(100) | Unique setting key (e.g. default_currency)    |
| value        | TEXT         | Value of the setting                          |
| updated_by   | UUID         | FK to admin_user                              |
| updated_at   | TIMESTAMPTZ  | When it was last updated                      |

- **Purpose:** Stores global or environment/system configuration values.

---

#### **system_errors**

| Column        | Type         | Description                                  |
|:------------- |:------------ |:---------------------------------------------|
| id            | UUID (PK)    | Primary key                                  |
| user_id       | UUID         | FK to user (if applicable)                   |
| service       | VARCHAR(100) | Service or subsystem reporting the error      |
| level         | VARCHAR      | ERROR, WARNING, INFO, DEBUG, CRITICAL        |
| message       | TEXT         | Error message                                |
| stack_trace   | TEXT         | Stack trace                                  |
| context       | JSONB        | Additional context info                      |
| occurred_at   | TIMESTAMPTZ  | When the error occurred                      |

- **Purpose:** Persistent log of all system errors for troubleshooting and analytics.

---

#### **business_events**

| Column        | Type         | Description                                  |
|:------------- |:------------ |:---------------------------------------------|
| id            | SERIAL (PK)  | Primary key                                  |
| event_type    | VARCHAR(100) | e.g. UserRegistered, CardIssued              |
| user_id       | UUID         | FK to user                                   |
| reference_id  | UUID         | Related entity ID (order, card, etc.)        |
| data          | JSONB        | Event data payload                           |
| triggered_by  | VARCHAR(50)  | Source: SYSTEM, ADMIN, API, etc.             |
| created_at    | TIMESTAMPTZ  | When the event was recorded                  |

- **Purpose:** Tracks high-level business or domain events for event sourcing, reporting, or analytics.

---

**Key notes:**
- All logs support auditing, compliance, and proactive health monitoring.
- Separation of concerns allows analytics without touching the operational database.
- JSON fields for flexible, future-proof logging and event data.

---

## 4. Triggers, Views & Functions

---

### **set_updated_at** (Trigger Function)

- **Purpose:** Ensures that the `updated_at` column is automatically set to `NOW()` whenever a row is updated.
- **Where Used:** Applied as a trigger on all major tables with an `updated_at` column.
- **Why:** Prevents stale modification timestamps, simplifies change tracking and auditing.

---

### **validate_client_subtype** (Trigger Function)

- **Purpose:** Validates that `client.type` and `client.subtype_id` are consistent:
    - If `type = 'personal'`, then `subtype_id` **must be NULL**
    - If `type = 'organization'`, then `subtype_id` must match a valid organization subtype.
- **Where Used:** Trigger before INSERT/UPDATE on `client`.
- **Why:** Prevents bad data—enforces business rules at the DB level.

---

### **all_titles** (View)

- **Purpose:** Combines global and localized honorifics (titles) into a single, unified view.
- **Structure:**  
    - Rows have a `full_id` like 'G-1' or 'L-42'
    - `country_code` present only for localized titles.
    - `source` column tells whether 'global' or 'local'
- **Usage:**  
    - To fetch all available titles for a given country (or all countries):

        SELECT * FROM all_titles WHERE country_code IS NULL OR country_code = 'GB';

    - Use `full_id` as the reference in the `user_profile` table.

---

### **Other Notes**

- Triggers for `set_updated_at` are applied to:
    - country, currency, user, address, client, organization_profile, charity_profile, business_profile, user_wallet_balance, wallet_limits, system_settings
- If you add new tables with `updated_at`, add this trigger to keep them up-to-date.

---

**Summary:**  
- Triggers and views enforce business rules and simplify code by handling boilerplate in the DB.
- The `all_titles` view enables a flexible, future-proof way to handle internationalization of names and honorifics.

---

## 5. Design Rationale & Notes

---

- **Normalization & Integrity**
    - All reference data is highly normalized (e.g., country, currency, titles) to prevent duplication and support internationalization.
    - Every table that references another entity uses a proper foreign key constraint, enforcing referential integrity.
    - Triggers (like `validate_client_subtype`) guarantee business rules are maintained at the database level, not just in application code.

- **Extensibility**
    - "Extension" tables (e.g., `charity_profile`, `business_profile`) allow new organization/client types without schema changes to the main tables.
    - The role, permission, and access control models are flexible enough for new business modules or granular user roles.

- **Auditability & Security**
    - Every critical event (admin actions, logins, errors, business events) is logged in a structured, queryable, and human-readable way.
    - The transaction model provides an unbroken, immutable financial audit trail—crucial for fintech or compliance-heavy use cases.
    - `user_access_override` enables per-user exceptions on top of the standard role-based access model for fine-grained control.

- **Flexibility**
    - Polymorphic tables like `address_link` let you associate any entity (user, client, organization, etc.) with any number of addresses, each with a type.
    - `wallet` and related tables support multi-user, multi-currency, and multi-purpose finance operations, making it easy to adapt to new products or regulatory needs.
    - JSON fields in logs and events allow flexible storage for evolving requirements without constant schema migrations.

- **Performance & Maintenance**
    - Triggers keep `updated_at` accurate, which helps with efficient incremental syncs and "what changed?" queries.
    - Views like `all_titles` reduce complex join logic in application code and UIs.

- **Developer/Operations Experience**
    - Schema is documented for both devs and analysts, with human-friendly field names and comments.
    - Sample queries and diagrams help with onboarding and day-to-day troubleshooting.

---

**Summary:**  
The Calu schema is built for long-term adaptability, safety, and clarity—helping both developers and non-technical stakeholders understand and trust how data is stored and managed.

---

## 6. Sample Queries

---

**Get all titles for a user in France (country code 'FR'):**

    SELECT * FROM all_titles
    WHERE country_code IS NULL OR country_code = 'FR';

---

**Fetch all clients with their main wallet balance in GBP:**

    SELECT c.id, c.name, wb.amount
    FROM client c
    JOIN wallet w ON w.client_id = c.id
    JOIN wallet_balance wb ON wb.wallet_id = w.id AND wb.currency = 'GBP';

---

**Find all users with the 'sys_admin' role:**

    SELECT u.email
    FROM "user" u
    JOIN user_to_role ur ON ur.user_id = u.id
    JOIN role r ON r.id = ur.role_id
    WHERE r.code = 'sys_admin';

---

**List all failed login attempts in the past day:**

    SELECT *
    FROM user_login_logs
    WHERE success = FALSE AND created_at > NOW() - INTERVAL '1 day';

---

**Transactions above £500 for a given wallet in GBP:**

    SELECT *
    FROM transaction
    WHERE wallet_id = '<wallet_id>'
      AND currency = 'GBP'
      AND amount >= 500;

---

**All active wallet limits for a client:**

    SELECT wl.*
    FROM wallet_limits wl
    JOIN wallet w ON wl.target_id = w.id
    WHERE wl.target_type = 'wallet'
      AND w.client_id = '<client_id>'
      AND wl.is_active = TRUE;

---

**Audit all admin actions taken on a specific user:**

    SELECT *
    FROM admin_action_logs
    WHERE target_table = 'user'
      AND target_id = <user_id>;

---

**Latest system errors for a given service:**

    SELECT *
    FROM system_errors
    WHERE service = 'payment'
    ORDER BY occurred_at DESC
    LIMIT 20;

---

**Tip:**  
- Replace `<wallet_id>` and `<client_id>` with real IDs when testing.
- Queries use standard SQL and are compatible with PostgreSQL.

---
