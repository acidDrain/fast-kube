#!/usr/bin/env bash

export WORKINGDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd "$WORKINGDIR/istio_install"

kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml

export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

echo $INGRESS_HOST
echo "$GATEWAY_URL"

sleep 5

curl -o /dev/null -s -w "%{http_code}\n" http://${GATEWAY_URL}/productpage
# kubectl apply -f samples/bookinfo/platform/kube/bookinfo-ingress.yaml