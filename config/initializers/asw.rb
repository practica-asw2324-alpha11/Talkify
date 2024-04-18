require 'aws-sdk-s3'

Aws.config.update({
    credentials: Aws::Credentials.new(
    ENV['AWS_ACCESS_KEY_ID'],
    ENV['AWS_SECRET_ACCESS_KEY'],
    ENV['AWS_SESSION_TOKEN']
    ),
  region: 'us-east-1'
})