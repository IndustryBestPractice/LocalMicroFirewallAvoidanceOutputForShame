from django import forms

from .models import Events, IPAddress

DEMO_CHOICES = []
dates = Events.objects.values('date').distinct().values('date')
i = 0
while i < len(dates):
    DEMO_CHOICES.append((i, dates[i]),)
    i += 1


class NetVisFilters(forms.Form):
    date_choice = forms.MultipleChoiceField(choices = DEMO_CHOICES)
    
