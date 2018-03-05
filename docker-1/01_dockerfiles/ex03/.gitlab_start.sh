#!/bin/bash
/etc/init.d/redis-server restart
/etc/init.d/nginx restart
/etc/init.d/postgresql restart
/etc/init.d/gitlab restart
/etc/init.d/ssh restart
bash
