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
    cd \$DIR_NAME
    pwd
    ls -la
    if [ -d ../../../xmm-infra-secrets-dev/\$DIR_NAME ];then
      echo found secrets folder
      ls -la ../../../xmm-infra-secrets-dev/\$DIR_NAME
    fi
    if [ -f ../../../xmm-infra-secrets-dev/\$DIR_NAME/.env ];then
      echo found .env file
      if [ -f .env ];then
        echo file or symlink exist
      else
        echo create symlink
        ln -s ../../../xmm-infra-secrets-dev/\$DIR_NAME/.env ./.env
      fi
    fi
    echo run service
    docker-compose up -d
    echo sleep for 2 seconds
    sleep 2
    echo print last logs
    docker-compose logs --tail 100
    cd ..
  done
  echo remove orphan docker images
  # get list images of running dockers
  RUNNING_IMAGES=\$(docker ps | grep -v ID | awk '{printf("%s\\|",\$2)}' | awk '{ print substr( \$0, 1, length(\$0)-2 ) }')
  docker rmi \$(docker images -q | grep -v $RUNNING_IMAGES)
EOF
