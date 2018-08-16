#!/usr/bin/env bash

# Get the base directory
export BASE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

which docker &>/dev/null

if [ $? -ne 0 ];
then
  echo "Could not find docker in PATH, please ensure it is installed before running this script"
  exit 1
fi

echo -e "\nBuilding docker image\n"
cd $BASE_DIR/javascript_server && docker build . -t javascript_server:latest
