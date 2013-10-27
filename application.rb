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
  field :secret

  embeds_one :response
end

class Response
  include Mongoid::Document
  include Mongoid::Timestamps

  field :content
  embedded_in :message
end


def authenticate_parent(id, secret)
  Message.where({:id => id, :secret => secret }).exists?
end

def random_secret
  SecureRandom.urlsafe_base64
end

def send_email(message, settings)
  Pony.mail({
                :from => message[:from],
                :to => message[:to],
                :via => :smtp,
                :via_options => {
                  :address        => settings["address"],
                  :port           => settings["port"],
                  :user_name      => settings["username"],
                  :password       => settings["password"],
                  :authentication => :plain, # :plain, :login,
                  # :cram_md5, no auth by default
                  :domain         => "ToSantaWithLove.com" 
                },
                :subject => message[:subject],
                :html_body => erb(message[:template]),
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
    begin
      # emails parent
      @email = { :from => "elves@ToSantaWithLove.com", :to => @message.email, :subject => "Hello #{@message.parent_email}, your child #{@message.firstname} wants to correspond with Santa. Do you want to help your child live out his or her dream?", :content => @message.content, :params => @message, :template => :email }
      send_email(@email, email_settings)
    end
  else
    throw Exception
  end

  { :id => @message.id, :secret => @message.secret }.to_json
end

get '/santa/reply/:id' do
  unless authenticate_parent(params[:id], params[:secret].to_s)
    # direct user to an informative page for adults
    redirect '/santa/adults'
  end
  
  @child_message = Message.find(params[:id])
  erb :reply
end

post '/santa/reply/:id' do
  @message = Message.find(params[:id])

  unless authenticate_parent(params[:id], @message.secret)
    # direct user to an informative page for adults
    redirect '/santa/adults'
  end

  @message.response = params[:response]

  if @message.response.save!
    begin
      # emails parent
      @email = { :from => "Santa@ToSantaWithLove.com", :to => @message.email, :subject => "placeholder subject", :content => @message.response.content, :params => @message, :template => :reply_email }
      send_email(@email, email_settings)
    end
  else
    throw Exception
  end

  { :id => @message.id, :secret => @message.secret }.to_json
end


get '/santa/adults' do
  # stub for adult information page
  # shoudl be prefaced with
  # to come later
  "stub - to be site info for adults"
end
