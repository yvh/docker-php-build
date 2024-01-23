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

building_message() {
  echo -e "\033[0;32mBuilding ${1} from ${2}\033[0m"
}

php_version=${1:-8.3}
project_path="$(pwd)/.."

for j in apache cli fpm; do
  tag=${php_version}-${j}

  # php
  pushd "${project_path}/docker-php"
  set_env ${php_version}.env
  php_image_tag="yannickvh/php:${tag}"
  building_message ${php_image_tag} ${BASE_IMAGE}
  docker build \
    --no-cache \
    --tag "${php_image_tag}" \
    --file "${j}/Dockerfile" \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg PHP_VERSION="${PHP_VERSION}" \
    --build-arg OS_PHP_DEPS="${OS_PHP_DEPS}" \
    .
  docker push ${php_image_tag}
  unset_env ${php_version}.env
  popd > /dev/null

  # php-prod 
  pushd "${project_path}/docker-php-prod"
  php_prod_image_tag="yannickvh/php-prod:${tag}"
  building_message ${php_prod_image_tag} ${php_image_tag}
  docker build \
    --no-cache \
    --tag "${php_prod_image_tag}" \
    --file "${j}/Dockerfile" \
    --build-arg PHP_BASE_IMAGE="${php_image_tag}" \
    .
  docker push ${php_prod_image_tag}
  popd > /dev/null

  # php-dev
  pushd "${project_path}/docker-php-dev"
  php_dev_image_tag="yannickvh/php-dev:${tag}"
  building_message ${php_dev_image_tag} ${php_prod_image_tag}
  docker build \
    --no-cache \
    --tag "${php_dev_image_tag}" \
    --build-arg PHP_BASE_IMAGE="${php_prod_image_tag}" \
    .
  docker push ${php_dev_image_tag}
  popd > /dev/null
done
