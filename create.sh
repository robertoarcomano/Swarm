#!/bin/bash
# #######################################
# CONFIGURE SWARM USING DOCKER-MACHINE #
# #######################################

# 1. install docker-machine
if [ ! -f "/usr/local/bin/docker-machine" ]; then
  base=https://github.com/docker/machine/releases/download/v0.16.0 && curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine && sudo install /tmp/docker-machine /usr/local/bin/docker-machine
fi

# 2. Create 3 docker machines:
docker-machine create manager1;
docker-machine create worker1;
docker-machine create worker2;

# 3. Install swarm on all of them
docker-machine ssh manager1 docker pull swarm;
docker-machine ssh worker1 docker pull swarm;
docker-machine ssh worker2 docker pull swarm;

# 4. Create a Swarm
MANAGER_IP=$(docker-machine ls|grep manager1|awk '{print $5}'|cut -c 7-|awk -F':' '{print $1}')
docker-machine ssh manager1 docker swarm init --advertise-addr $MANAGER_IP
TOKEN=$(docker-machine ssh manager1 docker swarm join-token worker -q)

# 5. Add the workers
docker-machine ssh worker1 docker swarm join --token $TOKEN $MANAGER_IP:2377
docker-machine ssh worker2 docker swarm join --token $TOKEN $MANAGER_IP:2377

# 6. Show swarm status
docker-machine ssh manager1 docker node ls

# 7. Launch a service
docker-machine ssh manager1 docker service create --replicas 1 --name webserver --publish published=8080,target=80 nginx

# 8. Test the service
wget http://$MANAGER_IP:8080 -O -
