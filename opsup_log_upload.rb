require 'aws-sdk'
require 'pp'

$s3 = AWS::S3.new(
  :access_key_id => '',
  :secret_access_key => '')

data_chunk = "All hail Nicholas Cage!"

begin
  bucket = $s3.buckets['']
  obj = bucket.objects['log_file'].write("#{data_chunk}")
rescue Exception => error_name
  puts error_name
end