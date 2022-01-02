FROM ubuntu:jammy

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        apt-utils mysql-client sqlite3 libsqlite3-dev python3 python3-pip golang nano cron
#    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src
COPY requirements.txt ./
RUN pip3 install -r requirements.txt
#RUN cd /usr/src && django-admin startproject lmfao && cd /usr/src/lmfao
RUN django-admin startproject lmfao
RUN python3 manage.py startapp netvis
WORKDIR /usr/src/lmfao
RUN python3 manage.py migrate
# Create admin/admin user
# Customize this if you want to change the password
RUN echo "from django.contrib.auth import get_user_model; User = get_user_model(); User.objects.create_superuser('admin', 'industrybestpractice2@gmail.com', 'admin')" | python3 manage.py shell
# Setting timezone
RUN sed -i "s/TIME_ZONE.*/TIME_ZONE = 'America/New_York'/g" ./lmfao/settings.py
# Allowing access from all hosts
RUN sed -i "s/ALLOWED_HOSTS.*/ALLOWED_HOSTS = ['*']/g" ./lmfao/settings.py
# Creating a "random" secret key
RUN sed -i "s/SECRET_KEY.*/SECRET_KEY = '$(cat /dev/urandom | tr -dc 'a-zA-Z0-9=*-+()^%#@!' | fold -w 50 | head -n 1)'/g" ./lmfao/settings.py
#COPY . .

EXPOSE 8000
#CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]
CMD ["/bin/bash"]
