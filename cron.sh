# run daily with
# 0 22 * * * cron.sh
#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo running in $DIR

# load rvm ruby
source $(rvm env --path -- ruby 2.2.1)

cd $DIR

bundle install
bundle exec ruby run.rb