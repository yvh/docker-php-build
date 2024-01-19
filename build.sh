#!/usr/bin/env bash
set -e

set_env() {
  if [ -f "${1}" ]; then
    source ${1}
  fi
}

unset_env() {
  if [ -f "${1}" ]; then
    unset $(grep -v '^#' ${1} | awk 'BEGIN { FS = "=" } ; { print $1 }')
  fi
}

message() {
  echo -e "\033[0;32m${1}\033[0m"
}

php_version=${1:-8.3}
project_path="$(pwd)/.."

for j in apache cli fpm; do
  tag=${php_version}-${j}

  pushd "${project_path}/docker-php"
  message "Current dir: $(pwd)"
  php_base_image="yannickvh/php:${tag}"
  message "Building ${php_base_image}"
  set_env ${php_version}.env
  docker build \
    --no-cache \
    --tag "${php_base_image}" \
    --file "${j}/Dockerfile" \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg PHP_VERSION="${PHP_VERSION}" \
    --build-arg OS_PHP_DEPS="${OS_PHP_DEPS}" \
    .
  docker push ${php_base_image}
  unset_env ${php_version}.env

  pushd "${project_path}/docker-php-prod"
  message "Current dir: $(pwd)"
  php_prod_base_image="yannickvh/php-prod:${tag}"
  message "Building ${php_prod_base_image}"
  docker build \
    --no-cache \
    --tag "${php_prod_base_image}" \
    --file "${j}/Dockerfile" \
    --build-arg PHP_BASE_IMAGE="${php_base_image}" \
    .
  docker push ${php_prod_base_image}

  pushd "${project_path}/docker-php-dev"
  message "Current dir: $(pwd)"
  php_dev_base_image="yannickvh/php-dev:${tag}"
  message "Building ${php_dev_base_image}"
  docker build \
    --no-cache \
    --tag "${php_dev_base_image}" \
    --file "${j}/Dockerfile" \
    --build-arg PHP_BASE_IMAGE="${php_prod_base_image}" \
    .
  docker push ${php_dev_base_image}
done
