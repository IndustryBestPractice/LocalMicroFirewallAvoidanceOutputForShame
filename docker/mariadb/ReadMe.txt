# https://hub.docker.com/_/mariadb

docker network create mariadb-network
sudo docker run --name mariadb --rm --detach --network mariadb-network --env MARIADB_USER=example-user --env MARIADB_PASSWORD=my_cool_secret --env MARIADB_ROOT_PASSWORD=my-secret-pw mariadb
docker run -it --network mariadb-network --name mariadb-console --rm mariadb mysql -hmariadb -uexample-user -p
# PASSWORD TO USE ABOVE WHEN LOGGING IN IS my_cool_secret
# to get shell access to the mariadb container to pull logs, etc
docker exec -it mariadb bash

# To run just a quick test
docker network create mariadb-network
docker run -it --network mariadb-network --rm mariadb mysql -hsome-mariadb -uexample-user -p

docker exec -it mariadb bash
