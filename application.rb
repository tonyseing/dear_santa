require 'sinatra'
require 'pry'
require 'pony'
require 'yaml'
require 'pg'
require 'data_mapper'

configure do
  set :app_file, __FILE__
  set :port, ENV['PORT']
end

email_settings = YAML.load_file('./config/email.yml')
db = YAML.load_file('./config/db.yml')


class Message
  include DataMapper::Resource

  property :from_email,   String
  property :parent_email, String
  property :content, Text
end


get '/' do
  erb :index
end

post '/write_santa' do
  parent_email = params[:parent_email]
  
  Pony.mail({
              :to => params[:parent_email],
              :via => :smtp,
              :via_options => {
                :address        => 'smtp.sendgrid.net',
                :port           => '25',
                :user_name      => email_settings["username"],
                :password       => email_settings["password"],
                :authentication => :plain, # :plain, :login,
                # :cram_md5, no auth by default
                :domain         => "localhost.localdomain" # the
                # HELO domain provided by the client to the server
              }
            })

  redirect_to '/'
end
