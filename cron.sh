#!/usr/bin/env bash
# run daily with
# 0 22 * * * /bin/bash -l -c 'cron.sh >> cron.log'

BASEDIR=$(dirname $0)
echo running in $BASEDIR
cd $BASEDIR

git checkout r-gamedev
git pull

ruby -v

bundle install
bundle exec ruby run.rb

git add -A
git commit -am "Stats update."
git push

echo done
echo
echo