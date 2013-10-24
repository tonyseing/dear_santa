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
  
  it "shows front page" do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to eq(File.open("views/index.erb").read)
  end
  

end


