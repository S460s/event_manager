require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

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

contents = CSV.open('../ss.csv', headers: true, header_converters: :symbol)
template_letter = File.read('../letter.erb')
erb_template = ERB.new template_letter

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)
  save_letter(id, form_letter)
end
