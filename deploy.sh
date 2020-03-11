#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

ENV=$1
CHART=$2
VALUES=$3
APP_NAME=$4

BUILD_NR_BLUE=$(kubectl -n "$ENV" get deployment "$ENV"-"$APP_NAME"-blue --template="{{ .spec.template.metadata.annotations.build_number }}")
BUILD_NR_GREEN=$(kubectl -n "$ENV" get deployment "$ENV"-"$APP_NAME"-green --template="{{ .spec.template.metadata.annotations.build_number }}")

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
  TAG_BLUE=$(kubectl -n "$ENV" get deployment "$ENV"-"$APP_NAME"-blue --template="{{ (index .spec.template.spec.containers 0).image }}" | cut -d':' -f2 | tr -d '\n')
  BUILD_NR_GREEN=$CI_PIPELINE_IID
  TRAFFIC_GREEN=100
  TRAFFIC_BLUE=0
else
  TAG_BLUE=$APP_VSN-$BUILD
  TAG_GREEN=$(kubectl -n "$ENV" get deployment "$ENV"-"$APP_NAME"-green --template="{{ (index .spec.template.spec.containers 0).image }}" | cut -d':' -f2 | tr -d '\n')
  BUILD_NR_BLUE=$CI_PIPELINE_IID
  TRAFFIC_GREEN=0
  TRAFFIC_BLUE=100
fi

helm upgrade --install --wait "$ENV"-"$APP_NAME" "$CHART" -f "$VALUES" --set greenTraffic="$TRAFFIC_GREEN" --set blueTraffic="$TRAFFIC_BLUE" --set image.greenTag="$TAG_GREEN" --set image.blueTag="$TAG_BLUE" --set buildNrGreen="$BUILD_NR_GREEN" --set buildNrBlue="$BUILD_NR_BLUE" --namespace "$ENV"

