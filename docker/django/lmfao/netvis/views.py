from django.shortcuts import render, redirect
from django.http import HttpResponse
from django.views.generic import RedirectView

# Create your views here.
def index(request):
	if request.user.is_authenticated:
		return HttpResponse("Hello world, from netvis app!")
	else:
		# We are not an authenticated user. Redirect us to the admin page for login
		return redirect('/admin/')
