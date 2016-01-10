# run daily with
# 0 22 * * * cron.sh
#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo running in $DIR
cd $DIR

git checkout r-gamedev
git pull

# load rvm ruby
source $(rvm env --path -- ruby 2.2.1)

bundle install
bundle exec ruby run.rb

git add -A
git commit -am "Stats update."

