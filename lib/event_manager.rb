require 'csv'
require 'google/apis/civicinfo_v2'
require 'pry'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone(phone)
  phone = phone.to_s.delete('^0-9')
  return 'N/A' unless phone.length == 10 || (phone.length == 11 && phone[0] == '1')

  phone[(phone.length - 10)..10]
end

def clean_datetime_object(date_string)
  # date_string #=> "11/17/08 19:41"
  DateTime.strptime(date_string, '%m/%d/%y %k:%M')
rescue
  'No registration time available'
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def make_personalized_letter(id, personal_letter)
  Dir.mkdir 'output' unless Dir.exist? 'output'
  filename = "output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.write personal_letter
  end
end

puts 'Event Manager Initialized!'

small_data_path = 'event_attendees.csv'

contents = CSV.open small_data_path, headers: true, header_converters: :symbol
template_letter = ERB.new File.read 'form_letter.erb'
registration_dates = []

contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode row[:zipcode]
  phone = clean_phone row[:homephone]
  registration_dates << clean_datetime_object(row[:regdate])
  p phone
  legislators = legislators_by_zipcode zipcode
  id = row[0]
  personal_letter = template_letter.result(binding)

  make_personalized_letter(id, personal_letter)
end

puts registration_dates
puts "\n Hour | Registered"
registration_dates.map(&:hour).tally.sort.each { |pair| puts "#{pair[0].to_s.rjust(2, '0')}:00 | #{pair[1]}"}
puts "\n  Weekday | Registered"
registration_dates.map(&:wday).tally.sort.each { |pair| puts "#{DateTime::DAYNAMES[pair[0]].rjust(9, ' ')} | #{pair[1]}"}
