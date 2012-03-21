$:.unshift File.dirname(__FILE__)
require 'rack/test'
require 's_auth'

include Rack::Test::Methods

describe 'Authentification server' do

        # Initialisation du middleware à tester
        def app
           Sinatra::Application
        end
        
        #before do
              #User.all.each{|p| p.destroy}
              #Appli.all.each{|p| p.destroy}
        #end

        context "to register somebody" do
           it "should return a formular" do
              get '/users/new'
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
	      
              post '/users' , params = {:login=>"ok1", :password=>"1ko",:message=>"createaccount"}          
              last_response.status.should == 200
              last_response.body.should == "Registering succeed </br></br> <a href=/users/login>Log in</a>"
           end
           
           it "should return a message if an account with the same arguments exists in database" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
              post '/users' , params = {:login=>"ok1", :password=>"1ko",:message=>"createaccount"}              
              last_response.status.should == 404
              last_response.body.should  == "An account with these arguments already exists </br></br> <a href=/users/new>Register</a> "
           end
           
           it "should redirect you on register page when no password or no login set" do
              post '/users' , params = {:login=>"ok1",:password => "",:message=>"createaccount"}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/users/new'
              last_request.query_string.should == "message=failed"
           end
        end
        
        context "to log somebody" do
           it "should return a formular" do
              get '/users/login'
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should redirect you on home page if everything goes on" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>"",:backup_url => ""}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/ok1/profile"
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
              last_request.path.should == "/users/ok1/profile"
              cookie = last_request.env["rack.session"]
              get '/users/login', rack_env = { "rack.session" => {"current_user"  => "ok1"} }
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/ok1/profile"
              last_response.body.should_not be nil
           end
           
           it "should redirect you on login page if it doesn't know login,password or if login or password are empty" do
              User.stub(:find_by_login).and_return(nil)
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/users/login'
              last_request.query_string.should == "message=failed"
           end
        end
        
        context "to register an application" do
           it "should return a formular by targetting /applications/new" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/ok1/profile"
              cookie = last_request.env["rack.session"]
              get '/applications/new', rack_env = { "rack.session" => cookie }
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should return a secret if everything goes on" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
              Appli.stub(:find_by_name).and_return(false)
              application = double(Appli)
              Appli.stub(:new).and_return(application)
              application.stub(:name=)
              application.stub(:secret=)
              application.stub(:author=)
              application.stub(:save!)
              application.stub(:secret).and_return(12345)
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/ok1/profile"
              cookie = last_request.env["rack.session"]
              post '/applications', params = {:application_name => "lvmh"} , rack_env = { "rack.session" => cookie }
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
                      
           it "should return an error message if there is another application with this name in database" do
              user = double(User)
              User.stub(:find_by_login).and_return(user)
              user.stub(:password).and_return("1ko")
              application = double(Appli)
              Appli.stub(:find_by_name).and_return(application)
              post '/login' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/ok1/profile"
              cookie = last_request.env["rack.session"]
              post '/applications', params = {:application_name => "APPLI1"} , rack_env = { "rack.session" => cookie }
              last_response.status.should == 404
              last_response.body.should ==  "Saving failed : An application with this name has been already registered  </br></br> <a href=\"/applications/new\">Register an application</a>  <a href=\"/users/ok1/profile\">Back</a>"
           end
              
           it "should redirect you on register application page if Field application is empty" do
              post '/applications', params = {:application_name => "", :backup_url => ""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/applications/new'
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
              last_response.should be_redirect
              follow_redirect!
              post '/delete_Appli', params = {:application => "alpha"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/users/ok1/list_Appli'
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
              last_response.should be_redirect
              follow_redirect!
              post '/delete_Appli', params = {:application => "alpha"}
              last_response.status.should == 404
              last_response.body.should == "You're not the author of application \"alpha\" and you don't have rights to delete it </br> <a href=\"/users/ok1/profile\">Back</a>"
           end
        end
        
        context "to delete a user" do
           it "should redirect you on users list if you re service administrator" do
              u = double(User)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("su")
              u.stub(:destroy)
              post '/login' , params = {:login=>"super_user", :password=>"su",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              cookie = last_request.env["rack.session"]
              post '/delete_User', params = {:user => "alpha"}, rack_env = {"rack.session" => cookie}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/super_user/list_User"
              last_response.body.should_not be nil
           end
           
           it "should print an error message if you re not service administrator" do
              u = double(User)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("alpha")
              post '/login' , params = {:login=>"alpha", :password=>"alpha",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              get '/users/alpha/delete_User'
              last_response.status.should == 404
              last_response.body.should == "You don't have permissions to reach this page  </br></br>    <a href=\"/users/alpha/profile\">Back</a> "
           end
        end
        
        
        context "to authenticate somebody on known application" do
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
              get '/APPLI1/authenticate?backup_url=/test'
              last_response.body.should_not be nil
           end
           
           it "should return an error message if it doesn't know application which is tried to authenticate you" do
              Appli.stub(:find_by_name).and_return(nil)
              get '/APPLI1/authenticate' ,params = {:backup_url => "/test"}
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
           
           it "should redirect you on login page if authentifiaction failed and if application known" do
              a = double(Appli)
              u = double(User)
              auth = double(Authentification)
              User.stub(:find_by_login).and_return(u)
              u.stub(:password).and_return("ok1")
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
              last_request.path.should == "/APPLI1/authenticate"
              last_request.params == {"backup_url"=>"/test", "message"=>"failed"}
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
        end
end
