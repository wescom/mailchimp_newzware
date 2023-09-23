#!/bin/bash
source /usr/local/rvm/environments/ruby-3.0.0@mailchimp

echo "$(date +%m/%d/%y\ %T)"
cd /u/apps/mailchimp_newzware

ruby import_subscribers.rb

echo "$(date +%m/%d/%y\ %T)"
