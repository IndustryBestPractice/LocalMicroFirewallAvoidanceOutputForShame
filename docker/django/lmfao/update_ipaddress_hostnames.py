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
#https://betterprogramming.pub/3-techniques-for-importing-large-csv-files-into-a-django-app-2b6e5e47dba0
print("Loading CSV took: " + str(runtime) + ".")
