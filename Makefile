NAME		= inception

COMPOSE		= docker compose -f srcs/docker-compose.yml

all: up

up:
		@mkdir -p /home/hmouis/data/mariadb /home/hmouis/data/wordpress
	   	docker compose -f srcs/docker-compose.yml up -d --build

down:
	$(COMPOSE) down --volumes

start:
	$(COMPOSE) start

restart:
	$(COMPOSE) down
	$(COMPOSE) up -d --build

build:
	$(COMPOSE) build

clean:
	$(COMPOSE) down --rmi all 

fclean: down clean
	sudo rm -rf /home/hmouis/data

re:
	$(MAKE) fclean
	$(MAKE) all

.PHONY: all up down stop start restart logs ps build clean fclean re