#!/bin/sh

# exit when any command fails
set -e

echo create ssh key
echo $SSH_PRIVATE_KEY | base64 -d > /tmp/id_rsa
chmod 400 /tmp/id_rsa
echo create ssh know host file
echo $SSH_KNOW_HOST > /tmp/known_hosts
cat /tmp/known_hosts
echo run command
echo DOCKER_VM_HOST=$DOCKER_VM_HOST
ssh -i /tmp/id_rsa -o UserKnownHostsFile=/tmp/known_hosts $DOCKER_VM_HOST << EOF
  hostname
  # define functions
  start_docker() {
    DIR_NAME=$1
    if [ -d ../../../xmm-infra-secrets\$ENVIRONMENT/\$DIR_NAME ];then
      echo found secrets folder
      ls -la ../../../xmm-infra-secrets\$ENVIRONMENT/\$DIR_NAME/secrets.json
    fi
    echo run service
    docker-compose pull
    docker-compose up -d
    echo sleep for 2 seconds
    sleep 2
    echo print last logs
    docker-compose logs --tail 100
  }
  stop_docker() {
    echo stop service
    docker-compose down
  }
  echo pull secrets repository
  cd xmm-infra-secrets\$ENVIRONMENT
  git pull
  echo pull main repository
  cd ../xmm-infra\$ENVIRONMENT
  git pull
  cd $REPOSITORY_VM_DIR
  if [ -z \$REPOSITORY_SERVICE_DIR ];then
    echo REPOSITORY_SERVICE_DIR defined - $REPOSITORY_SERVICE_DIR
    DCD=$REPOSITORY_SERVICE_DIR
  else
    echo searching for docker-compose.yaml files
    DCD=\$(find . -name docker-compose.yaml | awk -F/ '{print \$2}')
  fi
  echo list of dirs \$DCD
  for DIR_NAME in \$DCD
  do
    echo
    echo   - = [ \$DIR_NAME ] = -
    if [ -d \$DIR_NAME ];then
      cd \$DIR_NAME
      pwd
      if [ -f ../../../xmm-infra-secrets\$ENVIRONMENT/\$DIR_NAME/.env ];then
        echo found .env file
        if [ -f .env ];then
          echo file or symlink exist
        else
          echo create symlink
          ln -s ../../../xmm-infra-secrets\$ENVIRONMENT/\$DIR_NAME/.env ./.env
        fi
      fi
      ls -la
      if [ "$ACTION" = "START" ];then
        start_docker $DIR_NAME;
      fi
      if [ "$ACTION" = "STOP" ];then
        stop_docker;
      fi
    else
      echo \$DIR_NAME doesn\'t exist
    fi
    cd ..
  done
  echo remove orphan docker images
  docker image prune -af
EOF
# remove private key
rm /tmp/id_rsa
