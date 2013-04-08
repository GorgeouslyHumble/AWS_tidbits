require 'aws-sdk'
require 'pp'

$s3 = AWS::S3.new(
  :access_key_id => '',
  :secret_access_key => '')

    begin
      urls = Array.new
      bucket = $s3.buckets['']
      files = bucket.objects.with_prefix('user_data_scripts')

      files.each do |file|
        urls << file.url_for(:read, :expires_in => 60 * 60 * 24).to_s
      end
    rescue Exception => error_name
      #LoggingControl::log('deployment_control', error_name)
    end

    puts urls[0]
    puts urls[2]
