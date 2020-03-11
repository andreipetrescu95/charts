#!/usr/bin/env bash

ME=$(basename "$0")

usage() {
  echo "Usage: $ME" >&2
  exit 1

}

helm package web
helm package pgweb
helm package next

helm repo index ./ --url https://raw.githubusercontent.com/mr-yum/charts/master
