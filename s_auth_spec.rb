require 'sinatra'
require 'rack/test'
$:.unshift File.dirname(__FILE__)
require 's_auth'

include Rack::Test::Methods

describe 'Authentification server' do

        # Initialisation du middleware à tester
        def app
           Sinatra::Application
        end


        context "when registring an application" do
           it "should return a secret to the application's administrator " do
           end
        end
        
        
        context "when authenticating somebody on knowned application" do
           it "should redirect you in the protect part of the application that you tried to reach if authentifiaction succeed" do
           end
           
           it "should also set parameters which will help you to authenticate on the requesting application" do
           end
           
           it "should redirect you on new page to create a new account if authentifiaction failed " do
           end

        end

        
        context "when authenticating somebody on unknowned application" do
           it "should return 404 error found" do
           end
           
        end
        

end
