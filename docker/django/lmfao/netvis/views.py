from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.views.generic import RedirectView
from django.template import loader
from django.db.models import Count

from .models import Events,IPAddress

import datetime
import random

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
                legend_nodes = []
                legend_colors = {}
                for row in union_query:
                    node_ids.append(row['src_ip_id'])
                # Get the IPAddress data for each ip_id in Events table
                nodes = IPAddress.objects.filter(id__in=node_ids).values('id','ip_address','cidr','hostname')
                unique_cidrs = nodes.all().values_list('cidr').distinct().values('cidr')
                rando_color = lambda: random.randint(0,255)
                last_node_id = nodes.all().values('id').order_by('id').last()
                area_width = 800
                area_height = 800
                step_amt = 70
                step_count = 0
                x = (area_width * -1) / 2 + 50
                y = (area_height * -1) / 2 + 50
                for row in unique_cidrs:
                    last_node_id['id'] = last_node_id['id'] + 1
                    legend_colors[row['cidr']] = '#%02X%02X%02X' % (rando_color(),rando_color(),rando_color())
                    legend_entry = {}
                    legend_entry['id'] = str(last_node_id['id'])
                    legend_entry['x'] = str(x)
                    legend_entry['y'] = str(y  + (step_amt * step_count))
                    legend_entry['title'] = "group_" + str(row['cidr'])
                    legend_entry['label'] = "group_" + str(row['cidr'])
                    legend_entry['group'] = "group_" + str(row['cidr'])
                    legend_entry['value'] = "1"
                    legend_entry['fixed'] = "true"
                    legend_entry['physics'] = "false"
                    legend_nodes.append(legend_entry)
                    #legend_nodes.append('{ id: ' + str(last_node_id['id']) + ', x: ' + str(x) + ', y: ' + str(y  + (step_amt * step_count)) + ', title: "group_' + str(row['cidr']) + '", label: "group_' + str(row['cidr']) + '", group: "group_' + str(row['cidr']) + '", value: 1, fixed: true, physics: false},')
                    step_count = step_count + 1
                edges = Events.objects.filter(date='2020-10-14').values('src_ip_id','dst_ip_id','dstport','action').annotate(total=Count('id'))
                # COOKIES AND STUFF!
                #last_visit = request.session.get('last_page_visit', str(datetime.datetime.now()))
                num_visits = request.session.get('num_visits', "0")
                num_visits_pass = int(num_visits)
                #print("Number of page visits Before: " + str(num_visits))
                num_visits = int(num_visits) + 1
                #print("Number of page visits After: " + str(num_visits))
                request.session['num_visits'] = str(num_visits)
                #print(str(request.session['num_visits']))
                #print(str(request.session.get('last_visit')))
                # Create context to send to the template
                context = {
                    'nodes': nodes,
                    'edges': edges,
                    'num_visits': str(num_visits_pass),
                    'legend_colors': legend_colors,
                    'legend_nodes': legend_nodes
                }
                response = HttpResponse("")
                response.set_cookie("num_visits", num_visits_pass)
                template = loader.get_template('netvis/index.html')
                return HttpResponse(template.render(context, request))
                #return render(request, 'netvis/index.html', context)
            else:
                response = HttpResponse("Hello world, from netvis app!")
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
