import csv, datetime, sys
from netvis.models import stage_incoming

start_time = datetime.datetime.now()

file_path = 'ReplaceMe'
with open(file_path, "r") as csv_file:
    data = csv.reader(csv_file, delimiter=",")
    # Skip the header row
    next(data)
    incoming_events = []
    for row in data:
        event = stage_incoming(srcipinternal=row[0],dstipinternal=row[1],srcipver=row[2],dstipver=row[3],date=row[4],time=row[5],action=row[6],protocol=row[7],srcport=row[10],dstport=row[11],size=row[12],tcpflags=[13],tcpsyn=[14],tcpack=[15],tcpwin=[16],icmptype=[17],icmpcode=[18],info=[19],path=[20])
        incoming_events.append(event)
    stage_incoming.objects.bulk_create(incoming_events)

end_time = datetime.datetime.now()
runtime = end_time - start_time
#https://betterprogramming.pub/3-techniques-for-importing-large-csv-files-into-a-django-app-2b6e5e47dba0
print("Loading CSV took: " + str(runtime) + ".")
