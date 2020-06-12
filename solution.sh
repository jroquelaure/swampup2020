###############################################
#DRAFT
###############################################

###############################################
#Prepare your local environment
###############################################
#keep your git directory in memory for latest command
export SCRIPT_DIR=$(pwd)

#save your password

export ADMIN_PASSWORD=<password>

#save artifactory url
export ARTIFACTORY_URL=<url>

curl http://$ARTIFACTORY_URL/artifactory/api/system/ping 



##############
## 1st Lab
##############

#delete default permissions target
curl -uadmin:$ADMIN_PASSWORD -X DELETE http://$ARTIFACTORY_URL/artifactory/api/v2/security/permissions/Anything
curl -uadmin:$ADMIN_PASSWORD -X DELETE http://$ARTIFACTORY_URL/artifactory/api/v2/security/permissions/Any%20Remote


#Create base needed repository for gradle (gradle-dev-local, jcenter, libs-release)
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/repositories/gradle-dev-local -H "content-type: application/vnd.org.jfrog.artifactory.repositories.LocalRepositoryConfiguration+json" -T $SCRIPT_DIR/init/repository-gradle-dev-local-config.json
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/repositories/gradle-staging-local -H "content-type: application/vnd.org.jfrog.artifactory.repositories.LocalRepositoryConfiguration+json" -T $SCRIPT_DIR/init/repository-gradle-dev-local-config.json
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/repositories/gradle-prod-local -H "content-type: application/vnd.org.jfrog.artifactory.repositories.LocalRepositoryConfiguration+json" -T $SCRIPT_DIR/init/repository-gradle-dev-local-config.json

curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/repositories/jcenter -H "content-type: application/vnd.org.jfrog.artifactory.repositories.RemoteRepositoryConfiguration+json" -T $SCRIPT_DIR/init/jcenter-remote-config.json

curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/repositories/libs-releases -H "content-type: application/vnd.org.jfrog.artifactory.repositories.VirtualRepositoryConfiguration+json" -T $SCRIPT_DIR/init/repository-gradle-release-virtual-config.json

#create all with yaml configuration file
curl -uadmin:$ADMIN_PASSWORD -X PATCH  http://$ARTIFACTORY_URL/artifactory/api/system/configuration -T $SCRIPT_DIR/module1/repo.yaml

#create backend-dev, front-end dev, framework maintainer and release groups
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/security/groups/dev-team -H "content-type: application/vnd.org.jfrog.artifactory.security.Group+json" -T $SCRIPT_DIR/module1/group.json
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/security/groups/release-team -H "content-type: application/vnd.org.jfrog.artifactory.security.Group+json" -T $SCRIPT_DIR/module1/group.json
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/security/groups/security-team -H "content-type: application/vnd.org.jfrog.artifactory.security.Group+json" -T $SCRIPT_DIR/module1/group.json
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/security/groups/delivery-team -H "content-type: application/vnd.org.jfrog.artifactory.security.Group+json" -T $SCRIPT_DIR/module1/group.json

#create a new user for the dev team
export USER_LOGIN=<SetUserName>

curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/security/users/$USER_LOGIN -H "content-type: application/vnd.org.jfrog.artifactory.security.User+json" -T $SCRIPT_DIR/module1/user.json

#a QA engineer
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/security/users/qa -H "content-type: application/vnd.org.jfrog.artifactory.security.User+json" -T $SCRIPT_DIR/module1/qa.json

#a release manager
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/security/users/release -H "content-type: application/vnd.org.jfrog.artifactory.security.User+json" -T $SCRIPT_DIR/module1/delivery.json

#Login with user and show tree view (it is empty)

#create permission
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/v2/security/permissions/perm-dev -H "content-type: application/json" -T $SCRIPT_DIR/module1/permission-dev.json
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/v2/security/permissions/perm-release -H "content-type: application/json" -T $SCRIPT_DIR/module1/permission-release.json
curl -uadmin:$ADMIN_PASSWORD -X PUT http://$ARTIFACTORY_URL/artifactory/api/v2/security/permissions/perm-prod -H "content-type: application/json" -T $SCRIPT_DIR/module1/permission-prod.json

#Refresh session with new user and show the repos

#Get Api key for user
curl -u$USER_LOGIN:password31 -X POST http://$ARTIFACTORY_URL/artifactory/api/security/apiKey

export API_KEY=<apiKey>
##############
## 2nd Lab
##############
#configure the cli for dev profile
jfrog rt c orbitera

#Upload generic libs to Artifactory with props

jfrog rt u ....

#TODO : show with cli
# Find the latest released artifacts from specific build
curl -uadmin:$ADMIN_PASSWORD -X POST http://$ARTIFACTORY_URL/artifactory/api/search/aql -T $SCRIPT_DIR/module2/largestFile.aql

#AQl to find all archive with specific jar in it
 curl -uadmin:$ADMIN_PASSWORD -X POST http://$ARTIFACTORY_URL/artifactory/api/search/aql -T $SCRIPT_DIR/module2/junitfilter.aql

#AQL for cleanup
curl -uadmin:$ADMIN_PASSWORD -X POST http://$ARTIFACTORY_URL/artifactory/api/search/aql -T $SCRIPT_DIR/module2/cleanup.aql

##############
## 3nd Lab
##############

# Configure cli for gradle
jfrog rt gradlec

# run build 
jfrog rt gradle "clean artifactoryPublish -b build.gradle --info" --build-name=gradle --build-number=3

# build info
jfrog rt bp gradle 3 





#Now we go on QA (use qa user)
jfrog rt c orbitera-qa
jfrog rt use orbitera-qa

#Test run and promote ?
jfrog rt bpr gradle 3 gradle-staging-local --status=staged --copy=true

#security
#add build to scan
curl -uadmin:$ADMIN_PASSWORD -X PUT -H "content-type: application/json"  http://$ARTIFACTORY_URL/xray/api/v1/binMgr/default/builds -T $SCRIPT_DIR/module3/indexed.json

#scan
jfrog rt bs gradle 1 

#no alert
#create some watches and policies
curl -uadmin:$ADMIN_PASSWORD -X POST -H "content-type: application/json"  http://$ARTIFACTORY_URL/xray/api/v1/policies -T $SCRIPT_DIR/module3/policy.json
curl -uadmin:$ADMIN_PASSWORD -X POST -H "content-type: application/json"  http://$ARTIFACTORY_URL/xray/api/v2/watches -T $SCRIPT_DIR/module3/watch.json

#scan again
jfrog rt bs gradle 1

#promote the build
jfrog rt bpr gradle 1 gradle-prod-local --status=released --copy=true

#switch to release user
jfrog rt c orbitera-delivery

jfrog rt use orbitera-delivery

#Can access qualified artifact
jfrog rt s "libs-release/*.war" --build=gradle/1


#docker framework

#jfrog rt dpl $ARTIFACTORY_URL/docker-virtual/openjdk:11-jdk docker --build-name=docker --build-number=1
jfrog rt dl --spec framework-download.json --build-name=docker --build-number=1 --module=framework

#we are dev
jfrog rt use orbitera
#For now use my own fork with insecure mode in it
./jfrog1 rt dpl $ARTIFACTORY_URL/docker-virtual/openjdk:11-jdk-slim-buster docker-virtual --build-name=docker-framework --build-number=1 --module=framework


docker build . -t $ARTIFACTORY_URL/docker-virtual/jfrog-docker-framework:1 -f Dockerfile --build-arg REGISTRY=$ARTIFACTORY_URL/docker-virtual

jfrog rt dp $ARTIFACTORY_URL/docker-virtual/jfrog-docker-framework:1 docker-virtual --build-name=docker-framework --build-number=1 --module=framework

jfrog rt bp docker-framework 1


#scan
jfrog rt bs docker-framework 1

#promote

jfrog rt bpr docker-framework 1 docker-prod-local --status=released --copy=true


#docker app
./jfrog1 rt dpl $ARTIFACTORY_URL/docker-virtual/docker-framework:1 docker-virtual --build-name=docker-app --build-number=1 --module=app

jfrog rt dl --spec appmodules-download.json --build-name=app --build-number=1 --module=app

#build
docker build . -t $ARTIFACTORY_URL/docker-virtual/docker-app:1  -f Dockerfile

jfrog rt dp $ARTIFACTORY_URL/docker-virtual/docker-app:1 docker-virtual --build-name=docker-app --build-number=1 --module=app

jfrog rt bp docker-app 1

#scan
jfrog rt bs docker-app 1

#promote
jfrog rt bpr docker-app 1 docker-prod-local --status=released --copy=true

#helm


#security 
curl -uadmin:$ADMIN_PASSWORD -X POST -H "content-type: application/json"  http://$ARTIFACTORY_URL/xray/api/v1/policies -T $SCRIPT_DIR/module4/security-policy.json
curl -uadmin:$ADMIN_PASSWORD -X POST -H "content-type: application/json"  http://$ARTIFACTORY_URL/xray/api/v1/policies -T $SCRIPT_DIR/module4/license-policy.json
curl -uadmin:$ADMIN_PASSWORD -X POST -H "content-type: application/json"  http://$ARTIFACTORY_URL/xray/api/v2/watches -T $SCRIPT_DIR/module4/watch.json

# redo the whole thing or show it in pipelines and trigger a build on docker framework

#maintenance

# Find the latest released artifacts from specific build
curl -uadmin:$ADMIN_PASSWORD -X POST http://$ARTIFACTORY_URL/artifactory/api/search/aql -T $SCRIPT_DIR/module5/largestFile.aql

#AQl to find all archive with specific jar in it
 curl -uadmin:$ADMIN_PASSWORD -X POST http://$ARTIFACTORY_URL/artifactory/api/search/aql -T $SCRIPT_DIR/module5/junitfilter.aql

#AQL for cleanup
curl -uadmin:$ADMIN_PASSWORD -X POST http://$ARTIFACTORY_URL/artifactory/api/search/aql -T $SCRIPT_DIR/module2/cleanup.aql
