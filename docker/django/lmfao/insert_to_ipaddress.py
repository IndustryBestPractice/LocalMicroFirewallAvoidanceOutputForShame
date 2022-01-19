import datetime
from netvis.models import Stage_Incoming, Events, IPAddress

start_time = datetime.datetime.now()

# Get all data from stage_incoming where the srcip isn't already in ip_address table
src_query = Stage_Incoming.objects.values('srcipver', 'srcip', 'srcipinternal').distinct().exclude(srcip__in=IPAddress.objects.only('ip_address').values_list('ip_address', flat=True))

# Get all data from stage_incoming where the dstip isn't already in ip_address table
dst_query = Stage_Incoming.objects.values('dstipver', 'dstip', 'dstipinternal').distinct().exclude(dstip__in=IPAddress.objects.only('ip_address').values_list('ip_address', flat=True))

print("Number of src ip addresses: " + str(src_query.count()) + ".")
print("Number of dst ip addresses: " + str(dst_query.count()) + ".")
#Number of unique IP's added to ip_address table: 22592.

# Create ip_address objects and add them to the arraylist
ip_addresses = []
if (src_query.union(dst_query).count() > 0):
    for row in src_query.union(dst_query):
        ip_addresses.append(IPAddress(ip_version=row['srcipver'],ip_address=row['srcip'],is_local=row['srcipinternal']))

# Bulk add what we have to the ip_address table
IPAddress.objects.bulk_create(ip_addresses)

# Now we set the default CIDR ranges
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

print("Number of unique IPs added to ip_address table: " + str(IPAddress.objects.all().count()) + ".")

end_time = datetime.datetime.now()
runtime = end_time - start_time
print("Updating IP Address Table took: " + str(runtime) + ".")
