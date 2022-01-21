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
   cidr INT NOT NULL DEFAULT 24,
   is_local bool NOT NULL,
   PRIMARY KEY ( ip_id ),
   index ip_address_version_search (ip_version, ip_address, is_local),
   index ip_subnet_search (cidr),
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
insert into ip_address (ip_id=1, ip_version, ip_address, is_local) 
select unique a.ip_version, a.ip_address, a.is_local from 
(select srcipver as ip_version, srcip as ip_address, srcipinternal as is_local 
from stage_incoming 
UNION ALL 
select dstipver as ip_version, dstip as ip_address, dstipinternal as is_local 
from stage_incoming) a 
where a.ip_address not in 
(select ip_address from ip_address);

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

# Setting CIDR defaults
update ip_address set cidr='8' where ip_address like '127.0.%' or ip_address like '10.0.%';
update ip_address set cidr='12' where ip_address like '172.%' and substring(ip_address from 5 for 2) >= 16 and substring(ip_address from 5 for 2) <= 31 and is_local = 1;
update ip_address set cidr='16' where ip_address like '192.168.%' or ip_address like '169.254.%';
update ip_address set cidr='128' where ip_address like '::1%';
update ip_address set cidr='10' where ip_address like'fe80::%';
update ip_address set cidr='7' where ip_address like 'fc00::%';

# Query intelligable transaction data
select
ia1.ip_address as src_ip,
ia1.cidr as src_cidr,
ia2.ip_address as dst_ip,
ia2.cidr as dst_cidr,
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
limit 3;
# Add the below before the "order" statement for local -> local traffic
where ia1.is_local = 1 and ia2.is_local = 1
# below for local -> external traffic
where ia1.is_local = 1 and ia2.is_local = 0
# below for external -> internal traffic
where ia1.is_local = 0 and ia2.is_local = 1

# Create nodes by date
select
concat("[",
group_concat(
concat("{id: '",ia.ip_id,"',"),
concat("label: '",ia.ip_address,"',"),
concat("group: '",ia.cidr,"'}")
)
,"]"
) as json
from (select distinct src_ip_id as ip_id
from transaction
where date = '2020-10-14'
union
select distinct dst_ip_id as ip_id
from transaction
where date = '2020-10-14'
) tbd
join ip_address ia on
ia.ip_id = tbd.ip_id;

# To see the raw data above, not in JSON format:
select
ia.ip_id,
ia.ip_address,
ia.cidr
from (select distinct src_ip_id as ip_id
from transaction
where date = '2020-10-14'
union
select distinct dst_ip_id as ip_id
from transaction
where date = '2020-10-14'
) tbd
join ip_address ia on
ia.ip_id = tbd.ip_id;


# Now we need to create the edges (i.e. the connections between the nodes on this date
select
concat("[",
group_concat(
concat("{from: '",t.src_ip_id,"',"),
concat("to: '",t.dst_ip_id,"'}")
)
,"]"
) as json
from transaction t
where date = '2020-10-14';

# in django, connect to SQL directly
cd /usr/src/lmfao
python3 manage.py shell
from netvis.models import stage_incoming
stage_incoming.objects.create(srcipinternal="1", dstipinternal="1", srcipver="ipv4", dstipver="ipv4", date='2021-12-12', time='00:00:00.000', action="ALLOWED", protocol='TCP', srcport='80', dstport='80', size='123', tcpflags='-', tcpsyn='-', tcpack='-', tcpwin='-', icmptype='-', info='-', path='SEND')
# https://medium.com/@ksarthak4ever/django-models-and-shell-8c48963d83a3

##########
# PYTHON #
##########
import csv, datetime
from netvis.models import stage_incoming

start_time = datetime.datetime.now()

file_path = 'ReplaceMe'
with open(file_path, "r") as csv_file:
    data = csv.reader(csv_file, delimiter=",")
    # Skip the header row
    next(data)
    incoming_events = []
    for row in data:
        event = stage_incoming(srcipinternal=row[0],dstipinternal=row[1],srcipver=row[2],dstipver=row[3],date=row[4],time=row[5],action=row[6],protocol=row[7],srcip=row[8],dstip=row[9],srcport=row[10],dstport=row[11],size=row[12],tcpflags=row[13],tcpsyn=row[14],tcpack=row[15],tcpwin=row[16],icmptype=row[17],icmpcode=row[18],info=row[19],path=row[20])
		incoming_events.append(event)
    stage_incoming.objects.bulk_create(incoming_events)

end_time = datetime.datetime.now()
runtime = end_time - start_time
#https://betterprogramming.pub/3-techniques-for-importing-large-csv-files-into-a-django-app-2b6e5e47dba0
print("Loading CSV took: " + str(runtime) + ".")
##########
# PYTHON #
##########
#django = 4.0
#python3 = 3.9.9

#####################
# PYTHON - LOAD_CSV #
#####################
import csv, datetime, sys
from netvis.models import Stage_Incoming

start_time = datetime.datetime.now()

file_path = 'ReplaceMe'
with open(file_path, "r") as csv_file:
    data = csv.reader(csv_file, delimiter=",")
    # Skip the header row
    next(data)
    incoming_events = []
    for row in data:
        event = Stage_Incoming(srcipinternal=row[0],dstipinternal=row[1],srcipver=row[2],dstipver=row[3],date=row[4],time=row[5],action=row[6],protocol=row[7],srcip=row[8],dstip=row[9],srcport=row[10],dstport=row[11],size=row[12],tcpflags=row[13],tcpsyn=row[14],tcpack=row[15],tcpwin=row[16],icmptype=row[17],icmpcode=row[18],info=row[19],path=row[20])
        incoming_events.append(event)
    Stage_Incoming.objects.bulk_create(incoming_events)

end_time = datetime.datetime.now()
runtime = end_time - start_time
#https://betterprogramming.pub/3-techniques-for-importing-large-csv-files-into-a-django-app-2b6e5e47dba0
print("Loading CSV took: " + str(runtime) + ".")
#####################
# PYTHON - LOAD_CSV #
#####################

======================================================

#cat insert_to_stage_incoming.py | sed -e "s/ReplaceMe/\/usr\/src\/lmfao\/send_data.csv/g" | python3 manage.py shell
sed -i.bak "s/,-/,0/gI" all_data.csv
cat insert_to_stage_incoming.py | sed -e "s/ReplaceMe/\/usr\/src\/lmfao\/all_data.csv/g" | python3 manage.py shell

Number of entries added to stage_incoming table: 46405.
Loading CSV took: 0:00:07.621300.
======================================================

##################################
# PYTHON - LOAD IP_ADDRESS TABLE #
##################################
import datetime
from netvis.models import Stage_Incoming, IPAddress

start_time = datetime.datetime.now()

# Get all data from stage_incoming where the srcip isn't already in ip_address table
src_query = Stage_Incoming.objects.values('srcipver', 'srcip', 'srcipinternal').distinct().exclude(srcip__in=IPAddress.objects.only('ip_address').values_list('ip_address', flat=True))
# Get all data from stage_incoming where the dstip isn't already in ip_address table
dst_query = Stage_Incoming.objects.values('dstipver', 'dstip', 'dstipinternal').distinct().exclude(dstip__in=IPAddress.objects.only('ip_address').values_list('ip_address', flat=True))

print("Number of src ip addresses: " + str(src_query.count()) + ".")
print("Number of dst ip addresses: " + str(dst_query.count()) + ".")

# Create ip_address objects and add them to the arraylist
ip_addresses = []
if (src_query.union(dst_query).count() > 0):
    for row in src_query.union(dst_query):
        ip_addresses.append(IPAddress(ip_version=row['srcipver'],ip_address=row['srcip'],is_local=row['srcipinternal']))

print("Number of unique IPs added to ip_address table: " + str(src_query.union(dst_query).count()))
		
# Bulk add what we have to the ip_address table
ip_address.objects.bulk_create(ip_addresses)
##################################
# PYTHON - LOAD IP_ADDRESS TABLE #
##################################

======================================================
cat insert_to_ipaddress.py | python3 manage.py shell

Number of src ip addresses: 27.
Number of dst ip addresses: 81.
Number of unique IPs added to ip_address table: 103.
Updating IP Address Table took: 0:00:00.194121.
======================================================

########################
# UPDATING CIDR RANGES #
########################
# 10.0.* or 127.0.*
cidr8=IPAddress.objects.filter(ip_address__iregex=r'^(10|127)\.0\..+').values('cidr')
cidr8.update(cidr="8")
# 172.(16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31).*
cidr12=IPAddress.objects.filter(ip_address__iregex=r'^172\.(16|17|18|19|20|21|22|23|24|25|26|27|28|29|30|31)\..+').values('cidr')
cidr12.update(cidr="12")
# 192.168.* or 169.254.*
cidr16=IPAddress.objects.filter(ip_address__iregex=r'^(192\.168|169\.254)\..+').values('cidr')
cidr16.update(cidr="16")
# ::1*
cidr128=IPAddress.objects.filter(ip_address__iregex=r'\:\:1*').values('cidr')
cidr128.update(cidr="128")
# fe80::*
cidr10=IPAddress.objects.filter(ip_address__iregex=r'fe80\:\:*').values('cidr')
cidr10.update(cidr="10")
# fc80::*
cidr7=IPAddress.objects.filter(ip_address__iregex=r'fc80\:\:*').values('cidr')
cidr7.update(cidr="7")
########################
# UPDATING CIDR RANGES #
########################

##############################
# PYTHON - LOAD EVENTS TABLE #
##############################
import datetime
from netvis.models import Stage_Incoming, Events, IPAddress

start_time = datetime.datetime.now()

join_data = Stage_Incoming.objects.raw('select 1 as id, si."id" as "event_id", ia1."id" as "src_ip_id", ia2."id" as "dst_ip_id", si."date" as "date", si."time" as "time", si."action" as "action", si."protocol" as "protocol", si."srcport" as "srcport", si."dstport" as "dstport", si."path" as "path" from netvis_Stage_Incoming si join netvis_IPAddress ia1 on si."srcip" = ia1."ip_address" and si."srcipver" = ia1."ip_version" and si."srcipinternal" = ia1."is_local" join netvis_IPAddress ia2 on si."dstip" = ia2."ip_address" and si."dstipver" = ia2."ip_version" and si."dstipinternal" = ia2."is_local"')

# Create Events objects and add them to the arraylist
events = []
for row in join_data.iterator():
    events.append(Events(src_ip_id=IPAddress(row.src_ip_id),dst_ip_id=IPAddress(row.dst_ip_id),date=row.date,time=row.time,action=row.action,protocol=row.protocol,srcport=row.srcport,dstport=row.dstport,path=row.path))
		
# Bulk add what we have to the ip_address table
Events.objects.bulk_create(events)

end_time = datetime.datetime.now()
runtime = end_time - start_time
print("Updating Events table took: " + str(runtime) + ".")

======================================================
cat insert_to_events.py | python3 manage.py shell

Updating Events table took: 0:00:08.752905.
======================================================

#############################################
# PYTHON - UPDATE IPADDRESS HOSTNAME COLUMN #
#############################################
import csv, datetime, sys
from netvis.models import IPAddress

start_time = datetime.datetime.now()

file_path = 'ReplaceMe'
with open(file_path, "r") as csv_file:
    data = csv.reader(csv_file, delimiter=",")
    # Skip the header row
    next(data)
    ipaddress_updates = []
    for row in data:
        try:
            ipobj = IPAddress.objects.get(ip_address=row[0])
            ipobj.hostname=row[1]
            ipaddress_updates.append(ipobj)
        except:
            print("Error when processing IPAddress: " + str(row[0]))
    IPAddress.objects.bulk_update(ipaddress_updates, ['hostname'])

end_time = datetime.datetime.now()
runtime = end_time - start_time
#https://betterprogramming.pub/3-techniques-for-importing-large-csv-files-into-a-d
print("Loading CSV took: " + str(runtime) + ".")

======================================================
cat update_ipaddress_hostnames.py | sed -e "s/ReplaceMe/\/usr\/src\/lmfao\/hostnames.csv/g" | python3 manage.py shell

Loading CSV took: 0:00:00.008272.
======================================================

======================================================
# To get the column names from the database in case we forget them
test = Events.objects.raw('select 1 as id, name from pragma_table_info("netvis_Events")')
for row in test.iterator():
    row.name
======================================================