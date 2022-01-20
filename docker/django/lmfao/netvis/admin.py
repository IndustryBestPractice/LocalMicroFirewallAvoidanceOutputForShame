from django.contrib import admin
from .models import IPAddress

# Register your models here.
#admin.site.register(IPAddress)
class IPAddressAdmin(admin.ModelAdmin):
    list_display = ('ip_address','hostname','cidr',)
    list_filter = ['ip_address','hostname']
    search_fields = ('ip_address','hostname',)

admin.site.register(IPAddress, IPAddressAdmin)
