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
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should create an account and if everything goes on" do
              post '/register' , params = {:login=>"ok1", :password=>"1ko",:message=>"createaccount"}          
              last_response.status.should == 200
              last_response.body.should == "Registering succeed </br></br> <a href=/s_auth/user/login>Log in</a>"
           end
           
           it "should return a message if an account with the same arguments exists in database" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/register' , params = {:login=>"ok1", :password=>"1ko",:message=>"createaccount"}              
              last_response.status.should == 404
              last_response.body.should  == "An account with these arguments already exists </br></br> <a href=/s_auth/user/register>Register</a> "
           end
           
           it "should redirect you on register page when no password or no login set" do
              post '/register' , params = {:login=>"ok1",:password => "",:message=>"createaccount"}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/user/register'
              last_request.query_string.should == "message=failed"
           end
        end
        
        context "to log somebody" do
           it "should return a formular" do
              get '/s_auth/user/login'
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should redirect you on home page if you were logged earlier" do
              u = User.new
              u.login = "ok1"
              u.password = "1ok"
              u.save
              post '/login' , params = {:login=>"ok1", :password => "1ok",:message=>"",:backup_url => ""}
              cookie = last_response["Set-Cookie"]
              get '/s_auth/user/login' , rack_env={"HTTP_COOKIE" => "#{cookie}"}
              last_request.cookies.should_not be nil
              last_response.should be_redirect
              follow_redirect!
              last_response.body.should == "Welcome \"ok1\" </br></br> <a href=\"/s_auth/protected/list_Appli\">Applications list</a> </br> <a href=\"/s_auth/protected/usedApplis\">Used applications</a> </br> <a href=\"/s_auth/application/register\">Register an application</a> </br>  <a href=\"/s_auth/protected/delete_Appli\">delete an application</a> </br> <a href=\"/s_auth/protected/disconnect\">Disconnect</a>"
           end
           
           it "should redirect you on home page if everything goes on" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>"",:backup_url => ""}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/s_auth/protected"
           end
           
           it "should redirect you on login page if it doesn't know login,password or if login or password are empty" do
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/user/login'
              last_request.query_string.should == "message=failed"
           end
           
        end
        
        context "to register an application" do
           it "should return a secret if everything goes on" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              post '/application', params = {:application_name => "lvmh"}
              last_response.status.should == 200
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
              a.author = "ken"
              a.save
              post '/application', params = {:application_name => "APPLI1" ,:backup_url => ""}
              last_response.status.should == 404
              last_response.body.should == "Saving failed : An application with this name has been already registered  </br></br> <a href=\"/s_auth/application/register\">Register an application</a>  <a href=\"/s_auth/protected\">Back</a>"
           end
              
           it "should redirect you on register application page if Field application is empty" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.author = "ken"
              a.save
              post '/application', params = {:application_name => "", :backup_url => ""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/application/register'
              last_request.query_string.should == "message=application_empty"
              last_response.body.should_not be nil
           end
        end
        
        
        context "to delete an application" do
           it "should redirect you on applications list" do
              u = User.new
              u.login = "ok1"
              u.password = "1ko"
              u.save
              a = Appli.new
              a.name = "alpha"
              a.secret = 1234
              a.author = "ok1"
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              post '/s_auth/protected/delete_Appli', params = {:application => "alpha"}
              last_response.body.should == ""
              #last_response.should be_redirect
              follow_redirect!
              last_response.path.should == '/list_Appli'
              last_response.body.should_not be nil
           end
        end
        
        
        
        
        context "to authenticate somebody on knowned application" do
           it "should return a formular" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.author = "ken"
              a.save
              get '/s_auth/application/authenticate?application=APPLI1;backup_url=/test' 
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
              a.author = "ken"
              a.save
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/authenticate' , params = {:application=>"APPLI1",:login => "ok",:password=>"ok",:message => "" ,:backup_url => "/test"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/test"
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
        end
end
