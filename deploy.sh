#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

ENV=$1
BUILD_NR_BLUE=$(kubectl -n "$ENV" get deployment "$ENV"-web-blue --template="{{ .spec.template.metadata.annotations.build_number }}")
BUILD_NR_GREEN=$(kubectl -n "$ENV" get deployment "$ENV"-web-green --template="{{ .spec.template.metadata.annotations.build_number }}")

if [ "$BUILD_NR_BLUE" -eq 0 ] && [ "$BUILD_NR_GREEN" -eq 0 ]; then
  LIVE_COLOUR="green"
else
  if [ "$BUILD_NR_BLUE" -gt "$BUILD_NR_GREEN" ]; then
    LIVE_COLOUR="blue"
  else
    LIVE_COLOUR="green"
  fi
fi

if [ $LIVE_COLOUR == "blue" ]; then
  TAG_GREEN=$APP_VSN-$BUILD
  TAG_BLUE=$(kubectl -n "$ENV" get deployment "$ENV"-web-green --template="{{ (index .spec.template.spec.containers 0).image }}" | cut -d':' -f2 | tr -d '\n')
  BUILD_NR_GREEN=$CI_PIPELINE_IID
  TRAFFIC_GREEN=100
  TRAFFIC_BLUE=0
else
  TAG_BLUE=$APP_VSN-$BUILD
  TAG_GREEN=$(kubectl -n "$ENV" get deployment "$ENV"-web-green --template="{{ (index .spec.template.spec.containers 0).image }}" | cut -d':' -f2 | tr -d '\n')
  BUILD_NR_BLUE=$CI_PIPELINE_IID
  TRAFFIC_GREEN=0
  TRAFFIC_BLUE=100
fi

helm upgrade --install --wait staging-web apmryum/next -f next/values-stage.yaml --set greenTraffic="$TRAFFIC_GREEN" --set blueTraffic="$TRAFFIC_BLUE" --set image.greenTag="$TAG_GREEN" --set image.blueTag="$TAG_GREEN" --set buildNrGreen="$BUILD_NR_GREEN" --set buildNrBlue="$BUILD_NR_BLUE" --namespace "$ENV"

