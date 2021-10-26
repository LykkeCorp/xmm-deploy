# xmm-deploy
Apply all docker-compose yamls to docker host
# example of usage in pipeline
```
name: Deploy Dev VM1

on:
  push:
    branches: [ master ]
    paths:
    - 'vm1/**'

jobs:
  deploy:
    name: deploy
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    - name: ssh deploy
      uses: swisschain/xmm-deploy@master
      env:
        ENVIRONMENT: '-dev'
        DOCKER_VM_HOST: 'root@<IP>'
        REPOSITORY_VM_DIR: 'vm1'
        REPOSITORY_SERVICE_DIR: 'XMM-B2C2-Fix'
        SSH_PRIVATE_KEY: ${{ secrets.DEV_SSH_PRIVATE_KEY }}
        SSH_KNOW_HOST: '<IP> ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTHAyNTYAAAAIbmAAABBBLOVXiO8fOFnTO/tvMyceRutgJ4pbfsyOfiPB1xZjpNVzmuegG3icr1KFJDf8='
```
