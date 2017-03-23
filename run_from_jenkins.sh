#Default compose args
COMPOSE_ARGS=" -f jenkins.yml -p jenkins"

# Make sure old containers are gone
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

# Build the system
sudo docker-compose $COMPOSE_ARGS build --no-cache
sudo docker-compose $COMPOSE_ARGS up -d

#Run unit tests
sudo docker-compose $COMPOSE_ARGS run --no-deps --rm -e ENV=UNIT identidock
ERR=$?

# Run system test if unit tests passed
if [ $ERR -eq 0 ]; then
  IP=$(sudo docker inspect -f {{.NetworkSettings.IPAddress}} jenkins_identidock_1)
  CODE=$(curl -sL -w "%{http_code}" $IP:9090/monster/bla -o /dev/null) || true
  if [ $CODE -eq 200 ]; then
    echo "Test passed - Tagging "
    HASH=$(git rev-parse --short HEAD)
    # Replace <reginald> with the fully qualified domain name used on page 107'
    # This is the hostname on which the registry runs
    sudo docker tag jenkins_identidock <reginald>:5000/amouat/identidock:$HASH
    sudo docker tag jenkins_identidock <reginald>:5000/amouat/identidock:newest
    echo "Pushing"
    # sudo docker login -e me@me.com -u me -p me123
    sudo docker push <reginald>:5000/amouat/identidock:$HASH
    sudo docker push <reginald>:5000/amouat/identidock:newest
  else
    echo "Site returned " $CODE
    ERR=1
  fi
fi

#Pull down the system
sudo docker-compose $COMPOSE_ARGS stop
sudo docker-compose $COMPOSE_ARGS rm --force -v

return $ERR
