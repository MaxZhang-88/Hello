#!/bin/bash

Node_Port=$(kubectl get svc -n test | grep hello | awk '{print $5}'|awk -F":" '{print $2}'|awk -F"/" '{print $1}')
curl 192.168.169.3:${Node_Port}
