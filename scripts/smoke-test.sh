#!/bin/bash

APP_URL="http://af32f5fa4bee14ff5bfc2f8c4654df02-82948292.ap-south-1.elb.amazonaws.com:8080/"
echo "Checking application root URL: $APP_URL"
curl -f -s $APP_URL || { echo "App root URL check failed!"; exit 1; }
echo "Basic smoke test passed."
