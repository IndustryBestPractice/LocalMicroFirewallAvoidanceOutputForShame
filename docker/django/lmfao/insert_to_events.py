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
