# Generated by Django 4.0 on 2021-12-25 04:13

from django.db import migrations, models


class Migration(migrations.Migration):

    initial = True

    dependencies = [
    ]

    operations = [
        migrations.CreateModel(
            name='ip_address',
            fields=[
                ('ip_id', models.PositiveIntegerField(primary_key=True, serialize=False)),
                ('ip_version', models.CharField(max_length=4)),
                ('ip_address', models.CharField(max_length=100)),
                ('cidr', models.IntegerField(default=24)),
                ('is_local', models.BooleanField(default=True)),
            ],
        ),
        migrations.CreateModel(
            name='stage_incoming',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('srcipinternal', models.BooleanField(default=False)),
                ('dstipinternal', models.BooleanField(default=False)),
                ('srcipver', models.CharField(max_length=4)),
                ('dstipver', models.CharField(max_length=4)),
                ('date', models.DateField()),
                ('time', models.TimeField()),
                ('action', models.CharField(max_length=20)),
                ('protocol', models.CharField(max_length=3)),
                ('scrip', models.CharField(max_length=100)),
                ('dstip', models.CharField(max_length=100)),
                ('srcport', models.IntegerField()),
                ('dstport', models.IntegerField()),
                ('size', models.IntegerField()),
                ('tcpflags', models.CharField(max_length=100)),
                ('tcpsyn', models.CharField(max_length=100)),
                ('tcpack', models.CharField(max_length=100)),
                ('tcpwin', models.CharField(max_length=100)),
                ('icmptype', models.CharField(max_length=100)),
                ('icmpnode', models.CharField(max_length=100)),
                ('info', models.CharField(max_length=100)),
                ('path', models.CharField(max_length=100)),
            ],
        ),
        migrations.CreateModel(
            name='transaction',
            fields=[
                ('trans_id', models.PositiveIntegerField(primary_key=True, serialize=False)),
                ('src_ip_id', models.IntegerField(null=True)),
                ('dst_ip_id', models.IntegerField(null=True)),
                ('date', models.DateField()),
                ('time', models.TimeField()),
                ('action', models.CharField(max_length=100)),
                ('protocol', models.CharField(max_length=100)),
                ('srcport', models.IntegerField()),
                ('dstport', models.IntegerField()),
                ('path', models.CharField(max_length=100)),
            ],
        ),
        migrations.AddIndex(
            model_name='transaction',
            index=models.Index(fields=['src_ip_id', 'dst_ip_id', 'protocol'], name='netvis_tran_src_ip__b08f25_idx'),
        ),
        migrations.AddIndex(
            model_name='transaction',
            index=models.Index(fields=['dst_ip_id'], name='netvis_tran_dst_ip__6495bf_idx'),
        ),
        migrations.AddIndex(
            model_name='transaction',
            index=models.Index(fields=['src_ip_id', 'dst_ip_id', 'srcport', 'dstport'], name='netvis_tran_src_ip__be01b1_idx'),
        ),
        migrations.AddIndex(
            model_name='transaction',
            index=models.Index(fields=['srcport', 'dstport'], name='netvis_tran_srcport_74ac8f_idx'),
        ),
        migrations.AddIndex(
            model_name='transaction',
            index=models.Index(fields=['dstport'], name='netvis_tran_dstport_0c47b1_idx'),
        ),
        migrations.AddIndex(
            model_name='ip_address',
            index=models.Index(fields=['ip_version', 'ip_address', 'is_local'], name='netvis_ip_a_ip_vers_570485_idx'),
        ),
        migrations.AddIndex(
            model_name='ip_address',
            index=models.Index(fields=['cidr'], name='netvis_ip_a_cidr_d16da3_idx'),
        ),
        migrations.AddIndex(
            model_name='ip_address',
            index=models.Index(fields=['ip_address'], name='netvis_ip_a_ip_addr_c38382_idx'),
        ),
    ]
