#!/bin/sh
sleep(3)
echo "Starting migrations..."
python manage.py migrate
echo "Starting server..."
python manage.py runserver 0.0.0.0:8000