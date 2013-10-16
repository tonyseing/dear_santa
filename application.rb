require 'sinatra'
require 'pry'
require 'slim'
require 'pony'
require 'yaml'
require 'pg'

email_settings = YAML.load_file('./config/email.yml')
db = YAML.load_file('./config/db.yml')

get '/' do
  slim :index
end

post '/write_santa' do
  
  Pony.mail({
              :to => params[:parent_email],
              :via => :smtp,
              :via_options => {
                :address        => 'smtp.sendgrid.net',
                :port           => '25',
                :user_name      => 'tonyseing',
                :password       => 'tingold7',
                :authentication => :plain, # :plain, :login,
                # :cram_md5, no auth by default
                :domain         => "localhost.localdomain" # the
                # HELO domain provided by the client to the server
              }
            })

  redirect_to ''
end
