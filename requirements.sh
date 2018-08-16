#!/usr/bin/env bash

export PACKAGES="terraform kops kubernetes-cli awscli helm"
export LIGHT_GREEN="\e[38;5;85m"
export YELLOW_WARNING="\e[38;5;226m"
export RESET_COLOR="\e[0m"

echo -e "\nRequired packages:"
for PACKAGE in $PACKAGES
do
  echo -e "\t$PACKAGE"
done

echo -e "\n"
echo "To install Docker for Mac:"
echo -e "\t${YELLOW_WARNING}https://docs.docker.com/v17.12/docker-for-mac/install/${RESET_COLOR}"

echo -e "\n${LIGHT_GREEN}Using homebrew to install some required packages${RESET_COLOR}\n"

echo -e "${LIGHT_GREEN}-----------${RESET_COLOR}"
echo -e "\n${LIGHT_GREEN}Use the aws cli to configure the proper credentials${RESET_COLOR}"
echo -e "\t${YELLOW_WARNING}https://github.com/kubernetes/kops/blob/master/docs/aws.md#setup-iam-user${RESET_COLOR}\n"
echo -e "${LIGHT_GREEN}-----------${RESET_COLOR}"

echo -e "\n${LIGHT_GREEN}Use brew to install required packages? (y/N)${RESET_COLOR} "
read -s -n1 ANSWER

if ([[ $ANSWER == "y" ]] || [[ $ANSWER == "Y" ]])
then
  echo -e "\nInstalling packages\n"
  brew install $PACKAGES
else
  echo "Not installing packages"
  echo -e "Exiting...\n"
  exit 1
fi