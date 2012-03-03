$:.unshift File.dirname(__FILE__)
require 'auth_api'
require 'rack/test'

include Rack::Test::Methods

describe AuthApi do

  def app 
      app = Rack::Builder.app do
         use AuthApi
         run lambda{|env| [404, {'env' => env}, ["HELLO!"]]}
      end
  end
    
  it "should return <<unknow>> if user don't exit in database" do
     AuthApi.stub(:find).and_return(nil)
     get '/'
     last_response.headers["authentification"].should_be "unknow"
  end
  
  
  
end
