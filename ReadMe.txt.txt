# How to test and develop

# Step 1 - create the folder to house your firewall log files
sudo mkdir /lmfao/powershell/data -p
sudo mkdir /lmfao/golang/data -p
sudo mkdir /lmfao/mariadb/data -p

# Step 2 - Create network for all of this to talk in
# create a netwok
sudo docker network create lmfao-network

# Step 2.5  pull powershell
sudo docker pull mcr.microsoft.com/powershell
sudo docker run -it --rm --network lmfao-network -v /lmfao/powershell/data:/data --name powershell-console mcr.microsoft.com/powershell

# Step 3 - pull the golang container, then start it while mounting the data dir
sudo docker pull golang
sudo docker run --rm --name golang -v /lmfao/golang/data:/data -it golang

# Step 4 - start the mariadb instance that we will use to store the data
sudo docker pull mariadb
# Stert the container in headless mode
sudo docker run --name mariadb --rm --detach --network lmfao-network -v /lmfao/mariadb/data:/data --env MARIADB_USER=lmfao-user --env MARIADB_PASSWORD=my_cool_secret --env MARIADB_ROOT_PASSWORD=my-secret-pw mariadb

# Start another container in interactive mode to run SQL statements as needed
#sudo docker run -it --network lmfao-network --name mariadb-console --rm mariadb mysql -hmariadb -ulmfao-user -p
# PASSWORD TO USE ABOVE WHEN LOGGING IN IS my_cool_secret

sudo docker run -it --network lmfao-network --name mariadb-console --rm mariadb mysql -hmariadb -uroot -p
# PASSWORD TO USE ABOVE WHEN LOGGING IN IS my-secret-pw
# to get shell access to the mariadb container to pull logs, etc run: docker exec -it mariadb bash

# Step 5 - Create the database that we will be using
CREATE DATABASE lmfao;
use lmfao;
create table ipv4(
   ipv4_id INT NOT NULL AUTO_INCREMENT,
   ipv4_address VARCHAR(100) NOT NULL,
   rfc1918 bool NOT NULL,
   PRIMARY KEY ( ipv4_id )
);
create table ipv6(
   ipv6_id INT NOT NULL AUTO_INCREMENT,
   ipv6_address VARCHAR(100) NOT NULL,
   rfc1918 bool NOT NULL,
   PRIMARY KEY ( ipv6_id )
);
create table transaction(
   trans_id INT NOT NULL AUTO_INCREMENT,
   src_ip_id INT NULL,
   dst_ip_id INT NULL,
   datetime datetime NOT NULL,
   action VARCHAR(100) NOT NULL,
   protocol VARCHAR(100) NOT NULL,
   srcport VARCHAR(100) NOT NULL,
   dstport VARCHAR(100) NOT NULL,
   path VARCHAR(100) NOT NULL,
   PRIMARY KEY ( trans_id ),
   index trans_search_ip (src_ip_id, dst_ip_id),
   index trans_search_dstip (dst_ip_id),
   index trans_search_ip_proto (src_ip_id, dst_ip_id, protocol),
   index trans_search_ip_ports (src_ip_id, dst_ip_id, srcport, dstport),
   index trans_search_ports (srcport, dstport),
   index trans_search_dstport (dstport)
);
GRANT ALL PRIVILEGES ON lmfao TO 'lmfao-user';
SYSTEM mysql -u 'lmfao-user' -p