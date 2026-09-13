# Developer Documentation

This document explains how to set up, build, and work on the Inception project from a development standpoint.

## Setting up the environment from scratch

### Prerequisites

- A Linux VM (Debian or Alpine-based, matching the penultimate stable release, per the subject's requirements).
- Docker and Docker Compose installed on the VM.
- Your 42 login's domain (`hmouis.42.fr`) resolving to the VM's local IP — either via `/etc/hosts` on the client machine or local DNS.

### Repository layout

```
.
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── credentials.txt
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── wordpress/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

### Configuration files

- **`srcs/.env`** — holds non-sensitive configuration read by `docker-compose.yml`. At minimum:
  ```
  DOMAIN_NAME=hmouis.42.fr
  MYSQL_DATABASE=wordpress
  MYSQL_USER=wp_user
  DB_HOST=mariadb
  WP_TITLE=Inception
  WP_ADMIN_USER=<non-admin-username>
  WP_ADMIN_EMAIL=admin@hmouis.42.fr
  WP_USER=<secondary-username>
  WP_USER_EMAIL=user@hmouis.42.fr
  ```
  Note: `WP_ADMIN_USER` must not contain `admin`/`administrator` in any casing, per the subject's requirements.

- **`secrets/`** — one file per sensitive value, plain text, no trailing newline issues, referenced by `docker-compose.yml`'s top-level `secrets:` key and mounted into containers at `/run/secrets/<name>`. This is preferred over putting passwords in `.env` directly, since secrets aren't exposed via `docker inspect` and aren't baked into image layers.

Neither `.env` nor `secrets/` contents should be committed to Git with real values — keep them local or provide a `.env.example` / `secrets/*.example` instead.

## Building and launching with the Makefile and Docker Compose

The Makefile is the single entrypoint for all build/run operations — it should never be bypassed with raw `docker` commands during normal development, so that `make` alone is always enough to reproduce the full stack.

```makefile
up:
	@mkdir -p /home/hmouis/data/mariadb /home/hmouis/data/wordpress
	docker compose -f srcs/docker-compose.yml up -d --build

down:
	docker compose -f srcs/docker-compose.yml down

clean: down
	docker compose -f srcs/docker-compose.yml down --rmi all -v

fclean: clean
	sudo rm -rf /home/hmouis/data/mariadb/*
	sudo rm -rf /home/hmouis/data/wordpress/*

re: fclean up

.PHONY: up down clean fclean re
```

Key points for anyone modifying this:

- The host data directories (`/home/hmouis/data/mariadb`, `/home/hmouis/data/wordpress`) must exist **before** `docker compose up`, since Docker won't create a bind-mount target directory automatically — it will fail with a "no such file or directory" mount error instead.
- Each service's `Dockerfile` is called directly by `docker-compose.yml` (via `build: context: ./requirements/<service>`), never a pre-built image — pulling from Docker Hub for anything other than the Alpine/Debian base image is against the subject's rules.

## Managing containers and volumes

Common day-to-day commands:

```bash
# Rebuild a single service after editing its Dockerfile or scripts
docker compose -f srcs/docker-compose.yml up -d --build <service>

# Follow logs live
docker logs -f <container>

# Shell into a running container
docker exec -it <container> bash

# List named volumes and confirm host paths
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data

# Check container restart/health status
docker compose -f srcs/docker-compose.yml ps
```

If a container is stuck in a restart loop, `docker logs <container>` will show the point of failure from the last crash — this is the fastest way to diagnose startup script issues (e.g. database not ready, missing directories, wrong file permissions).

## Where project data is stored and how it persists

Two named volumes are defined in `docker-compose.yml`, each using the `local` driver with bind-mount `driver_opts` so Docker manages them as proper named volumes while still pinning their storage location on the host:

```yaml
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/hmouis/data/mariadb

  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/hmouis/data/wordpress
```

- **`mariadb_data`** is mounted at `/var/lib/mysql` inside the `mariadb` container — this is the actual database (tables, users, grants). It's shared with no other container.
- **`wordpress_data`** is mounted at `/var/www/html` in **both** the `wordpress` and `nginx` containers — WordPress writes site files (core, themes, plugins, uploads) here, and NGINX needs read access to the same files to serve static assets directly (see the `try_files` directive in the NGINX config).

Because both volumes point at real host directories under `/home/hmouis/data`, all data survives `docker compose down` and container rebuilds — it's only lost if the underlying host directories are explicitly deleted (as `make fclean` does intentionally).

Startup scripts (`mariadb.sh`, `wordpress.sh`) check for existing data on these volumes before re-running first-time initialization (`mariadb-install-db`, `wp core install`, etc.), so restarting the stack against existing volumes is idempotent and won't re-download or re-provision anything already in place.
