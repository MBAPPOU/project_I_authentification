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
              User.stub(:find_by_login).and_return(false)
              user = double(User)
              User.stub(:new).and_return(user)
              user.stub(:login=)
              user.stub(:password=)
              user.stub(:save!)
	      
              post '/register' , params = {:login=>"ok1", :password=>"1ko",:message=>"createaccount"}          
              last_response.status.should == 200
              last_response.body.should == "Registering succeed </br></br> <a href=/s_auth/user/login>Log in</a>"
           end
           
           it "should return a message if an account with the same arguments exists in database" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
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
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ok")
              user.stub(:login=)
              user.stub(:password=)
              user.stub(:save!)
              post '/login' , params = {:login=>"ok1", :password => "1ok",:message=>"",:backup_url => ""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/s_auth/user/protected"
              get '/s_auth/user/login', rack_env = { "rack.session" => last_request.env["rack.session"] }
              last_response.should be_redirect
              follow_redirect!
              last_response.body.should == "Welcome \"ok1\" </br></br> <a href=\"/s_auth/user/list_Appli\">Applications list</a> </br> <a href=\"/s_auth/user/usedApplis\">Used applications</a> </br> <a href=\"/s_auth/application/register\">Register an application</a> </br>  <a href=\"/s_auth/user/delete_Appli\">delete an application</a> </br> <a href=\"/s_auth/user/disconnect\">Disconnect</a>"
           end
           
           it "should redirect you on home page if everything goes on" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>"",:backup_url => ""}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/s_auth/user/protected"
           end
           
           it "should redirect you on login page if it doesn't know login,password or if login or password are empty" do
              User.stub(:find_by_login).and_return(nil)
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/user/login'
              last_request.query_string.should == "message=failed"
           end
           
        end
        
        context "to register an application" do
           it "should return a secret if everything goes on" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
              application = double(Appli)
              Appli.stub(:find_by_name).and_return(false)
              Appli.stub(:new).and_return(application)
              application.stub(:name=)
              application.stub(:secret=)
              application.stub(:author=)
              application.stub(:save!)
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/s_auth/user/protected"
              
              post '/application', params = {:application_name => "lvmh"} , rack_env = { "rack.session" => last_request.env["rack.session"] }
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
                      
           it "should return an error message if there is another application with this name in database" do
              application = double(Appli)
              Appli.stub(:find_by_name).and_return(application)
              post '/application', params = {:application_name => "APPLI1" ,:backup_url => ""}
              last_response.status.should == 404
              last_response.body.should == "Saving failed : An application with this name has been already registered  </br></br> <a href=\"/s_auth/application/register\">Register an application</a>  <a href=\"/s_auth/user/protected\">Back</a>"
           end
              
           it "should redirect you on register application page if Field application is empty" do
              post '/application', params = {:application_name => "", :backup_url => ""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/application/register'
              last_request.query_string.should == "message=application_empty"
              last_response.body.should_not be nil
           end
        end
        
        
        context "to delete an application" do
           it "should redirect you on applications list if you re application author" do
              u = double(User)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("1ko")
              a = double(Appli)
              Appli.stub(:find_by_name).and_return(a)
              a.stub(:destroy)
              a.stub(:author).and_return("ok1")
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              post '/s_auth/user/delete_Appli', params = {:application => "alpha"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/s_auth/user/list_Appli'
              last_response.body.should_not be nil
           end
           
           it "should return an error message if you re not apoplication author or service administrator" do
              u = double(User)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("1ko")
              a = double(Appli)
              Appli.stub(:find_by_name).and_return(a)
              a.stub(:author).and_return("super_user")
              a.stub(:destroy)
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              post '/s_auth/user/delete_Appli', params = {:application => "alpha"}
              last_response.status.should == 404
              last_response.body.should == "You're not the author of application \"alpha\" and you don't have rights to delete it </br> <a href=\"/s_auth/user/protected\">Back</a>"
           end
        end
        
        context "to delete a user" do
           it "should redirect you on users list if you re service administrator" do
              u = double(User)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("su")
              u.stub(:destroy)
              post '/login' , params = {:login=>"super_user", :password=>"su",:message=>""}
              post '/s_auth/user/delete_User', params = {:user => "alpha"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/s_auth/user/list_User"
              last_response.body.should_not be nil
           end
           
           it "should redirect you on login page if you re not service administrator" do
              u = double(User)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("alpha")
              post '/login' , params = {:login=>"alpha", :password=>"alpha",:message=>""}
              get '/s_auth/user/delete_User'
              last_response.status.should == 302
              last_response.headers["Location"].should == "http://example.org/s_auth/user/login?backup_url=/s_auth/delete_User"
           end
        end
        
        
        context "to authenticate somebody on knowned application" do
           it "should return a formular" do
              a = double(Appli)
              u = double(User)
              auth = double(Authentification)
              User.stub(:find_by_login).and_return(u)
              u.stub(:id).and_return(1)
              Appli.stub(:find_by_name).and_return(a)
              Authentification.stub(:new).and_return(auth)
              auth.stub(:user=)
              auth.stub(:application=)
              auth.stub(:save!)
              a.stub(:id).and_return(2)
              a.stub(:secret).and_return(12345)
              get '/s_auth/application/authenticate?application=APPLI1;backup_url=/test' 
              last_response.body.should_not be nil
           end
           
           it "should return an error message if it doesn't know application which is tried to authenticate you" do
              Appli.stub(:find_by_name).and_return(nil)
              get '/s_auth/application/authenticate' ,params = {:application=> "APPLI1" , :backup_url => "/test"}
              last_response.should_not be_ok
              last_response.status.should == 404
              last_response.body.should == "Unknown application APPLI1"
           end
           
           it "should redirect you in the protect part of the application that you tried to reach if authentifiaction succeed and if application known" do
              a = double(Appli)
              u = double(User)
              auth = double(Authentification)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("ok")
              u.stub(:id).and_return(1)
              Appli.stub(:find_by_name).and_return(a)
              Authentification.stub(:new).and_return(auth)
              auth.stub(:user=)
              auth.stub(:application=)
              auth.stub(:save!)
              a.stub(:id).and_return(2)
              a.stub(:secret).and_return(12345)
              post '/authenticate' , params = {:application=>"APPLI1",:login => "ok",:password=>"ok",:message => "" ,:backup_url => "/test"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/test"
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
        end
end
