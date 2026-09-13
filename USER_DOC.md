# User Documentation

This document explains how to use the Inception stack once it has been built and started — no development knowledge required.

## What services does the stack provide?

The stack is made up of three containers working together:

| Container  | Role                                                                 |
|------------|-----------------------------------------------------------------------|
| `nginx`    | The only entrypoint to the whole site. Handles HTTPS (TLSv1.2/1.3) on port 443 and forwards PHP requests to WordPress. |
| `wordpress`| Runs the WordPress site itself via PHP-FPM (no web server of its own). |
| `mariadb`  | Stores all WordPress data — posts, pages, users, settings — in a MySQL-compatible database. |

All three run on a private Docker network and only NGINX is reachable from outside the machine.

## Starting and stopping the project

From the root of the repository:

```bash
# Start everything (builds images if needed)
make

# Stop all containers (keeps data)
make down

# Stop containers and remove images/volumes
make clean

# Full reset: stop everything and wipe stored data too
make fclean

# Full reset then rebuild and start
make re
```

Containers are configured to restart automatically if they crash, so under normal use you shouldn't need to intervene once the stack is up.

## Accessing the website

Open a browser and go to:

```
https://hmouis.42.fr
```

You'll see a certificate warning first — this is expected, since the site uses a self-signed TLS certificate generated locally rather than one issued by a public certificate authority. Accept/continue past the warning to reach the site.

> The site is **only** reachable over HTTPS on port 443. Plain `http://` requests are not served by this stack.

## Accessing the administration panel

The WordPress admin panel is available at:

```
https://hmouis.42.fr/wp-admin
```

Log in with the administrator account credentials (see below for where to find them).

## Locating and managing credentials

Credentials are never hardcoded in the source files. They live in one of two places:

- **`srcs/.env`** — non-sensitive configuration (domain name, database name, usernames).
- **`secrets/`** (at the repository root) — sensitive values, one per file:
  - `credentials.txt` — WordPress admin/user credentials
  - `db_password.txt` — MariaDB application user password
  - `db_root_password.txt` — MariaDB root password

If you need to reset the admin password, the cleanest way is to update the relevant secret file and rebuild the `wordpress` container (`docker compose up -d --build wordpress`) — WordPress will need this to happen before its first-time setup, since re-running install on an already-provisioned site won't automatically pick up a changed password.

> Do **not** commit the `secrets/` folder's actual contents to Git — only commit a template/example if needed. Real credentials must stay local.

## Checking that services are running correctly

Check container status at a glance:

```bash
docker compose -f srcs/docker-compose.yml ps
```

All three containers should show a state of `Up`.

Check logs for a specific service if something looks wrong:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

What healthy output looks like:

- **mariadb**: ends with `mysqld: ready for connections.` and stays quiet afterward — no repeated restarts or error loops.
- **wordpress**: shows `WordPress is ready!` (or similar) after connecting to the database, with no PHP errors.
- **nginx**: shows the SSL certificate being generated (first run only) and no repeated crash/restart messages.

If a container keeps restarting, `docker logs <container> --tail 50` will usually show the error from its most recent crash.
