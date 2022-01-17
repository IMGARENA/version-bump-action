#!/bin/sh

if [ -f ./pom.xml ] ; then
    DEPENDENCY_SYSTEM=MAVEN
    BUILD_FILE=./pom.xml
    mvn help:evaluate -Dexpression=project.version -q -DforceStdout
else
    DEPENDENCY_SYSTEM=GRADLE
    if [ -f ./build.gradle ] ; then
        BUILD_FILE=./build.gradle
    elif [ -f ./build.gradle.kts ]; then
        BUILD_FILE=./build.gradle.kts
    fi
    ./gradlew properties --no-daemon --console=plain -q --build-file "$BUILD_FILE" | grep "^version:" | awk '{printf $2}'
fi
