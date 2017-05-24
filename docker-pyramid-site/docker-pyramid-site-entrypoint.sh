#!/bin/bash

# This file compiled from base/docker-pyramid-site-entrypoint.sh.in


# Modeled on:
#
# https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/

set -e

# Ensure our repository is defined
if [[ ! -n $GIT_REPOSITORY_SITE ]] ; then
  echo "\$GIT_REPOSITORY_SITE not defined"
  exit 1
fi

# Ensure our branch is defined
if [[ ! -n $GIT_REPOSITORY_SITE_BRANCH ]] ; then
  GIT_REPOSITORY_SITE_BRANCH="master"
fi

# Pull the repository into our site directory

# If we have an existing repository, but not the right one, we need to start from scratch
GIT_REPOSITORY_EXISTING=$(git --git-dir=/docker-pyramid-site/site/.git remote -v | grep -m 1 origin | awk -F'[ \t]' '{print $2}')
echo "Desired Repository: $GIT_REPOSITORY_SITE"
echo "Existing Repository: $GIT_REPOSITORY_EXISTING"
if [[ -d /docker-pyramid-site/site ]] ; then
  if [[ $GIT_REPOSITORY_SITE != $GIT_REPOSITORY_EXISTING ]] ; then
    rm -rf /docker-pyramid-site/site/*
    rm -rf /docker-pyramid-site/site/.[!.]?*
  fi
fi

# Check whether this is our first time running, such that we need to clone
if [[ ! -d /docker-pyramid-site/site/.git ]] ; then
  git clone $GIT_REPOSITORY_SITE /docker-pyramid-site/site
fi

# The presence of a lock means somebody else did not finish
# We need to clear the lock so our git commands can execute
# Saw this when the host disk filled, hopefully should not need this
# But it allows us to recover without needing to explicitly detect
# this situation and delete the container
if [[ -f /docker-pyramid-site/site/.git/index.lock ]] ; then
  rm -f /docker-pyramid-site/site/.git/index.lock
fi

# Change into the directory
GIT_PULL_PRIOR_DIRECTORY=$(pwd)
cd /docker-pyramid-site/site

# Ensure we have the branch we want, but nothing else
# http://grimoire.ca/git/stop-using-git-pull-to-deploy
git fetch --all
git checkout --force origin/$GIT_REPOSITORY_SITE_BRANCH

# Restore our directory
cd $GIT_PULL_PRIOR_DIRECTORY



# Change into the site directory
cd /docker-pyramid-site/site

# Ensure we have our Python dependencies
pip install -r requirements3.txt

# Put our production config in the correct location
rm -f pyramid_config.production.ini
ln -s /docker-pyramid-site/pyramid_config.production.ini pyramid_config.production.ini

# Build our site
exec invoke serve_production
