require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'
require 'json'
require 'date'

def clean_zipcode(zip_code)
  zip_code.to_s.rjust(5, '0')[0, 5]
end

def legislators_by_zipcode(zip_code)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  legislators = civic_info.representative_info_by_address(
    address: zip_code,
    levels: 'country',
    roles: %w[legislatorUpperBody legislatorLowerBody]
  )
  legislators = legislators.officials
  l_names = legislators.map(&:name)
  l_names.join(', ')
rescue StandardError
  'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
end

def save_letter(id, letter)
  Dir.mkdir('output') unless Dir.exist?('output')
  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') { |file| file.puts letter }
end

def process_legislators
  template_letter = File.read('letter.erb')
  erb_template = ERB.new template_letter

  id = row[0]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_letter(id, form_letter)
end

def time_target(time_str)
  begin
    time = Time.strptime(time_str, '%m/%d/%y %H:%M')
  rescue StandardError
    puts 'error '
  end
  time
end

def handle_hours(hours, save = false)
  if save
    json = JSON.dump(hours)
    Dir.mkdir('output') unless Dir.exist?('output')
    File.open('output/hours.json', 'w') { |file| file.puts json }
    puts 'Hours saved!'
  else
    hours.each do |key, value|
      puts "Hour: #{key} -> #{'#' * value}"
    end
  end
end

def handle_days(days, save = false)
  if save
    json = JSON.dump(days)
    Dir.mkdir('output') unless Dir.exist?('output')
    File.open('output/days.json', 'w') { |file| file.puts json }
    puts 'Hours saved!'
  else
    days.each do |key, value|
      puts "Day: #{Date::DAYNAMES[key]} -> #{'#' * value}"
    end
  end
end

def main
  contents = CSV.open('ss.csv', headers: true, header_converters: :symbol)
  hours = Hash.new(0)
  days = Hash.new(0)

  contents.each do |row|
    name = row[:first_name]
    time = time_target(row[:regdate])
    hours[time.hour] += 1
    days[time.wday] += 1
  end
  handle_hours hours
  handle_days days
end

main
