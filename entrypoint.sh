#!/bin/sh

# exit when any command fails
set -e

echo create ssh key
echo $SSH_PRIVATE_KEY | base64 -d > /id_rsa
chmod 400 /id_rsa
echo create ssh know host file
echo $SSH_KNOW_HOST > /known_hosts
echo run command
echo run command
ssh -i /id_rsa -o UserKnownHostsFile=/known_hosts $DOCKER_VM_HOST << EOF
  hostname
  # define functions
  start_docker() {
    if [ -d ../../../xmm-infra-secrets-dev/\$1 ];then
      echo found secrets folder
      ls -la ../../../xmm-infra-secrets-dev/\$1/secrets.json
    fi
    echo run service
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
  cd xmm-infra-secrets-dev
  git pull
  echo pull main repository
  cd ../xmm-infra-dev
  git pull
  cd $REPOSITORY_VM_DIR
  DC=\$(find . -name docker-compose.yaml)
  for dc in \$DC
  do
    DIR_NAME=\$(echo \$dc | awk -F/ '{print \$2}')
    echo
    echo   - = [ \$DIR_NAME ] = -
    if [ -d \$DIR_NAME ];then
      cd \$DIR_NAME
      pwd
      if [ -f ../../../xmm-infra-secrets-dev/\$1/.env ];then
        echo found .env file
        if [ -f .env ];then
          echo file or symlink exist
        else
          echo create symlink
          ln -s ../../../xmm-infra-secrets-dev/\$1/.env ./.env
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
      echo \$DIR_NAME doesn't exist
    fi
    cd ..
  done
  echo remove orphan docker images
  docker image prune -af
EOF
