require 'sinatra'
require 'pry'
require 'mail'
require 'pony'
require 'yaml'
require 'pg'
require 'mongoid'
require 'json'
require 'securerandom'


configure do
  Mongoid.load!('./config/mongoid.yml', :development)
end

email_settings = YAML.load_file(File.open "./config/email.yml")


class Message
  include Mongoid::Document
  include Mongoid::Timestamps

  field :firstname
  field :lastname
  field :email
  field :parent_email
  field :content
  field :reply
  field :secret

  has_many :responses
end

class Response
  include Mongoid::Document
  include Mongoid::Timestamps

end


def authenticate_parent(id, secret)
  binding.pry
  Message.where({:id => id, :secret => secret }).exists?
end

def random_secret
  SecureRandom.urlsafe_base64
end

def mail_parent(message, settings)
  Pony.mail({
                :from => "elves@ToSantaWithLove.com",
                :to => message.parent_email,
                :via => :smtp,
                :via_options => {
                  :address        => settings["address"],
                  :port           => settings["port"],
                  :user_name      => settings["username"],
                  :password       => settings["password"],
                  :authentication => :plain, # :plain, :login,
                  # :cram_md5, no auth by default
                  :domain         => "ToSantaWithLove.com" ,
                },
                :subject => "Hello #{message.parent_email}, your child #{message.firstname} wants to correspond with Santa. Do you want to help your child live out his or her dream?",
                :html_body => erb(:email),
                :body => "Yo, your email client can't read html."
                
              })
end

get '/' do
  erb :index
end




post '/santa/write' do
  content_type :json
  @message = Message.new(params[:message])
  @message.secret = random_secret()
  if @message.save!
    mail_parent(@message, email_settings)
  else
    throw Exception
  end

  { :status => "ok" }.to_json
end

get '/santa/reply/:id' do
  unless authenticate_parent(params[:id], params[:secret].to_s)
    # direct user to an informative page for adults
    redirect '/santa/adults'
  end
  erb :reply
end

get '/santa/adults' do
  # stub for adult information page
  # shoudl be prefaced with
  "site info for adults"
end
