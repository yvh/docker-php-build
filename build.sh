#!/usr/bin/env bash
set -e

DOCKER_PHP_PROD_REPO="yannickvh/php-prod"
DOCKER_PHP_DEV_REPO="yannickvh/php-dev"
LAST_PHP_VERSION="7.4"
PHP_FOLDERS=( "docker-php-prod" "docker-php-dev" )
TAG_FOLDERS=( "apache" "cli" "fpm" )
php_version=$1
git_branch=$1

if [[ $php_version = $LAST_PHP_VERSION ]];
then
  git_branch="master"
fi

for i in "${PHP_FOLDERS[@]}"
do
  cd ../$i
  echo "Current dir: " $(pwd)
  git checkout $git_branch

  if [[ $i =~ 'prod' ]]; then
    docker_repo=$DOCKER_PHP_PROD_REPO
  else
    docker_repo=$DOCKER_PHP_DEV_REPO
  fi

  for j in "${TAG_FOLDERS[@]}"
  do
    tag=$php_version-$j
    echo "Build $docker_repo:$tag"
    docker build -t $docker_repo:$tag $j
    docker push $docker_repo:$tag
  done

  git checkout -
done
