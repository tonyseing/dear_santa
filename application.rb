require 'sinatra'
require 'pry'
require 'pony'
require 'yaml'
require 'pg'
require 'mongoid'
require 'json'



configure do
  Mongoid.load!('./config/mongoid.yml', :development)

end

email_settings = YAML.load_file(File.open "./config/email.yml")


class Message
  include Mongoid::Document

  field :firstname, :type => String
  field :lastname, :type => String
  field :from_email, :type => String
  field :parent_email, :type => String
  field :content, :type => String
end


get '/' do
  erb :index
end


post '/write_santa' do
  content_type :json
  binding.pry
  message = params[:message]
  if Message.create!(params[:message])
    Pony.mail({
                :from => message[:email],
                :to => message[:parent_email],
                :via => :smtp,
                :via_options => {
                :address        => email_settings["address"],
                :port           => email_settings["port"],
                :user_name      => email_settings["username"],
                :password       => email_settings["password"],
                :authentication => :plain, # :plain, :login,
                # :cram_md5, no auth by default
                  :domain         => "ToSantaWithLove.com" ,
                  :html_body => "<html><h1>hello world</h1></html>",
                  :body => "Yo, your email client can't read html"

              }
            })
  else
    throw Exception
  end

  { :status => "ok" }.to_json
end
