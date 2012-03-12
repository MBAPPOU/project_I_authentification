$:.unshift File.dirname(__FILE__)
require 'rack/test'
require 's_auth'
require 'database'

include Rack::Test::Methods

describe 'Authentification server' do

        # Initialisation du middleware à tester
        def app
           Sinatra::Application
        end
        
        before(:each) do
              User.all.each{|p| p.destroy}
              Appli.all.each{|p| p.destroy}
        end

        context "to register somebody" do
           it "should return a formular" do
              get '/s_auth/user/register'
              last_response.should be_ok
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should create an account if everything goes on" do
              post '/register' , params = {"login"=>"ok1", "password"=>"1ko","message"=>"createaccount"}              
              last_response.status.should == 302
           end
           
           it "should return a message if an account with the same arguments exists in database" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/register' , params = {"login"=>"ok1", "password"=>"1ko","message"=>"createaccount"}              
              last_response.status.should == 404
              last_response.body.should  == "An account with these arguments already exists"
           end
           
           it "should return again a formular when no password or login put in the first formular" do
              post '/register' , params = {"login"=>"ok1","message"=>"createaccount"}              
              last_response.status.should == 404
              last_response.body.should_not be nil
           end
        end
        
        context "to authenticate somebody" do
           it "should return a formular" do
              get '/s_auth/user/login'
              last_response.should be_ok
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should return a message if you have been logged earlier" do
                 u = User.new
                 u.login = "ok1"
                 u.password = "ok1"
                 u.save
                 post '/login' , params = {"login"=>"ok1", "password" => "ok1","message"=>"createaccount"}
                 last_response.headers["Set-Cookie"].should_not be nil
              get '/s_auth/user/login' , rack_env={"HTTP_COOKIE" => "#{cookie}"}
              last_response.should be_ok
              last_request.cookies.should_not be nil
              last_response.body.should == "You've been already log in"
           end
           
           it "should return a message if everything goes on" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/login' , params = {"login"=>"ok1", "password"=>"1ko","message"=>"","backup_url" => ""}              
              last_response.status.should == 200
              last_response.headers["Set_Cookie"].should_not be nil
              last_response.body.should  == "Authentification succeed <a href=\"/disconnect\">Disconnect</a>"
           end
           
           it "should print an error message if it doesn't know this login" do
              post '/login' , params = {"login"=>"ok1", "password"=>"1ko","message"=>""}              
              last_response.status.should == 404
              last_response.body.should  == "This account doesn't exist"
           end
           
           it "should return a formular if problem occured because of wrong password" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/login' , params = {"login"=>"ok1", "password"=>"ok","message"=>""}              
              last_response.status.should == 404
              last_response.body.should_not be nil
           end
        end

#-------------------------------------------------------------------------------------------------------
        
        context "to register an application" do
           it "should return a formular" do
              get '/s_auth/application/register'
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should create an application and return a secret" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/application', params = {"login"=>"ok", "password"=>"ok",:appli_name => "APPLI1"}
              last_response.headers.should_not be nil
              last_response.body.should_not be nil
           end
           
           it "should return a message if saving failed" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              post '/application', params = {"login"=>"ok", "password"=>"ok",:appli_name => "APPLI1","backup_url" => ""}
              last_response.status.should == 404
              last_response.body.should == "Saving failed : An application with this name has been already registered"
           end
              
           it "should return a message if saving failed" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              post '/application', params = {"login"=>"ok", "password"=>"ok","appli_name" => "","backup_url" => ""}
              last_response.status.should == 404
              last_response.body.should_not be nil
           end
        end
        
        context "to authenticate somebody on knowned application" do
           it "should return a formular" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              get '/s_auth/application/authenticate' , params = {"application"=> "APPLI1", "backup_url" => "/"}
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should return an error message if it doesn't know application which is tried to authenticate you" do
              get '/s_auth/application/authenticate' ,params = {"application"=> "APPLI1" , "backup_url" => "/"}
              last_response.should_not be_ok
              last_response.status.should == 404
              last_response.body.should == "Unknown application APPLI1"
           end
           
           it "should redirect you in the protect part of the application that you tried to reach if authentifiaction succeed and if application known" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/authenticate' , params = {"application"=>"APPLI1","login" => "ok","password"=>"ok",:message => "" ,:backup_url => "/"}
              last_response.headers["Set-Cookie"].should_not be nil
              last_response.should be_redirect
              follow_redirect!
              last_response.body.should == "Vous avez ete redirige apres authentification de l'application APPLI1"
           end
           
           it "should return an error message if authentification failed" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/authenticate' , params = {"application"=>"APPLI1","login" => "ok","password"=>"okp",:message => "" ,:backup_url => "/"}
              last_response.status.should == 404
              last_response.body.should == "Authentification failed"
           end
        end
end
