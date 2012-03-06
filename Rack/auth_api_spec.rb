$:.unshift File.dirname(__FILE__)
require 'auth_api'
require 'rack/test'

include Rack::Test::Methods

describe AuthApi do

  def app 
      app = Rack::Builder.app do
         use AuthApi
         run lambda{|env| [200, {'env' => env}, ["hello!"]]}
      end
  end

context "when no cookie" do
   it "should return <<unknow>> if user don't exit in database" do
      post '/sessions' , params={"login"=>"ok","password"=>"ok","backup_url"=>"","message"=>""}
      last_request.headers["authentification"].should_be "unknow"
   end
   
   it "should returnn <<true>> if user exist in database"  do
      post '/sessions' , params={"login"=>"ok","password"=>"ok","backup_url"=>"","message"=>""}
      last_request.headers["authentification"].should be "true"
   end
end



context "when cookie" do
   it "should return <<unknow>> if your cookie is not authicate in AuthApi" do
      get '/s_auth/user/login' , rack_env={"HTTP_COOKIE"=>"name=name"}
      last_request.headers["authentification"].should_be "unknow"
   end

   it "should return <<true>> if your cookie is not authicate in AuthApi" do
      AuthApi.add("name=name")
      get '/s_auth/user/login' , rack_env={"HTTP_COOKIE"=>"name=name"}
      last_request.headers["authentification"].should_be "true"
   end

end
  
  
  
end
