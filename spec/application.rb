require 'rspec'
require 'pry'
require 'rack/test'
require './application.rb'
require 'rack'

describe 'The TSWL app' do
  include Rack::Test::Methods

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


  it "shows a page for adults when secret is correct for a message id" do
    
  end

  it "redirects adult to an informational page when secret is not correct for a message id" do
      get '/santa/write/:id'
      expect(last_response).to be_ok
      expect(last_response.body).to eq(File.open("views/xindex.erb").read)
      response.should redirect_to "/santa/adults"
  end


end


