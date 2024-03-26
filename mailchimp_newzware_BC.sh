#!/bin/bash
source /usr/local/rvm/environments/ruby-3.0.0@mailchimp
export PATH="/usr/local/rvm/gems/ruby-3.0.0@mailchimp/bin:$PATH"

echo "$(date +%m/%d/%y\ %T)"
cd /u/apps/mailchimp_newzware

ruby import_subscribers.rb -site=BC -days=3 -logs=detail

echo "$(date +%m/%d/%y\ %T)"
echo "Export_Complete"