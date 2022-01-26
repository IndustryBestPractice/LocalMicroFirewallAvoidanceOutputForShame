from django.db import models

# Create your models here.
class IPAddress(models.Model):
    #ip_id = models.BigAutoField(primary_key=True)
    ip_version = models.CharField(default='ipv4', max_length=4)
    ip_address = models.CharField(max_length=100)
    cidr = models.IntegerField(default=24)
    is_local = models.BooleanField(default=True)
    hostname = models.CharField(max_length=100, blank=True)
    subnet_name = models.CharField(max_length=100, blank=True)

    class Meta:
        indexes = [
            models.Index(fields=['ip_version','ip_address','is_local',]),
            models.Index(fields=['cidr',]),
            models.Index(fields=['ip_address',]),
            models.Index(fields=['subnet_name',]),
    ]

class Events(models.Model):
    #trans_id = models.BigAutoField(primary_key=True)
    #src_ip_id = models.IntegerField(null=True)
    #src_ip_id = models.OneToOneField(IPAddress, on_delete=models.CASCADE, related_name='src_ip_id')
    src_ip_id = models.ForeignKey(IPAddress, on_delete=models.CASCADE, related_name='src_ip_id')
    #dst_ip_id = models.IntegerField(null=True)
    #dst_ip_id = models.OneToOneField(IPAddress, on_delete=models.CASCADE, related_name='dst_ip_id')
    dst_ip_id = models.ForeignKey(IPAddress, on_delete=models.CASCADE, related_name='dst_ip_id')
    date = models.DateField()
    time = models.TimeField()
    action = models.CharField(max_length=100)
    protocol = models.CharField(max_length=100)
    srcport = models.CharField(max_length=5)
    dstport = models.CharField(max_length=5)
    path = models.CharField(max_length=100)

    class Meta:
        indexes = [
            models.Index(fields=['src_ip_id','dst_ip_id','protocol',]),
            models.Index(fields=['dst_ip_id',]),
            models.Index(fields=['src_ip_id','dst_ip_id','srcport','dstport',]),
            models.Index(fields=['srcport','dstport',]),
            models.Index(fields=['dstport',]),
    ]

class Stage_Incoming(models.Model):
    srcipinternal = models.BooleanField(default=False)
    dstipinternal = models.BooleanField(default=False)
    srcipver = models.CharField(max_length=4)
    dstipver = models.CharField(max_length=4)
    date = models.DateField()
    time = models.TimeField()
    action = models.CharField(max_length=20)
    protocol = models.CharField(max_length=3)
    srcip = models.CharField(max_length=100)
    dstip = models.CharField(max_length=100)
    srcport = models.CharField(max_length=5)
    dstport = models.CharField(max_length=5)
    size = models.IntegerField()
    tcpflags = models.CharField(max_length=100)
    tcpsyn = models.CharField(max_length=100)
    tcpack = models.CharField(max_length=100)
    tcpwin = models.CharField(max_length=100)
    icmptype = models.CharField(max_length=100)
    icmpcode = models.CharField(max_length=100)
    info = models.CharField(max_length=100)
    path = models.CharField(max_length=100)

