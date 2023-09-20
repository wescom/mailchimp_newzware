require 'net/ssh'
require 'net/scp'
require 'uri'
require 'net/sftp'
require 'net/ssh/proxy/http'
require 'csv'
require 'date'

def download_Newzware_FTP_files()
  puts "Connecting to Newzware"
  
  newzware_server = ENV['NEWZWARE_SERVER']
  newzware_username = ENV['NEWZWARE_USERNAME']
  newzware_password = ENV['NEWZWARE_PASSWORD']
  registered_user_file = ENV['NEWZWARE_REGISTERED_USERS_FILENAME']
  subscriber_file = ENV['NEWZWARE_SUBSCRIBERS_FILENAME']
  
  raise StandardError if newzware_server.empty? or newzware_username.empty? or newzware_password.empty? or subscriber_file.empty?

  #Download files
  userfile = "./data/registered_users.csv"
  subscriberfile = "./data/subscribers.csv"
  backupsubscriberfile = "./data/subscribers_" + DateTime.now().strftime("%Y-%m-%d") + ".bak"

  puts "Downloading files..."
  Net::SCP.download!(newzware_server, newzware_username, registered_user_file, userfile, :ssh => { :password => newzware_password })
  Net::SCP.download!(newzware_server, newzware_username, subscriber_file, subscriberfile, :ssh => { :password => newzware_password })
  Net::SCP.download!(newzware_server, newzware_username, subscriber_file, backupsubscriberfile, :ssh => { :password => newzware_password })

  puts "   " + registered_user_file + " => " + userfile
  puts "   " + subscriber_file + " => " + subscriberfile
  puts "Download complete"

  rescue
    puts "\n**************************************************************************************************"
    puts " Newzware SCP Connection Error: cannot connect"
    puts " Check SCP connection setting within the secret.rb file:"
    puts "      domain name = "+newzware_server
    puts "      username = "+newzware_username
    puts "      password = ******"
    puts "      filename = "+subscriber_file
    puts "**************************************************************************************************"
    puts "\n\n\n"
    exit!
end

def get_newzware_users(domain)
  ###########################
  # Registered Users file
  # -------------------------
  # Login_id = login id
  # fname = first name
  # lname = last name
  # email = email
  # user_type = "S" for Subscribers,  "G" for Registered only (General) 
  # account = account number
  # application = edition/publication of 'G' records
  # created = date newzware account registered
  # last_login = date of last login to newzware account by reader through login page
  # auth_edition = edition/publication of 'S' records
  # auth_last_date = last authorization date of 'S' records; automatic as subscriber visits website
  # auth_count_to_dt = count of authorizations of 'S' records
  ###########################
  
  eomedia_sites = eval ENV['EOMEDIA_SITES']
  puts "Searching for registered users"

  #read users into array
  userfile = "./data/registered_users.csv"
  newzware_registered_users = Array.new
  newzware_registered_users = CSV.parse(File.read(userfile), headers: true, col_sep: ",")

  # delete all records without email address
  newzware_registered_users.delete_if do |element|
    if element["email"].empty?
      true
    else
      false
    end
  end
  
  # filter array to records based on domain
  newzware_registered_users.delete_if do |element|
    edition_code = element["user_type"] == "S" ? element["auth_edition"] : element["application"]
    subscriber_domain = eomedia_sites[edition_code]
    if subscriber_domain != domain
      true
    else
      false
    end
  end
  
  puts "   * registered users found " + newzware_registered_users.length.to_s
  return newzware_registered_users
end

def get_newzware_subscribers(domain)
  eomedia_sites = eval ENV['EOMEDIA_SITES']
  puts "Searching for subscribers"
  
  #read subscribers into array
  subscriberfile = "./data/subscribers.csv"
  newzware_subscribers = Array.new
  newzware_subscribers = CSV.parse(File.read(subscriberfile), headers: true, col_sep: ",")
  
  # delete all records without email address
  newzware_subscribers.delete_if do |element|
    if element["em_email"].empty?
      # if em_email empty, replace with login_id if an email address
      if !element["login_id"].empty? && element["login_id"].include?("@")
        element["em_email"] = element["login_id"]
        false
      else
        true
      end
    else
      false
    end
  end
  
  # filter array to records based on domain
  newzware_subscribers.delete_if do |element|
    edition_code = element["rr_edition"]
    subscriber_domain = eomedia_sites[edition_code]
    if subscriber_domain != domain
      true
    else
      false
    end
  end
  
  puts "   * subscribers found: " + newzware_subscribers.length.to_s
  return newzware_subscribers
end

def merge_newzware_users_and_subscribers(newzware_users,newzware_subscribers)
  # merges registered users and subscriber into single array for importing to MailChimp
  puts "Merging user and subscriber files"
  newzware_users_and_subscribers = newzware_subscribers
  
  newzware_users.each do |user|
    # merge registered user array into subscriber array
    # user_type = "S" for Subscribers,  "G" for Registered only (General)
    user_in_subscriber_array = newzware_subscribers.find{|a| (a['em_email'] == user['email'] && a['rr_edition'] == user['auth_edition'])}
    if user_in_subscriber_array.nil?
      # register user record not found in subscriber file, so search by login id
      user_in_subscriber_array = newzware_subscribers.find{|a| (a['login_id'] == user['login_id'])}
    end
    if user_in_subscriber_array.nil?  # user was not a subscriber thus only registering, add to array
      newzware_users_and_subscribers.push([user['account'],user['fname'],user['lname'],user['email'],"","","","","","",user['user_type'],user['application'],user['created'],"","",user['created'],user['last_login'],"","","","",user['auth_last_date']])
      # puts user['email'] + "... appending to file "
    else
      # already in subscriber file, dont add again
      # update subscriber last_login date to most recent
      user_in_subscriber_array['last_login'] = most_recent_date(user_in_subscriber_array['last_login'],user['last_login'])
      #puts user_in_subscriber_array['em_email'] + " already in subscriber file... merging last_login date to most recent"
    end
  end

  puts "   * merged records: " + newzware_users_and_subscribers.length.to_s
  return newzware_users_and_subscribers
end

def filter_records_by_date(newzware_users_and_subscribers)
  # filter array to new records based on ENV['DAYS_PAST_TO_IMPORT']
  if ENV['IGNORE_DAYS_PAST_TO_IMPORT'] == 'false'
    puts "Filter records to past " + ENV['DAYS_PAST_TO_IMPORT'] + " days"
    todays_date = Date.parse(DateTime.now.to_s)
    newzware_users_and_subscribers.delete_if do |element|
      if element["last_change_date"].empty?
        import_by_change_date = true
      else
        change_date = Date.parse(element["last_change_date"])
        import_by_change_date = (todays_date - change_date).to_i > ENV['DAYS_PAST_TO_IMPORT'].to_i
      end

      if element["last_login"].empty?
        import_by_login_date = true
      else
        login_date = Date.parse(element["last_login"])
        import_by_login_date = (todays_date - login_date).to_i > ENV['DAYS_PAST_TO_IMPORT'].to_i
      end
      
      if import_by_change_date && import_by_login_date
        true    # delete record from import
      else
        false   # import record
      end
    end
  end

  puts "   * records ready for import: " + newzware_users_and_subscribers.length.to_s
  return newzware_users_and_subscribers
end