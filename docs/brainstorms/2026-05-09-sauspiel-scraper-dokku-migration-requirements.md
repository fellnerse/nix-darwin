# Sauspiel Scraper: Dokku Deployment & PostgreSQL Migration

**Date:** 2026-05-09
**Status:** Approved for Planning

## Problem & Context
The project was originally intended to be deployed on Render's free tier. However, Render's free tier does not offer persistent ephemeral storage, which is problematic for the current SQLite database setup.

To solve this, the application will be self-hosted on a dedicated Proxmox VM.

## Decisions

### 1. Deployment Platform: Dokku
*   **Why:** Provides a PaaS-like "git push to deploy" experience (similar to Render) but can run on a self-hosted Proxmox VM. It's lightweight, CLI-based, and easy to manage.

### 2. Database: PostgreSQL via Dokku Plugin
*   **Why:** While SQLite can be persisted via volume mounts in Dokku, switching to PostgreSQL provides a more robust, production-ready environment. Dokku's official PostgreSQL plugin makes provisioning and linking the database trivial.

### 3. Data Layer: SQLAlchemy ORM
*   **Why:** To facilitate the move from SQLite to PostgreSQL, the current raw `sqlite3` queries in `repository.py` will be migrated to use an ORM (SQLAlchemy). This abstracts the database engine and provides long-term benefits for schema management and querying.

## Scope Boundaries

### In Scope
*   Updating `pyproject.toml` to include SQLAlchemy and a PostgreSQL driver (e.g., `psycopg2-binary` or `asyncpg`).
*   Refactoring `repository.py` to use SQLAlchemy models instead of raw SQL queries.
*   Ensuring the application can connect to a database via a standard `DATABASE_URL` environment variable (which Dokku will provide).
*   Documenting the necessary Dokku setup commands (app creation, plugin installation, linking).

### Out of Scope
*   Changes to the core scraping logic or UI (unless required by the ORM change).
*   Provisioning the actual Proxmox VM (the user will handle the OS installation).
