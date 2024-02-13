#!/bin/bash
source /usr/local/rvm/environments/ruby-3.0.0@mailchimp
export PATH="/usr/local/rvm/gems/ruby-3.0.0@mailchimp/bin:$PATH"

echo "$(date +%m/%d/%y\ %T)"
cd /u/apps/mailchimp_newzware

ruby import_subscribers.rb -site=BB -days=3
ruby import_subscribers.rb -site=RS -days=3
ruby import_subscribers.rb -site=BC -days=3
ruby import_subscribers.rb -site=LG -days=3
ruby import_subscribers.rb -site=EO -days=3
ruby import_subscribers.rb -site=HH -days=3
ruby import_subscribers.rb -site=WC -days=3
ruby import_subscribers.rb -site=BE -days=3
ruby import_subscribers.rb -site=DA -days=3
ruby import_subscribers.rb -site=CO -days=3
ruby import_subscribers.rb -site=SS -days=3
ruby import_subscribers.rb -site=RV -days=3
ruby import_subscribers.rb -site=CP -days=3

echo "$(date +%m/%d/%y\ %T)"