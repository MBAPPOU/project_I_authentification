
require 'rack/test'
$:.unshift File.dirname(__FILE__)
require 's_auth'
require 'database'

include Rack::Test::Methods

describe 'lol' do
# Initialisation du middleware à tester
        def app
           Sinatra::Application
        end
it "should return a message if you have been logged earlier" do
                 u = User.new
                 u.login = "ok1"
                 u.password = "1ok"
                 u.save
                 post '/login' , params = {:login=>"ok1", :password => "1ok",:message=>"createaccount"}
              get '/s_auth/user/login' , rack_env={"HTTP_COOKIE" => "#{cookie}"}
              last_response.should be_ok
              last_request.cookies.should_not be nil
              last_response.body.should == "You've been already log in"
           end
           end
