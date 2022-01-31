from django.urls import path

from . import views

urlpatterns = [
        # ex: /netvis/
	path('', views.index, name='index'),
        # ex: /netvis/modify/
        #path('/modify/', views.modify, name='modify'),
]
