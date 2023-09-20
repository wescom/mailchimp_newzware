#!/usr/bin/env ruby

require "MailchimpMarketing"
require "digest"
require "./secret"  # load secret parameter keys
require "./config"  # load config parameters
require "./get_newzware_csv_data.rb"

##################################################################
### CONNECT TO MAILCHIMP
##################################################################
def connect_mailchimp()
  client = MailchimpMarketing::Client.new()
  client.set_config({
    :api_key => ENV['MAILCHIMP_API'],
    :server => ENV['MAILCHIMP_SERVER']
  })
  result = client.ping.get()
  #puts result
  return client

  rescue MailchimpMarketing::ApiError => e
    puts "Connection Error: #{e}"
    exit!
end

##################################################################
### MAILCHIMP GROUP & INTEREST functions
##################################################################
def get_group_id_of_name(client, list_id, group_name)
  # searches through audience list for group name and returns id
  groups = client.lists.get_list_interest_categories(list_id, opts = {count: 100})
  keys_to_extract = ["id", "title"]
  groups["categories"].map do |category|
    if category.has_value?(group_name)
      #puts category["id"].to_s + " " + category["title"]
      return category["id"]
    end
  end
  return nil
  
  rescue MailchimpMarketing::ApiError => e
    puts "GroupID Error: #{e}"  
    exit!
end

def get_interest_id_of_name(client, list_id, group_name, interest_name)
  # searches through group_name and returns group interest id

  # find group_id of group_name
  group_id = get_group_id_of_name(client, list_id, group_name)
  #puts group_id

  # find group_interest_id of interest_name
  # IMPORTANT... MailChimp API limits the returned records to 10 by default; increase the count to get all records
  group_interests = client.lists.list_interest_category_interests(list_id, group_id, opts = {count: 100})
  keys_to_extract = ["id", "name"]
  group_interests["interests"].map do |interest|
    if interest.has_value?(interest_name)
      return interest["id"]
    end
  end
  return nil

  rescue MailchimpMarketing::ApiError => e
    puts "Group Interest Error: #{e}"  
    exit!
end

def list_groups_and_all_interests(client, list_id)
  # list all groups for list_id and all interests within those groups

  groups = client.lists.get_list_interest_categories(list_id)
  groups["categories"].map do |category|
    puts "\n" + category["id"].to_s + " - " + category["title"]
    
    group_interests = client.lists.list_interest_category_interests(list_id, category["id"].to_s,opts = {count: 100})
    #puts group_interests.inspect
    group_interests["interests"].each do |interest|
      puts "   " + interest["id"].to_s + " - " + interest["name"]
    end
    
  end
  puts "\n\n"

  exit
  

  rescue MailchimpMarketing::ApiError => e
    puts "Group Interest Add Error: #{e}"
    exit!  
end

def member_exists_in_list?(client, list_id, member_data)
  #puts member_data.inspect
  response = client.lists.get_list_member(list_id, member_data["em_email"])
  return true

  rescue MailchimpMarketing::ApiError => e
    return false
    exit!
end

def add_group_interest(client, list_id, group_name, interest_name)
  # adds new interest to Mailchimp group, returns id

  # find group_id of group_name
  group_id = get_group_id_of_name(client, list_id, group_name)
  response = client.lists.create_interest_category_interest(
      list_id,
      group_id,
      { 'name' => interest_name }
    )
  puts "*** New mailchimp group_interest added: " + group_name + "->" + response['name']

  return response['id']

  rescue MailchimpMarketing::ApiError => e
    puts "Group Interest Add Error: #{e}"
    exit!
end

##################################################################
### UTILITY funtions
##################################################################

def get_address(member_data)
  address = ""
  if member_data.key?("addr1")
    address = member_data['addr1']
  end
  if member_data.key?("addr2")
    address = address + "," + member_data['addr2'] unless member_data['addr2'].empty?
  end
  return address
end

def get_full_address(member_data)
  # returns full address of member formatted properly
  full_addr = ""
  if member_data.key?("addr1")
    full_addr = get_address(member_data)
    full_addr = full_addr + "," unless get_address(member_data).empty?
  end
  if member_data.key?("ad_city")
    full_addr = full_addr + " " + member_data['ad_city'] unless member_data['ad_city'].empty?
  end
  if member_data.key?("ad_state")
    full_addr = full_addr + " " + member_data['ad_state'] unless member_data['ad_state'].empty?
  end
  if member_data.key?("ad_zip")
    full_addr = full_addr + " " + member_data['ad_zip'] unless member_data['ad_zip'].empty?
  end
  return full_addr.strip
end

def most_recent_date(date1,date2)
  if date1.empty? || date2.empty?
    if date1.empty?
      return date2
    else
      return date1
    end
  else
    most_recent_date = Date.strptime(date1,"%Y-%m-%d") > Date.strptime(date2,"%Y-%m-%d") ? date1 : date2
    return most_recent_date
  end
end

##################################################################
### MAILCHIMP UPDATE functions
##################################################################
def subscriber?(member_data)
  # returns whether member is a subscriber
  subscription_names = eval ENV['SUBSCRIPTION_NAMES']
  if subscription_names[member_data["rr_del_meth"]].downcase.include?("register")  # ENV['SUBSCRIPTION_NAMES'] is a registered user
    return 'NO'
  else
    return 'YES'
  end
end

def activate_member_marketing_groups(client, list_id, member_data)
  # new members will be activated for all marketing 'groups'
  email = Digest::MD5.hexdigest member_data["em_email"].downcase
  if member_exists_in_list?(client, list_id, member_data)
    group_id = get_group_id_of_name(client, list_id, ENV['MAILCHIMP_MARKETING_GROUP_NAME'])
    #puts group_id
    group_interests = client.lists.list_interest_category_interests(list_id, group_id,opts = {count: 100}) # find all interests of group_id
    interests_hash_to_set = {}
    group_interests["interests"].map do |interest|
      interests_hash_to_set[interest["id"]] = true
    end
    
    # activate marketing groups
    member = client.lists.update_list_member(
        list_id,
        member_data["em_email"],
        :interests => interests_hash_to_set
    )
    #puts member
    puts "     Marketing newsletters added to member"
  else
    puts "Member NOT FOUND in MailChimp"
  end
  
  rescue MailchimpMarketing::ApiError => e
    puts "GroupID Error: #{e}"  
    exit!
end

def activate_default_newsletter_groups(client, list_id, member_data, group_name)
  # activate all default newsletters for new member
  newsletters = ENV['MAILCHIMP_DEFAULT_NEWSLETTERS'].split("'")

  if member_exists_in_list?(client, list_id, member_data)
    # create hash of interest_ids; set all to false except member's subscription group
    group_id = get_group_id_of_name(client, list_id, group_name)
    group_interests = client.lists.list_interest_category_interests(list_id, group_id,opts = {count: 100}) # find all interests of group_id
    interests_hash_to_set = {}
    keys_to_extract = ["id", "name"]
    newsletters.each do |newsletter|
      group_interests["interests"].map do |interest|
        interest_name = interest["name"].gsub(/[^A-Za-z0-9 ]/, '')
        interest_matches = (interest_name == newsletter ? true : false)
        interests_hash_to_set[interest["id"]] = interest_matches
        if interest_matches
          service_name_matches_an_interest = true
        end
      end
    end
    
    # activate marketing groups
    member = client.lists.update_list_member(
        list_id,
        member_data["em_email"],
        :interests => interests_hash_to_set
    )
    puts "     Default newsletters added to member"
  else
    puts "Member NOT FOUND in MailChimp"
  end
  
  rescue MailchimpMarketing::ApiError => e
    puts "GroupID Error: #{e}"  
    exit!
end

def update_member_subscription_group(client, list_id, member_data)

  # updates existing member's subscription group
  email = Digest::MD5.hexdigest member_data["em_email"].downcase
  if member_exists_in_list?(client, list_id, member_data)
    # create hash of interest_ids; set all to false except member's subscription group
    group_id = get_group_id_of_name(client, list_id, ENV['MAILCHIMP_SUBSCRIPTION_GROUP_NAME'])
    group_interests = client.lists.list_interest_category_interests(list_id, group_id,opts = {count: 100}) # find all interests of group_id

    interests_hash_to_set = {}
    keys_to_extract = ["id", "name"]
    service_name_matches_an_interest = false  # keep track if subscription service_name matches at least one interest
    group_interests["interests"].map do |interest|
      #puts "*" + interest.inspect = "*"
      interest_matches = interest.has_value?(member_data["service_name"])
      interests_hash_to_set[interest["id"]] = interest_matches
      if interest_matches
        service_name_matches_an_interest = true
      end
    end
    
    unless service_name_matches_an_interest
      puts "*** No MailChimp subscription group matches service_name: "+member_data["service_name"]
      # add new group_interest 
      id = add_group_interest(client, list_id, ENV['MAILCHIMP_SUBSCRIPTION_GROUP_NAME'], member_data["service_name"])
      interests_hash_to_set[id] = true
    end
    
    # update subscription group
    member = client.lists.update_list_member(
        list_id,
        member_data["em_email"],
        :interests => interests_hash_to_set
    )
  else
    puts "Member NOT FOUND in MailChimp"
  end
  
  rescue MailchimpMarketing::ApiError => e
    puts "GroupID Error: #{e}"  
    exit!
end

def add_or_update_member_record(client, list_id, member_data, index)
  
  # set merge_fields to update in MailChimp member record
  merge_fields = {}
  merge_fields["MMERGE16"] = member_data["occ_id"] unless member_data["occ_id"].nil?
  merge_fields["FNAME"] = member_data["occ_fname"].capitalize unless member_data["occ_fname"].nil?
  merge_fields["LNAME"] = member_data["occ_lname"].capitalize unless member_data["occ_lname"].nil?
  merge_fields["PHONE"] = member_data["ph_num"] unless member_data["ph_num"].nil?
  merge_fields["FULL_ADDR"] = get_full_address(member_data) unless get_full_address(member_data).nil?
  merge_fields["ADDRESS"] = get_address(member_data) unless get_address(member_data).nil?
  merge_fields["CITY"] = member_data["ad_city"] unless member_data["ad_city"].nil?
  merge_fields["STATE"] = member_data["ad_state"] unless member_data["ad_state"].nil?
  merge_fields["ZIPCODE"] = member_data["ad_zip"] unless member_data["ad_zip"].nil?
  merge_fields["ORIGSTART"] = Date.strptime(member_data["sp_orig_start"],"%Y-%m-%d").strftime("%m/%d/%Y").to_s unless member_data["sp_orig_start"].empty?
  merge_fields["STARTDATE"] = Date.strptime(member_data["sp_beg"],"%Y-%m-%d").strftime("%m/%d/%Y").to_s unless member_data["sp_beg"].empty?
  merge_fields["GRACEDATE"] = Date.strptime(member_data["sp_grace_end"],"%Y-%m-%d").strftime("%m/%d/%Y").to_s unless member_data["sp_grace_end"].empty?
  merge_fields["STOPDATE"] = Date.strptime(member_data["sp_paid_thru"],"%Y-%m-%d").strftime("%m/%d/%Y").to_s unless member_data["sp_paid_thru"].empty?
  merge_fields["LAST_LOGIN"] = Date.strptime(member_data["last_login"],"%Y-%m-%d").strftime("%m/%d/%Y").to_s unless member_data["last_login"].empty?
  #merge_fields["SERVICE_TYPE"] = member_data["rr-del_meth"] unless member_data["rr_del_meth"].empty?  # service: 'internet','carrier','mail'
  merge_fields["RATE"] = member_data["rr_zone"] unless member_data["rr_zone"].empty?  # ratecode?

  subscription_names = eval ENV['SUBSCRIPTION_NAMES']
  #puts member_data["rr_del_meth"]
  member_data["service_name"] = subscription_names[member_data["rr_del_meth"]].empty? ? subscription_names["default"] : subscription_names[member_data["rr_del_meth"]]
  #puts member_data["service_name"]
  merge_fields["MMERGE25"] = subscriber?(member_data)

  #puts merge_fields.inspect
  #puts member_data["em_email"] + ' - ' + merge_fields["FNAME"].to_s + ' ' + merge_fields["LNAME"].to_s
  #puts "Sub?     " + member_data["service_name"] + ' = ' + merge_fields["MMERGE25"]

  # add or update MailChimp member record
  email = Digest::MD5.hexdigest member_data["em_email"].downcase
  if member_exists_in_list?(client, list_id, member_data)
    # existing member record
    #puts 'Email found in Mailchimp'
    member = client.lists.update_list_member(
        list_id,
        member_data["em_email"],
        :status => "subscribed", # "subscribed","unsubscribed","cleaned","pending"
        :merge_fields => merge_fields
      )
  else
    # new member record
    #puts 'Email not found in Mailchimp'
    member = client.lists.set_list_member(
        list_id,
        member_data["em_email"],
        {
          :email_address => member_data["em_email"],
          :status => "subscribed", # "subscribed","unsubscribed","cleaned","pending"
          :merge_fields => merge_fields
        }
      )
    activate_member_marketing_groups(client, list_id, member_data) # activate marketing groups for all new members
    activate_default_newsletter_groups(client, list_id, member_data, "Newsletters") # activate marketing groups for all new members
  end
  
  # update member's subscription group
  update_member_subscription_group(client, list_id, member_data)

  member = client.lists.get_list_member(list_id, email)
  if merge_fields["MMERGE25"] == "YES"
    puts "#{index+1} - Subscriber added/updated in MailChimp:  " + member['email_address'] + " - " + member['full_name'] + " - " + member_data["service_name"]
  else
    puts "#{index+1} - Registered User added/updated in MailChimp:  " + member['email_address'] + " - " + member['full_name']
  end
  
  rescue MailchimpMarketing::ApiError => e
    if merge_fields["MMERGE25"] == "YES"
      puts "#{index+1} - Subscriber update FAILED in MailChimp:  " + member_data["em_email"] + " - " + member_data['occ_fname'] + " " + member_data["occ_lname"]
    else
      puts "#{index+1} - Registered User update FAILED in MailChimp:  " + member_data["em_email"] + " - " + member_data['occ_fname'] + " " + member_data["occ_lname"]
    end
    puts "Update Member Error: #{e}"
end

##################################################################
# MAIN
##################################################################
# Get records from Newzware CSV files - registered users and subscribers
# Newzware files:
#   subscribers.csv = subscribers in Newzware database with their subscription info

#download_Newzware_FTP_files()  #connect to Newzware FTP and download files

# Get site codes and associated domains
eomedia_sites = eval ENV['EOMEDIA_SITES']
eomedia_sites.each do |site|
  puts "\n--------------------------------------------------------------"
  puts "Importing domain: " + site[0] + " - " + site[1]
  puts "--------------------------------------------------------------"
  domain = site[1]

  # read downloaded domain records into array for import
  newzware_subscribers = get_newzware_subscribers(domain)   # returns array of subscribers for domain
  newzware_users = get_newzware_users(domain)   # returns array of registered users for domain

  # merge registered users and subscribers into single array for import
  newzware_users_and_subscribers = merge_newzware_users_and_subscribers(newzware_users,newzware_subscribers)

  # filter records by date
  newzware_users_and_subscribers = filter_records_by_date(newzware_users_and_subscribers)
  
  # Update MailChimp with new subscriber record changes
  mailchimp_client = connect_mailchimp()  # connect to mailchimp API
  list_id = ENV[domain.upcase+'_LIST_ID'] # get MailChimp audience list ID based on domain
  list_name = mailchimp_client.lists.get_list(list_id)["name"] # get MailChimp audience name
  puts "\nConnected to MailChimp audience: #" + list_id + " - " + list_name

  puts "Updating Mailchimp audience..."
  newzware_users_and_subscribers.each_with_index do |member,index|
    # connect to MailChimp API every 100 records
    #if index % 100 == 0
    #  mailchimp_client = connect_mailchimp()
    #end

    #puts member.inspect
    add_or_update_member_record(mailchimp_client, list_id, member, index)
  end
  
  exit
end

