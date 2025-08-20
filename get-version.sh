#!/bin/sh

if [ -f ./pom.xml ] ; then
    DEPENDENCY_SYSTEM=MAVEN
    BUILD_FILE=./pom.xml
    mvn help:evaluate -Dexpression=project.version -q -DforceStdout
else
    ./gradlew properties --no-daemon --console=plain -q | grep "^version:" | awk '{printf $2}'
fi
