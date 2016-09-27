unless ENV['RACK_ENV'] == 'production'
  require 'dotenv'
  Dotenv.load
end

require 'aws-sdk'


s3  = Aws::S3::Client.new

app = Proc.new do |env|
  request       = Rack::Request.new(env)
  path_info     = request.path_info 
  s3_key        = path_info.gsub(/^\/+/, '')
  file_ext      = ".#{path_info.split('.').last}"
  content_type  = Rack::Mime.mime_type(file_ext)
  content       = s3.get_object(
    bucket: ENV['AWS_BUCKET'],
    key:    s3_key
  )

  [
    '200', 
    { 'Content-Type' => content_type }, 
    [ content.body.string ]
  ]
end

# Check creds
protected_app = Rack::Auth::Basic.new(app) do |username, password|
  username == ENV['AUTH_USER'] &&
  Rack::Utils.secure_compare(ENV['AUTH_PASSWORD'], password)
end

run protected_app
