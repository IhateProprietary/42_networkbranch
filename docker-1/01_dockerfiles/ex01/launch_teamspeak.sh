#!/bin/bash

# docker build -t ts3:local
docker run --name ts3 -p 9987:9987/udp -p 10011:10011 -p 30033:30033 -d ts3:local
