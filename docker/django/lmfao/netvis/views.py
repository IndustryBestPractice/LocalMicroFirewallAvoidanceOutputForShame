from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.views.generic import RedirectView
from django.template import loader

from .models import Events,IPAddress

# Create your views here.
def index(request):
	if request.user.is_authenticated:
            if request.method == "POST":
                return HttpResponse("Hello world - post not yet implimented!")
                Event_List = Events.objects.all()
                Event_List = Events.objects.raw('select * from Events')
                template = loader.get_template('netvis/index.html')
                context={
                    'test': Event_List
                }
                return HttpResponse(template.render(context, request))
            elif request.method == "GET":
                #template = loader.get_template('netvis/index.html')
                # Get all data from Events where the src_ip_id is in the IPAddress table
                src_query = Events.objects.values('src_ip_id').distinct().filter(date='2020-10-14',src_ip_id__in=IPAddress.objects.only('id').values_list('id', flat=True))
                src_query.count()
                # Get all data from Events where the dst_ip_id is in the IPAddress table
                dst_query = Events.objects.values('dst_ip_id').distinct().filter(date='2020-10-14',dst_ip_id__in=IPAddress.objects.only('id').values_list('id', flat=True))
                dst_query.count()
                #  Combine the query results
                union_query = src_query.union(dst_query)
                union_query.count()
                # Create a list of all node ids
                node_ids = []
                for row in union_query:
                    node_ids.append(row['src_ip_id'])
                # Get the IPAddress data for each ip_id in Events table
                #nodes = IPAddress.objects.filter(id__in=node_ids).values_list('id','ip_address','cidr','hostname')
                nodes = IPAddress.objects.filter(id__in=node_ids).values('id','ip_address','cidr','hostname')
                # Create context to send to the template
                context = {
                    'nodes': nodes
                }
                #return HttpResponse(template.render(context, request))
                return render(request, 'netvis/index.html', context)
            else:
                return HttpResponse("Hello world, from netvis app!")
                Event_List = Events.objects.all()
                Event_List = Events.objects.raw('select * from Events')
                template = loader.get_template('netvis/index.html')
                context={
                    'test': Event_List
                }
                return HttpResponse(template.render(context, request))
	else:
		# We are not an authenticated user. Redirect us to the admin page for login
		return redirect('/admin/')
