#!/bin/bash

cat /etc/passwd|sed 's/:/ /g'|awk '{print $1, $3, $6}'
