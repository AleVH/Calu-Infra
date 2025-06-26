# Base Schema Overview

## Introduction

This document explains the structure, key relationships, and main usage patterns for the base schema, targeting developers and data engineers new to PostgreSQL or relational design.

---

## ID Types: UUID vs SERIAL

- **UUID (Universally Unique Identifier)**
  - Used as primary key for main business entities (`user`, `client`, `admin_user`, `wallet`, etc.).
  - Ensures global uniqueness, is secure (hard to guess), and safe for distributed/microservice architectures.
  - In the schema, UUIDs are usually generated automatically with `DEFAULT gen_random_uuid()`.

- **SERIAL**
  - Auto-incrementing integer, used mainly for lookup/reference tables or system-controlled enumerations.
  - Good for simple, internal tables where uniqueness across systems isn’t needed.
  - Example: `country.id`, `titles.id`, `role.id`.

---

## Major Entities and Relationships

### 1. User & Admins

- **user**
  - Core identity for anyone in the system (clients, admins, etc.).
  - `id` is UUID, all related data references this PK.

- **admin_user**
  - Specialization of user for admin purposes.
  - Links to `user(id)` via FK (`user_id UUID UNIQUE NOT NULL REFERENCES "user"(id)`).
  - Allows tracking of admin-specific actions and roles without duplicating data.

- **user_auth**, **user_profile**
  - Store authentication and profile details for each user.
  - Both reference `user(id)` with PK+FK pattern (`user_id UUID PRIMARY KEY REFERENCES "user"(id)`).

### 2. Roles, Permissions, and Access

- **role**, **permission**, **access**
  - Internal lookup tables using SERIAL PKs.
  - Map roles to permissions and access via join tables (`role_to_permission`, `role_to_access`).

- **user_to_role**
  - Assigns roles to users; references UUID user and integer role.

### 3. Address System

- **address**
  - Stores address details; uses UUID PK.

- **address_link**
  - Connects addresses to entities (user, client, etc.) via `entity_type` (string) and `entity_id` (UUID).
  - Allows multiple types of entities to be linked to addresses flexibly.

### 4. Client, Organization, Wallet

- **client**
  - Represents either a personal or organizational client.
  - Uses UUID PK.

- **organization_profile, charity_profile, business_profile**
  - Extra details for organizations, charities, and businesses (one-to-one with client via UUID FK).

- **wallet**
  - Each wallet is linked to a client (`client_id` UUID).
  - All wallet-related tables use UUIDs for relationships and auditing.

- **wallet_balance, transaction, wallet_authorization, user_wallet_balance**
  - Track balances, transactions, and reserved amounts.
  - All reference the relevant wallet and user/client by UUID.

### 5. System Health, Logging, and Settings

- **admin_action_logs**
  - Records all admin actions; references admin_user (UUID).

- **job_logs**
  - Tracks asynchronous/background jobs.

- **user_login_logs**
  - Records all login attempts (for users and admins).

- **system_errors**
  - Stores application errors with severity (`level` as ENUM), service context, and reference to user.

- **system_settings**
  - Stores key/value system settings with admin tracking.

---

## Use and Best Practices

- **UUIDs for main business tables** ensure global uniqueness and safe referencing, especially in distributed systems.
- **SERIAL for internal tables** (enums, status types, static data) keeps lookups lightweight and fast.
- **All FK references match PK types**—critical for avoiding Postgres errors.
- **Triggers and audit fields** (`updated_at` with `set_updated_at()` trigger) ensure modification times are always tracked.
- **Seed data** uses `ON CONFLICT (...) DO NOTHING` to allow safe, repeatable inserts.

---

## Example Usage

- **Add a new user:**
  ```sql
  INSERT INTO "user" (email, status, is_verified)
  VALUES ('newuser@email.com', 'active', TRUE);
