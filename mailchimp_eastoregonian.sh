#!/bin/bash
source /usr/local/rvm/environments/ruby-2.5.1@mailchimp

echo "$(date +%m/%d/%y\ %T)"
cd /u/apps/mailchimp_townnews

echo "eastoregonian"
ruby import_subscribers.rb eastoregonian

echo "$(date +%m/%d/%y\ %T)"
