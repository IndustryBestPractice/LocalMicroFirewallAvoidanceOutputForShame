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

docker run -it --network lmfao-network -v /lmfao/mariadb/data:/data --name mariadb-console --rm mariadb mysql -hmariadb -uroot -p
# PASSWORD TO USE ABOVE WHEN LOGGING IN IS my-secret-pw
# to get shell access to the mariadb container to pull logs, etc run: docker exec -it mariadb bash

# Step 5 - Create the database that we will be using
CREATE DATABASE lmfao;
use lmfao;
# PASSWORD TO USE ABOVE WHEN LOGGING IN IS my-secret-pw
create table ip_address(
   ip_id INT NOT NULL AUTO_INCREMENT,
   ip_version VARCHAR(4) NOT NULL,
   ip_address VARCHAR(100) NOT NULL,
   is_local bool NOT NULL,
   PRIMARY KEY ( ip_id ),
   index ip_address_version_search (ip_version, ip_address, is_local),
   index ip_address_search (ip_address)
);
create table transaction(
   trans_id INT NOT NULL AUTO_INCREMENT,
   src_ip_id INT NULL,
   dst_ip_id INT NULL,
   date date NOT NULL,
   time time NOT NULL,
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

create table stage_incoming(
srcipinternal BOOL NOT NULL,
dstipinternal BOOL NOT NULL,
srcipver VARCHAR(4) NOT NULL,
dstipver VARCHAR(4) NOT NULL,
date DATE NOT NULL,
time TIME NOT NULL,
action VARCHAR(20) NOT NULL,
protocol VARCHAR(3) NOT NULL,
srcip VARCHAR(100) NOT NULL,
dstip VARCHAR(100) NOT NULL,
srcport INT NOT NULL,
dstport INT NOT NULL,
size INT NOT NULL,
tcpflags VARCHAR(100) NOT NULL,
tcpsyn VARCHAR(100) NOT NULL,
tcpack VARCHAR(100) NOT NULL,
tcpwin VARCHAR(100) NOT NULL,
icmptype VARCHAR(100) NOT NULL,
icmpcode VARCHAR(100) NOT NULL,
info VARCHAR(100) NOT NULL,
path VARCHAR(100) NOT NULL
);
GRANT ALL PRIVILEGES ON lmfao TO 'lmfao-user';
SYSTEM mysql -u 'lmfao-user' -p

# https://stackoverflow.com/questions/58576129/importing-csv-file-into-mysql-docker-container
LOAD DATA LOCAL INFILE '/data/52fdfc07-2182-654f-163f-5f0f9a621d72_send_data.csv' 
INTO TABLE stage_incoming
FIELDS TERMINATED BY ',' 
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

# Get unique addresses from staging table into ip_address table
insert into ip_address (ip_version, ip_address, is_local) select unique a.ip_version, a.ip_address, a.is_local from (select srcipver as ip_version, srcip as ip_address, srcipinternal as is_local from stage_incoming UNION ALL select dstipver as ip_version, dstip as ip_address, dstipinternal as is_local from stage_incoming) a where a.ip_address not in (select ip_address from ip_address);

# Get info for each interaction into the main transaction table
insert into transaction (src_ip_id, dst_ip_id, date, time, action, protocol, srcport, dstport, path)
select ia1.ip_id as src_ip_id , ia2.ip_id as dst_ip_id, si.date as date, si.time as time, si.action as action, si.protocol as protocol, si.srcport as srcport, si.dstport as dstport, si.path as path from stage_incoming si
join ip_address ia1 on
si.srcip = ia1.ip_address
and si.srcipver = ia1.ip_version
and si.srcipinternal = ia1.is_local
join ip_address ia2 on
si.dstip = ia2.ip_address
and si.dstipver = ia2.ip_version
and si.dstipinternal = ia2.is_local;

# Query intelligable transaction data
select
ia1.ip_address as src_ip,
ia2.ip_address as dst_ip,
t.date,
t.time,
t.action,
t.protocol,
t.srcport,
t.dstport,
t.path
from transaction t
join ip_address ia1 on
t.src_ip_id = ia1.ip_id
join ip_address ia2 on
t.dst_ip_id = ia2.ip_id
order by date asc, time asc
limit 1;