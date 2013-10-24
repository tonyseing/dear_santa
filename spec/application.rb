require 'rspec'
require 'pry'
require 'rack/test'
require './application.rb'
require 'rack'
require 'json'



  

describe 'The TSWL app' do
  include Rack::Test::Methods

  test_message = {
    :firstname => "Tester-First",
    :lastname => "Tester-Last",
    :email => "tonyseing+test@gmail.com",
    :parent_email => "tonyseing+test@gmail.com",
    :content => "This is test content"
  }
  
  def app
    Sinatra::Application.new
  end


  describe 'GET /' do
    it "shows front page" do
      get '/'
      expect(last_response).to be_ok
      expect(last_response.body).to eq(File.open("views/index.erb").read)
    end
  end

  describe 'POST /santa/write' do
    it "sends an email to parent and save message to database" do
      post '/santa/write', params = { :message => test_message } 
      expect(last_response).to be_ok
    end
  end

  describe 'GET /santa/reply/:id' do
    it "shows a reply page for user when id and secret are correct" do
      post '/santa/write', params = { :message => test_message }
      
      id = JSON.parse(last_response.body)["id"]
      secret = JSON.parse(last_response.body)["secret"]
      get "/santa/reply/#{id}?secret=#{secret}"
      expect(last_response).to be_ok
      expect(last_response.body).to eq(File.open("views/reply.erb").read)
    end

    it "directs user to an info page when id or secret are incorrect" do
    end
  end

=begin  
  it "shows a page for adults when secret is correct for a message id" do
    
  end

  it "redirects adult to an informational page when secret is not correct for a message id" do
    get '/santa/write/:id'
    binding.pry
    expect(last_response).to be_ok
    expect(last_response.body).to eq(File.open("views/index.erb").read)
    response.should redirect_to "/santa/adults"
  end

=end
  
end


