#!/bin/bash

# Directory of this script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

#
# Takes a version number, and the mode to bump it, and increments/resets
# the proper components so that the result is placed in the variable
# `NEW_VERSION`.
#
# $1 = mode (major, minor, patch)
# $2 = version (x.y.z)
#
function bump {
  local mode="$1"
  local old="$2"
  local parts=( ${old//./ } )
  case "$1" in
    major)
      local bv=$((parts[0] + 1))
      NEW_VERSION="${bv}.0.0"
      ;;
    minor)
      local bv=$((parts[1] + 1))
      NEW_VERSION="${parts[0]}.${bv}.0"
      ;;
    patch)
      local bv=$((parts[2] + 1))
      NEW_VERSION="${parts[0]}.${parts[1]}.${bv}"
      ;;
    esac
}

BUMP_MODE="none"
if git log -1 | grep -q "#major"; then
  BUMP_MODE="major"
elif git log -1 | grep -q "#minor"; then
  BUMP_MODE="minor"
else
  BUMP_MODE="patch"
fi


if [ -f ./pom.xml ] ; then
    DEPENDENCY_SYSTEM=MAVEN
    VERSION_FILE=./pom.xml
else
    DEPENDENCY_SYSTEM=GRADLE
    if [ -f .${VERSION_FILEPATH}/gradle.properties ] && grep -E -q "version=${CURRENT_VERSION}" .${VERSION_FILEPATH}/gradle.properties
    then
      VERSION_FILE=.${VERSION_FILEPATH}/gradle.properties
    elif [ -f .${VERSION_FILEPATH}/build.gradle ] ; then
      VERSION_FILE=.${VERSION_FILEPATH}/build.gradle
    elif [ -f .${VERSION_FILEPATH}/build.gradle.kts ]; then
      VERSION_FILE=.${VERSION_FILEPATH}/build.gradle.kts
    fi
fi

PRETTIFIED_VERSION_FILE=$(basename ${VERSION_FILE})

if [[ "${BUMP_MODE}" == "none" ]]
then
  echo "### No Release Occurred

No matching commit tags found.
${PRETTIFIED_BUILD_FILE} will remain at ${CURRENT_VERSION}" >> "${GITHUB_STEP_SUMMARY}"
  exit 0
fi

echo "$BUMP_MODE version bump detected"

bump $BUMP_MODE "${CURRENT_VERSION}"

SUMMARY_MSG="Release ${NEW_VERSION}

Bump ${PRETTIFIED_VERSION_FILE} from ${CURRENT_VERSION} to ${NEW_VERSION}"
COMMIT_MSG="${SUMMARY_MSG}
[skip actions]"

echo "----"
echo "${SUMMARY_MSG}"
echo "----"

echo "### ${SUMMARY_MSG}" >> "${GITHUB_STEP_SUMMARY}"

if [ "${DEPENDENCY_SYSTEM}" = "MAVEN" ]; then
  mvn -q versions:set -DnewVersion="${NEW_VERSION}"
elif [ "${DEPENDENCY_SYSTEM}" = "GRADLE" ]; then
  sed -i "s/\(version *= *['\"]*\)${CURRENT_VERSION}\(['\"]*\)/\1${NEW_VERSION}\2/" ${VERSION_FILE}
fi

git add $VERSION_FILE
git commit -m "${COMMIT_MSG}"
git tag "${NEW_VERSION}"

# The actions/checkout sets the git header authorisation which will be used over any url authorisation
# This means the below "repo" arg wont do anything
# Preserve the header, unset it then push using the provided authentication
HEADER=$(git config --local --get http.https://github.com/.extraheader)
git config --local --unset http.https://github.com/.extraheader

REPO="https://$TOKEN@github.com/$GITHUB_REPOSITORY.git"
git push --repo="${REPO}" --follow-tags || exit 1
git push --repo="${REPO}" --tags || exit 1

# Re-set the header back in to allow subsequent actions to expect it
git config --local http.https://github.com/.extraheader "${HEADER}"

