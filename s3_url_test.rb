require 'rubygems'
require 'aws-sdk'
require 'pp'

$s3 = AWS::S3.new(
  :access_key_id => '',
  :secret_access_key => '')

farm = ""
version = ""
env = "dev"

$environment = YAML::load(File.open("../conf/environment.yaml"))

bucket = $s3.buckets['']
files = bucket.objects.with_prefix("")

s3_file = Hash.new

files.each do |file|
  if file.key.split('/')[2].split('-')[1] == version
    s3_file[:zip_url] = file.url_for(:read, :expires_in => 60 * 60 * 24).to_s
    s3_file[:zip_name] = file.key.split('/').last
  elsif file.key.split('/')[2].split('-')[1] == env
    s3_file[:config_url] = file.url_for(:read, :expires_in => 60 * 60 * 24).to_s
    s3_file[:config_name] = file.key.split('/').last
  end
end

files = bucket.objects.with_prefix("")
files.each(:limit => 1) do |file|
  puts file
  s3_file[:gf_url] = file.url_for(:read, :expires => 60 * 60 * 24).to_s
  s3_file[:gf_name] = file.key.split('/').last
end

puts s3_file[:gf_url]