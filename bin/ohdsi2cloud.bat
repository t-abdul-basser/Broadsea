@echo off
setlocal
SET YML_DIR=C:\Users\taa7016\Documents\GitHub\Broadsea\postgresql
SET DOCKER_COMPOSE_FILE=%YML_DIR%\docker-compose-aou-postgres.yml
SET GCP_OHDSI_PROJECT_ID="$(gcloud config get-value project)"
IF ""%~1"" == ""up"" GOTO kubernetes-deploy
IF "%~1" == "down" GOTO kubernetes-undeploy
IF ""%~1"" == ""compute-up"" GOTO compute-up
IF "%~1" == "compute-down" GOTO compute-down
IF "%~1" == "kompose-up" GOTO kubernetes-deploy
IF "%~1" == "kompose-down" GOTO kubernetes-undeploy
IF "%~1" == "convert" GOTO kubernetes-convert
IF "%~1" == "create-ohdsi-sql-users" GOTO create-sql-users
IF "%~1" == "clean-docker-volumes" GOTO clean-docker-volumes
IF "%~1" == "test" GOTO test
IF "%~1" == "tail" GOTO tail
IF "%~1" == "logs" GOTO tail
IF "%~1" == "describe" GOTO info
IF "%~1" == "bash" GOTO bash
IF "%~1" == "push" GOTO push
IF "%~1" == "install" AND "%~2" == "docker-compose" GOTO install-docker-compose
GOTO usage

:kubernetes-deploy
kompose -f %DOCKER_COMPOSE_FILE% up
kubectl delete services broadsea-methods-library
kubectl expose deployment broadsea-methods-library --type=LoadBalancer --port 8787
kubectl delete services broadsea-webtools
kubectl expose deployment broadsea-webtools --type=LoadBalancer --port 8080
GOTO end

:kubernetes-undeploy
kompose -f %DOCKER_COMPOSE_FILE% down
GOTO end

:compute-up
ssh curation-analysis-instance-1.us-central1-a.all-of-us-ehr-dev
docker-compose -f docker-compose-aou.yml up -d

:compute-down
echo Deprecated!

:convert
kompose -f DOCKER_COMPOSE_FILE convert
GOTO end

:test
SET ATLAS_DEFAULT_PORT=8080
SET ATLAS_IP = $(kubectl get services kubernetes | awk 'FNR == 2 {print $2}')
echo Testing Tomcat availability...
curl %ATLAS_IP%:%ATLAS_DEFAULT_PORT%
echo Testing WebAPI availability...
curl %ATLAS_IP%:%ATLAS_DEFAULT_PORT%/WebAPI/source/sources
echo Testing Atlas availability...
curl %ATLAS_IP%:%ATLAS_DEFAULT_PORT%/atlas
GOTO end

:info
kubectl get deployment,svc,pods
kubectl describe svc broadsea-webtools
kubectl describe svc broadsea-methods-library
GOTO end

:tail
kubectl exec -it broadsea-webtools tail -f /var/log/supervisor/*stdout*
GOTO end

:clean-docker-volumes
REM See https://unix.stackexchange.com/questions/203168/docker-says-no-space-left-on-device-but-system-has-plenty-of-space
ssh curation-analysis-instance-1.us-central1-a.all-of-us-ehr-dev
# remove exited containers:
docker ps --filter status=dead --filter status=exited -aq | xargs -r docker rm -v
# remove unused images:
docker images --no-trunc | grep '<none>' | awk '{ print $3 }' | xargs -r docker rmi
docker volume ls -qf dangling=true | xargs -r docker volume rm

:bash
kubectl exec -it broadsea-webtools bash
GOTO end

:push
gcloud docker -- push gcr.io/%GCP_OHDSI_PROJECT_ID%/broadsea-webtools:v1
gcloud docker -- push gcr.io/%GCP_OHDSI_PROJECT_ID%/broadsea-methodslibrary:v1
GOTO end

:install-docker-compose
install-docker-compose.sh
GOTO end

:create-sql-users
createCloudSqlUsers.bat
GOTO END

:version
echo Version 0.1.0 (Requires gcloud installed with established credentials, kubectl installed with an established context, kompose (https://github.com/kubernetes-incubator/kompose) on PATH).
GOTO end

:usage
echo Usage:  ohdsi2cloud ( commands ... )
echo commands:
echo   up			Deploy OHDSI stack to GKE via via kompose
echo   down			Undeploy OHDSI stack from GKE via kompose
echo   compute-up			Deploy OHDSI stack to GCE
echo   compute-down			Undeploy OHDSI stack from GCE
echo   convert  Convert docker-compose YAML file to kubernetes YAML files
echo   create-ohdsi-sql-users	Creates OHDSI SQL users
echo   clean-docker-volumes	Clean docker volumes
echo   test			Test deployment
echo   tail			Tail OHDSI logs
echo   describe		Describe deployed services
echo   bash			Bash shell
echo   push			push customized Docker images to GCE (alpha)
GOTO end
:end
