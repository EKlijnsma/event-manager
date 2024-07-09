require 'csv'
require 'erb'
require 'google/apis/civicinfo_v2'
require 'time'

def add_registration_time(time)
    registration_times[time.hour] += 1
end
def clean_phone_number(phone)
    # If the phone number is 10 digits, assume that it is good
    if phone.length == 10
        phone
    # If the phone number is 11 digits and the first number is 1, trim the 1 and use the remaining 10 digits
    elsif phone.length == 11 && phone.start_with?('1')
        phone[1..10] 
    # If the phone number is less than 10 digits, assume that it is a bad number
    # If the phone number is 11 digits and the first number is not 1, then it is a bad number
    # If the phone number is more than 11 digits, assume that it is a bad number
    else
        '0000000000'
    end
end

def clean_zipcode(zipcode)
    # to_s converts nil to an empty string
    # rjust adds padding zeroes when zipcode has missing digits, but leaves 5 or more digits as they are
    # slice removes any trailing digits after the first 5 if they occur
    zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
    civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
    civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

    begin
        legislators = civic_info.representative_info_by_address(
            address: zip,
            levels: 'country',
            roles: ['legislatorUpperBody', 'legislatorLowerBody']
        ).officials
    rescue
      'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'  
    end
end

def save_thank_you_letter(id, form_letter)
    Dir.mkdir('output') unless Dir.exist?('output')

    filename = "output/thanks_#{id}.html"

    File.open(filename, 'w') do |file|
        file.puts form_letter
    end
end

puts 'EventManager initialized'

contents = CSV.open(
    'event_attendees.csv', 
    headers: true,
    header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registration_hours = Array.new(24, 0)
registration_days = Array.new(7, 0)


contents.each do |row|
    registration_time =  Time.strptime(row[:regdate], "%m/%d/%y %H:%M")
    registration_hours[registration_time.hour] += 1
    registration_days[registration_time.wday] += 1
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)

    save_thank_you_letter(id, form_letter)
end

p registration_hours
p registration_days

