require 'sinatra'
require 'pry'
require 'mail'
require 'pony'
require 'yaml'
require 'mongoid'
require 'json'
require 'securerandom'
require 'redis'
require 'resque'


configure do
  Mongoid.load!('./config/mongoid.yml', :development)

  redis_url = "redis://pub-redis-18819.us-east-1-1.1.ec2.garantiadata.com:18819"
  uri = URI.parse(redis_url)
  Resque.redis = Redis.new(:host => uri.host, :port => uri.port, :password => "eiV5ClQyFg4vTfLm")
  set :redis, redis_url
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


class EmailJob
  @queue = :email_serve
  
  def self.perform(message, settings)
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
      binding.pry
      Resque.enqueue(EmailJob, @email, email_settings)
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
      Resque.enqueue(EmailJob, @email, email_settings)
    end
  else
    throw Exception
  end

  { :id => @message.id, :secret => @message.secret }.to_json
end



