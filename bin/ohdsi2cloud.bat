@echo off
setlocal
SET YML_DIR=C:\Users\taa7016\Documents\GitHub\Broadsea\postgresql
SET DOCKER_COMPOSE_FILE=%YML_DIR%\docker-compose-aou-postgres.yml
SET GCP_OHDSI_PROJECT_ID="$(gcloud config get-value project)"
IF ""%~1"" == ""up"" GOTO kubernetes-deploy
IF "%~1" == "down" GOTO kubernetes-undeploy
IF "%~1" == "convert" GOTO kubernetes-convert
IF "%~1" == "test" GOTO test
IF "%~1" == "logs" GOTO tail
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

:bash
kubectl exec -it broadsea-webtools bash
GOTO end

:push
gcloud docker -- push gcr.io/%GCP_OHDSI_PROJECT_ID%/broadsea-webtools:v1
gcloud docker -- push gcr.io/%GCP_OHDSI_PROJECT_ID%/broadsea-methodslibrary:v1
REM gcloud docker -- push gcr.io/%GCP_OHDSI_PROJECT_ID%/achilles:v1.6.0
GOTO end

:version
echo Version 0.1.0 (Requires gcloud installed with established credentials, kubectl installed with an established context, kompose (https://github.com/kubernetes-incubator/kompose) on PATH).
GOTO end

:usage
echo Usage:  ohdsi2cloud ( commands ... )
echo commands:
echo   up       Deploy OHDSI stack to GKE via via kompose
echo   down     Undeploy OHDSI stack from GKE via kompose
echo   convert  Convert docker-compose YAML file to kubernetes YAML files
echo   test     Test deployment
echo   logs     Tail OHDSI logs
echo   describe	Describe deployed services
echo   bash			Open Bash shell in container
GOTO end
:end
