# Add account credentials and API keys here.
# See http://railsapps.github.com/rails-environment-variables.html
# This file should be listed in .gitignore to keep your settings secret!
# Each entry sets a local environment variable and overrides ENV variables in the Unix shell.
# For example, setting:
# GMAIL_USERNAME: Your_Gmail_Username
# makes 'Your_Gmail_Username' available as ENV["GMAIL_USERNAME"]
# Add application configuration variables here, as shown below.
#
# Main global settings
ENV['SITE_TO_IMPORT'] = 'ALL'   # import 'ALL' sites or one site code (BB,BC,CP,...)
ENV['DAYS_PAST_TO_IMPORT'] = '3'   # number of past days to import from csv file (ie. 1 = yesterday, 2 = two days ago,...)
ENV['IGNORE_DAYS_PAST_TO_IMPORT'] = 'false'   # ignore the days_past_to_ignore setting and import all records?
# MailChimp settings
ENV['MAILCHIMP_SUBSCRIPTION_GROUP_NAME'] = 'Subscriptions'
ENV['MAILCHIMP_MARKETING_GROUP_NAME'] = 'I still want to be the first to know about:'
ENV['MAILCHIMP_DEFAULT_NEWSLETTERS'] = "" #list of newsletters to default new members to. Do not include ' in names
#
ENV['BENDBULLETIN_LIST_ID'] = '7e54ad03a8'
ENV['REDMONDSPOKESMAN_LIST_ID'] = '3f18b6f620'
ENV['BAKERCITYHERALD_LIST_ID'] = 'cceb3fda23'
ENV['DAILYASTORIAN_LIST_ID'] = 'aa2bbf9c40'
ENV['BLUEMOUNTAINEAGLE_LIST_ID'] = 'a372fda86b'
ENV['CAPITALPRESS_LIST_ID'] = '5d7644bd5d'
ENV['CHINOOKOBSERVER_LIST_ID'] = 'da88a38d49'
ENV['EASTOREGONIAN_LIST_ID'] = '0a51a22157'
ENV['HERMISTONHERALD_LIST_ID'] = '7a6269ffd5'
ENV['LAGRANDEOBSERVER_LIST_ID'] = 'c3c558f605'
ENV['SEASIDESIGNAL_LIST_ID'] = '9c85cedaed'
ENV['WALLOWA_LIST_ID'] = '9586cf40b5'
ENV['RV-TIMES_LIST_ID'] = '2798b4fb96'
# Newzware FTP settings and data configs
ENV['NEWZWARE_REGISTERED_USERS_FILENAME'] = '/mnt/PAULINA3/EOMG_FTP/newzwareftp/REGISTRATIONS_EXPORT_FROM_NEWZWARE.csv'
ENV['NEWZWARE_SUBSCRIBERS_FILENAME'] = '/mnt/PAULINA3/EOMG_FTP/newzwareftp/SUBSCRIBERS_EXPORT_FROM_NEWZWARE.csv'
#ENV['NEWZWARE_SUBSCRIPTION_NAMES'] = ''
#ENV['NEWZWARE_REGISTERED_GROUP_NAME'] = 'Registered Account'
# EO Media site codes and domains
ENV['EOMEDIA_SITES'] = '{ 
  "BB" => "bendbulletin", 
  "BC" => "bakercityherald", 
  "BE" => "bluemountaineagle", 
  "CO" => "chinookobserver", 
  "CP" => "capitalpress", 
  "DA" => "dailyastorian", 
  "EO" => "eastoregonian", 
  "HH" => "hermistonherald", 
  "LG" => "lagrandeobserver", 
  "RS" => "redmondspokesman", 
  "SS" => "seasidesignal", 
  "WC" => "wallowa", 
  "RV" => "rv-times", 
}'
ENV['SUBSCRIPTION_NAMES'] = '{ 
  "I" => "Full Digital Access", 
  "C" => "Print Subscription - Carrier", 
  "M" => "Print Subscription - Mail",
  "S" => "Stopped Subscription",
  "G" => "Registered Account",
  "default" => "Registered Account"
}'  # default value is used if nothing provided or does not exist in hash