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

print("Number of entries added to stage_incoming table: " + str(Stage_Incoming.objects.all().count()) + ".")

end_time = datetime.datetime.now()
runtime = end_time - start_time
#https://betterprogramming.pub/3-techniques-for-importing-large-csv-files-into-a-django-app-2b6e5e47dba0
print("Loading CSV took: " + str(runtime) + ".")
