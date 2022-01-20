from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.views.generic import RedirectView
from django.template import loader

from .models import Events

# Create your views here.
def index(request):
	if request.user.is_authenticated:
		#return HttpResponse("Hello world, from netvis app!")
                Event_List = Events.objects.all()
                template = loader.get_template('netvis/index.html')
                context={
                    'test': Event_List
                }
                return HttpResponse(template.render(context, request))
	else:
		# We are not an authenticated user. Redirect us to the admin page for login
		return redirect('/admin/')
