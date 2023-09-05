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

  puts "Starting download"
  Net::SCP.download!(newzware_server, newzware_username, registered_user_file, userfile, :ssh => { :password => newzware_password })
  Net::SCP.download!(newzware_server, newzware_username, subscriber_file, subscriberfile, :ssh => { :password => newzware_password })
  Net::SCP.download!(newzware_server, newzware_username, subscriber_file, backupsubscriberfile, :ssh => { :password => newzware_password })

  puts "   " + registered_user_file + " => " + userfile
  puts "   " + subscriber_file + " => " + subscriberfile
  puts "Download complete."

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
  eomedia_sites = eval ENV['EOMEDIA_SITES']
  puts "Searching for register users in " + domain

  #read users into array
  userfile = "./data/registered_users.csv"
  newzware_registered_users = Array.new
  newzware_registered_users = CSV.parse(File.read(userfile), headers: true, col_sep: ",")

  # filter array to new records based on ENV['DAYS_PAST_TO_IMPORT']
#  todays_date = Date.parse(DateTime.now.to_s)
#  newzware_registered_users.delete_if do |element|
#    record_date = Date.parse(element["creationdate"])
#    if (todays_date - record_date).to_i > ENV['DAYS_PAST_TO_IMPORT'].to_i
#      true
#    else
#      false
#    end  
#  end
  
  # filter array to records based on domain
  newzware_registered_users.delete_if do |element|
    edition_code = element["rr_edition"]
    subscriber_domain = eomedia_sites[edition_code]
    if subscriber_domain != domain
false
      #true
    else
      false
    end
  end
  
  puts "   *registered users found " + newzware_registered_users.length.to_s
  return newzware_registered_users
end

def get_newzware_subscribers(domain)
  eomedia_sites = eval ENV['EOMEDIA_SITES']
  puts "Searching for subscribers in " + domain
  
  #read subscribers into array
  subscriberfile = "./data/subscribers.csv"
  newzware_subscribers = Array.new
  newzware_subscribers = CSV.parse(File.read(subscriberfile), headers: true, col_sep: ",")
  
  # filter array to new records based on ENV['DAYS_PAST_TO_IMPORT']
#  todays_date = Date.parse(DateTime.now.to_s)
#  newzware_subscribers.delete_if do |element|
#    record_date = Date.parse(element["transactionTime"])
#    if (todays_date - record_date).to_i > ENV['DAYS_PAST_TO_IMPORT'].to_i
#      true
#    else
#      false
#    end
#  end
  
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