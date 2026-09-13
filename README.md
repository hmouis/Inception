*This project has been created as part of the 42 curriculum by hmouis.*

# Inception

## Description

Inception is a system administration project that consists of building a small, containerized web infrastructure using Docker and Docker Compose, from scratch, inside a personal virtual machine.

The goal is to deploy a working WordPress website behind an NGINX reverse proxy, backed by a MariaDB database, with every service running in its own dedicated, custom-built container — no pre-made Docker Hub images, no `latest` tags, and no shortcuts like `network: host` or infinite-loop hacks (`tail -f`, `sleep infinity`, etc.) to keep containers alive.

At a high level, the stack looks like:

```
        Internet (port 443, TLS only)
               │
           ┌───▼────┐
           │ NGINX  │  (TLSv1.2 / TLSv1.3, sole entrypoint)
           └───┬────┘
               │ fastcgi (port 9000)
           ┌───▼──────┐
           │ WordPress│  (php-fpm)
           └───┬──────┘
               │ mysql (port 3306)
           ┌───▼──────┐
           │ MariaDB  │
           └──────────┘
```

Each service is built from its own `Dockerfile`, runs in its own container on a dedicated Docker network, and persists its data through named volumes stored on the host at `/home/hmouis/data`.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker and Docker Compose installed.
- Your domain `hmouis.42.fr` pointing to the VM's local IP (add an entry to `/etc/hosts` on the machine you're browsing from, or configure DNS accordingly).

### Setup

1. Clone the repository.
2. Fill in the `.env` file at the root of `srcs/` with your own values (database name, users, domain, etc.) — see `DEV_DOC.md` for the full list of required variables.
3. If using Docker secrets (recommended for passwords), populate the files under `secrets/` (e.g. `db_password.txt`, `db_root_password.txt`, `credentials.txt`).

### Build & run

From the root of the repository:

```bash
make
```

This builds all Docker images from their Dockerfiles and starts the full stack via `docker-compose.yml`.

Other available targets:

```bash
make down     # stop and remove containers
make clean    # stop containers and remove images/volumes
make fclean   # full clean, including host data directories
make re       # fclean + up
```

See `USER_DOC.md` and `DEV_DOC.md` for full day-to-day usage and development details.

## Project description: Docker design choices

### Virtual Machines vs Docker

A virtual machine virtualizes an entire hardware stack and runs a full guest operating system on top of a hypervisor — heavy on disk space, memory, and boot time, but fully isolated at the kernel level. Docker containers, by contrast, share the host machine's kernel and only isolate the process, filesystem, and network namespace of the application itself. This makes containers dramatically lighter and faster to start, at the cost of slightly weaker isolation than a full VM. This project runs multiple Docker containers *inside* a single VM: the VM provides the outer isolation boundary required by the subject, while Docker provides fast, reproducible, per-service isolation within it.

### Secrets vs Environment Variables

Environment variables (via `.env` and `docker-compose.yml`'s `environment:` key) are simple and widely supported, but they leak fairly easily — they show up in `docker inspect`, in process listings inside the container, and in image layer history if not handled carefully. Docker secrets are mounted as files inside the container's filesystem (under `/run/secrets/`) at runtime only, are never baked into the image, and aren't exposed through `docker inspect`. In this project, non-sensitive configuration (domain name, database name, usernames) is passed via `.env`/environment variables, while actual passwords (`MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, WordPress admin credentials) are provided as Docker secrets.

### Docker Network vs Host Network

`network: host` makes a container share the host's network namespace directly — no isolation, and every container would compete for the same ports. This project instead defines a dedicated bridge network (`inception`) in `docker-compose.yml`. Containers on this network resolve each other by service name (e.g. `wordpress` reaches MariaDB at host `mariadb`), and only NGINX exposes a port to the host (443), keeping WordPress and MariaDB unreachable from outside the Docker network entirely.

### Docker Volumes vs Bind Mounts

A bind mount maps an arbitrary host path directly into a container, with no involvement from Docker's volume management (no `docker volume ls`, no built-in driver options). A named volume is managed by Docker itself, and can still be configured to physically store its data at a specific host path via the `local` driver's bind `driver_opts`, while remaining a first-class, Docker-managed volume. This project uses named volumes (`mariadb_data`, `wordpress_data`) configured with `driver_opts` to store their data under `/home/hmouis/data`, satisfying both the subject's requirement for named volumes and the requirement that data live at a specific host path.

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [NGINX documentation](https://nginx.org/en/docs/)
- [MariaDB knowledge base](https://mariadb.com/kb/en/)
- [WP-CLI documentation](https://wp-cli.org/)
- [PHP-FPM documentation](https://www.php.net/manual/en/install.fpm.php)

### AI usage

AI (Claude) was used throughout this project as a debugging and explanation aid, not as a source of copy-pasted, unreviewed code:

- Diagnosing container startup races (e.g. MariaDB's socket/auth-plugin behavior after `ALTER USER`, PHP-FPM listening on a Unix socket vs TCP, NGINX 502 errors from a misconfigured `fastcgi_pass`).
- Explaining NGINX `location` block matching order and `try_files` fallback behavior for WordPress permalinks.
- Reviewing entrypoint scripts (`mariadb.sh`, `wordpress.sh`, `nginx.sh`) for PID 1 / daemon best practices, in line with the subject's requirement to avoid `tail -f`-style hacks.
- Cross-checking the subject PDF against the current setup (e.g. whether a MariaDB root password is required, Docker secrets vs `.env` usage) to catch requirements that were easy to miss.

Every suggested fix was tested against real container logs before being adopted, and the reasoning behind each fix (not just the fix itself) was worked through so it could be explained and defended during evaluation.
