#!/bin/bash
#
# Calls the pa11y container to run the tool against the current directory.
DIRNAME="$(basename "$(pwd)")"
PARENT="$(dirname "$(readlink -f .)")"

if [ -z "$TAG" ]; then
  TAG=latest
fi

# Make sure that the script is not in the current directory. The output from Jekyll
# should be in a sub-directory of the git repository.
SCRIPTDIR="$(dirname "$(readlink -f "$0")")"
if [ "$SCRIPTDIR" == "$(pwd)" ]; then
  echo "Script is being run incorrectly. Go into the built site directory and"
  echo "then run:"
  echo
  echo "../check-a11y.sh"
  exit 1
fi

docker run \
  --cap-drop ALL \
  --rm \
  -t \
  -u "$(id -u)":"$(id -g)" \
  -v "$PARENT":/srv \
  jekyll-pa11y:"$TAG" \
  -d "$DIRNAME" "$@"
