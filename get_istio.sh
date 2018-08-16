#!/bin/sh
#
# Early version of a downloader/installer for Istio
#
# This file will be fetched as: curl -L https://git.io/getLatestIstio | sh -
# so it should be pure bourne shell, not bash (and not reference other scripts)
#
# The script fetches the latest Istio release candidate and untars it.
# It's derived from ../downloadIstio.sh which is for stable releases but lets
# users do curl -L https://git.io/getLatestIstio | ISTIO_VERSION=0.3.6 sh -
# for instance to change the version fetched.

# This is the latest release candidate (matches ../istio.VERSION after basic
# sanity checks)

# Get project directory
export WORKINGDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export ENV_FILE="$WORKINGDIR/env_setup.sh"

OS="$(uname)"
if [ "x${OS}" = "xDarwin" ] ; then
  OSEXT="osx"
else
  # TODO we should check more/complain if not likely to work, etc...
  OSEXT="linux"
fi

if [ "x${ISTIO_VERSION}" = "x" ] ; then
  ISTIO_VERSION=$(curl -L -s https://api.github.com/repos/istio/istio/releases/latest | \
                  grep tag_name | sed "s/ *\"tag_name\": *\"\\(.*\\)\",*/\\1/")
fi

NAME="istio_install"
if [ ! -d "$PWD/$NAME" ];
then
  URL="https://github.com/istio/istio/releases/download/${ISTIO_VERSION}/istio-${ISTIO_VERSION}-${OSEXT}.tar.gz"
  echo "Downloading $NAME from $URL ..."
  curl -L "$URL" &>/dev/null -o "$WORKINGDIR/$NAME.tar.gz"
  mkdir "$WORKINGDIR/istio_install"
  tar xzf "$WORKINGDIR/$NAME.tar.gz" --strip-components 1 -C "$WORKINGDIR/istio_install"
  rm "$WORKINGDIR/$NAME.tar.gz"
  # NAME="$WORKINGDIR/istio_install"
  # TODO: change this so the version is in the tgz/directory name (users trying multiple versions)
  echo "Downloaded into $NAME:"
  ls "$NAME"
  BINDIR="$(cd "$NAME/bin" && pwd)"
  echo "Add $BINDIR to your path; e.g copy paste in your shell and/or ~/.profile:"
  echo "export PATH=\"\$PATH:$BINDIR\""
  grep -q "$NAME" "$ENV_FILE"
  if [ $? -ne 0 ]
  then
    echo "export PATH=\"\$PATH:$BINDIR\"" >> "$ENV_FILE"
  fi
fi

cd $NAME

# Install Istio's Custom Resource Definitions
# https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/#customresourcedefinitions
kubectl apply -f install/kubernetes/helm/istio/templates/crds.yaml
sleep 10

# Create the Kubernetes Service Account for Helm's Tiller Service
kubectl create -f install/kubernetes/helm/helm-service-account.yaml
sleep 10

# Initialize Helm/Tiller
helm init --service-account tiller
sleep 10

# Install Istio
helm install install/kubernetes/helm/istio --name istio --namespace istio-system --set tracing.enable=true
