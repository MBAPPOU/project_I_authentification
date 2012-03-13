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
              post '/register' , params = {:login=>"ok1", :password=>"1ko",:message=>"createaccount"}              
              last_response.status.should == 200
           end
           
           it "should return a message if an account with the same arguments exists in database" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/register' , params = {:login=>"ok1", :password=>"1ko",:message=>"createaccount"}              
              last_response.status.should == 404
              last_response.body.should  == "An account with these arguments already exists"
           end
           
           it "should return again a formular when no password or login put in the first formular" do
              post '/register' , params = {:login=>"ok1",:password => "",:message=>"createaccount"}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/user/register'
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
                 u.password = "1ok"
                 u.save
                 post '/login' , params = {:login=>"ok1", :password => "1ok",:message=>"",:backup_url => ""}
                 cookie = last_response["Set-Cookie"]
              get '/s_auth/user/login' , rack_env={"HTTP_COOKIE" => "#{cookie}"}
              last_request.cookies.should_not be nil
              last_response.body.should == "Welcome ok1 \n \n <a href=\"/disconnect\">Disconnect</a>" # Pb de test
           end
           
           it "should return a message if everything goes on" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>"",:backup_url => ""}              
              last_response.status.should == 200
              last_response.body.should  == "Welcome ok1 \n \n <a href=\"/disconnect\">Disconnect</a>"
           end
           
           it "should print an error message if it doesn't know this login" do
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/user/login'
           end
           
           it "should redirect you on login page if problem occured because of wrong password" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/login' , params = {:login=>"ok1", :password=>"ok",:message=>"",:backup_url => ""}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/user/login'
           end
        end
        
        context "to register an application" do
           it "should return a formular" do
              get '/s_auth/application/register'
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should regsiter an application and return a secret if everything goes on" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/application', params = {:login=>"ok", :password=>"ok",:appli_name => "APPLI1"}
              last_response.should be_ok
              last_response.body.should_not be nil
           end
           
           it "should return an error message if there is another application with this name in database" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              post '/application', params = {:login=>"ok", :password=>"ok",:appli_name => "APPLI1",:backup_url => ""}
              last_response.status.should == 404
              last_response.body.should == "Saving failed : An application with this name has been already registered"
           end
              
           it "should redirect you on register application page if saving failed" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              post '/application', params = {:login=>"ok", :password=>"ok",:appli_name => "",:backup_url => ""}
              last_response.should be_redirect
              last_response.path.should == '/s_auth/application/register'
              last_response.body.should_not be nil
           end
        end
        
        context "to authenticate somebody on knowned application" do
           it "should return a formular" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              get '/s_auth/application/authenticate' , params = {:application=> "APPLI1", :backup_url => "/test"}
              last_response.status.should be_ok
              last_response.body.should_not be nil
           end
           
           it "should return an error message if it doesn't know application which is tried to authenticate you" do
              get '/s_auth/application/authenticate' ,params = {:application=> "APPLI1" , :backup_url => "/test"}
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
              post '/authenticate' , params = {:application=>"APPLI1",:login => "ok",:password=>"ok",:message => "" ,:backup_url => "/test"}
              last_response.should be_redirect
              follow_redirect!
              last_response.body.should == "Vous avez ete redirige apres authentification de l'application APPLI1"
           end
           
           it "should redirect you if backup_url set and authentification failed" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/authenticate' , params = {:application=>"APPLI1",:login => "ok",:password=>"okp",:message => "" ,:backup_url => "/test"}
              last_response.should be_redirect
              last_response.status.should == 302
              follow_redirect!
              last_request.path.should == '/test'
           end
           
           it "should print you a message if backup_url not set and authentification failed" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/authenticate' , params = {:application=>"APPLI1",:login => "ok",:password=>"okp",:message => "" ,:backup_url => ""}
              last_response.status.should == 404
              last_response.body.should == "Authentification failed"
           end
        end
end
