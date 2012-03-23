$:.unshift File.dirname(__FILE__)
require 'rack/test'
require 's_auth'

include Rack::Test::Methods

describe 'Authentification server' do

        # Initialisation du middleware à tester
        def app
           Sinatra::Application
        end
        
         before do
            @user = double(User)
            @application = double(Appli)
            @auth = double(Authentification)
            
            Appli.stub(:new).and_return(@application)
            User.stub(:new).and_return(@user)
            Authentification.stub(:new).and_return(@auth)
            
            User.stub(:find_by_id).and_return(@user)
            
            
            @user.stub(:password=)
            @user.stub(:login=)
            @user.stub(:save!)
            @user.stub(:destroy)
            @user.stub(:id).and_return(1)
            
            
            @application.stub(:name=)
            @application.stub(:secret=)
            @application.stub(:author=)
            @application.stub(:save!)
            @application.stub(:destroy)
            @application.stub(:id).and_return(1)
            @application.stub(:secret).and_return(1234)
            
            @auth.stub(:user=)
            @auth.stub(:application=)
            @auth.stub(:save!)
        end

        context "to register somebody" do
           it "should return a formular" do
              get '/users/new'
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should create an account and if everything goes on" do
              User.stub(:find_by_login).and_return(nil)
              @user.stub(:password).and_return("1ko")
              post '/users' , params = {:login=>"ok", :password=>"1ko",:backup_url=>"",:message=>""}          
              last_response.status.should == 200
              last_response.body.should == "Registering succeed </br></br> <a href=/sessions/new>Log in</a>"
           end
           
           it "should return a message if an account with the same arguments exists in database" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:password).and_return("1ko")
              post '/users' , params = {:login=>"ok1", :password=>"1ko",:backup_url=>"",:message=>""}              
              last_response.status.should == 404
              last_response.body.should  == "An account with these arguments already exists </br></br> <a href=/users/new>Register</a> </br> <a href=/sessions/new>Log in</a> "
           end
           
           it "should redirect you on register page when no password or no login set" do
              post '/users' , params = {:login=>"ok1",:password => "",:backup_url=>"",:message=>""}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/users/new'
              last_request.query_string.should == "message=failed"
           end
        end
        
        context "to log somebody" do
           it "should return a formular" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              get '/sessions/new'
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should redirect you on home page if everything goes on" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:password).and_return("1ok")
              @user.stub(:id).and_return(371)
              post '/sessions' , params = {:login=>"ok1", :password=>"1ok",:backup_url => ""}              
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
           end
           
           it "should redirect you on home page if you were logged earlier" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ok")
              post '/sessions' , params = {:login=>"ok1", :password => "1ok",:backup_url => ""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              cookie = last_request.env["rack.session"]
              get '/sessions/new', rack_env = { "rack.session" => {"current_user"  => "ok1"} }
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              last_response.body.should_not be nil
           end
           
           it "should redirect you on login page if it doesn't know login,password or if login or password are empty" do
              User.stub(:find_by_login).and_return(nil)
              post '/sessions' , params = {:login=>"ok1", :password=>"1ko"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == '/sessions/new'
              last_request.query_string.should == "message=failed"
           end
        end
        
        context "to register an application" do
           it "should return a formular by targetting /applications/new" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ok")
              post '/sessions' , params = {:login=>"ok1", :password=>"1ok",:backup_url=> "" ,:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              cookie = last_request.env["rack.session"]
              get '/applications/new', rack_env = { "rack.session" => cookie }
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should return a secret if everything goes on" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ok")
              post '/sessions' , params = {:login=>"ok1", :password=>"1ok",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              cookie = last_request.env["rack.session"]
              Appli.stub(:find_by_name).and_return(nil)
              post '/applications', params = {:application_name => "lvmh"} , rack_env = { "rack.session" => cookie }
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
                      
           it "should return an error message if there is another application with this name in database" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ko")
              post '/sessions' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              cookie = last_request.env["rack.session"]
              Appli.stub(:find_by_name).and_return(@application)
              post '/applications', params = {:application_name => "APPLI1"} , rack_env = { "rack.session" => cookie }
              last_response.status.should == 404
              last_response.body.should ==  "Saving failed : An application with this name has been already registered  </br></br> <a href=\"/applications/new\">Register an application</a>  <a href=\"/users/371\">Back</a>"
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
           it "should redirect you on home page if you re application author" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ko")
              post '/sessions' , params = {:login=>"ok1", :password=>"1ko",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              Appli.stub(:find_by_name).and_return(@application)
              @application.stub(:author).and_return("ok1")
              post '/Applidelete', params = {:application => "alpha"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              last_response.body.should_not be nil
           end
           
           it "should return an error message if you re not apoplication author or service administrator" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ok")
              post '/sessions' , params = {:login=>"ok1", :password=>"1ok",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              Appli.stub(:find_by_name).and_return(@application)
              @application.stub(:author).and_return("jean")
              post '/Applidelete', params = {:application => "alpha"}
              last_response.status.should == 404
              last_response.body.should == "You're not the author of application \"alpha\" and you don't have rights to delete it </br> <a href=\"/users/371\">Back</a>"
           end
        end
        
        context "to delete a user" do
           it "should redirect you on home page if you re service administrator" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("su")
              post '/sessions' , params = {:login=>"super_user", :password=>"su"}
              last_response.should be_redirect
              follow_redirect!
              cookie = last_request.env["rack.session"]
              post '/Userdelete', params = {:user => "alpha"}, rack_env = {"rack.session" => cookie}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              last_response.body.should_not be nil
           end
           
           it "should print an error message if you re not service administrator" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ok")
              post '/sessions' , params = {:login=>"ok1", :password=>"1ok",:message=>""}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/users/371"
              cookie = last_request.env["rack.session"]
              print cookie
              get '/users/delete', rack_env = {"rack.session" => cookie}
              last_response.status.should == 403
              last_response.body.should == "forbidden"
           end
        end
        
        
        context "to authenticate somebody on known application" do
           it "should return a formular" do
              get '/APPLI1/authenticate?backup_url=/test'
              last_response.body.should_not be nil
           end
           
           it "should return an error message if it doesn't know application which is tried to authenticate you" do
              get '/APPLI1/authenticate' ,params = {:backup_url => "/test"}
              last_response.should_not be_ok
              last_response.status.should == 404
              last_response.body.should == "Unknown application APPLI1"
           end
           
           it "should redirect you in the protect part of the application that you tried to reach if authentifiaction succeed and if application known" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ko")
              Appli.stub(:find_by_name).and_return(@application)
              @application.stub(:secret).and_return(1234)
              post '/authenticate' , params = {:application=>"APPLI1",:login => "ok1",:password=>"1ko",:backup_url => "/test"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/test"
              last_response.status.should == 200
              last_response.body.should_not be nil
           end
           
           it "should redirect you on login page if authentifiaction failed and if application known" do
              User.stub(:find_by_login).and_return(@user)
              @user.stub(:id).and_return(371)
              @user.stub(:password).and_return("1ko")
              Appli.stub(:find_by_name).and_return(@application)
              @application.stub(:secret).and_return(1234)
              post '/authenticate' , params = {:application=>"APPLI1",:login => "ok",:password=>"ok",:backup_url => "/test"}
              last_response.should be_redirect
              follow_redirect!
              last_request.path.should == "/APPLI1/authenticate"
              last_request.params == {"backup_url"=>"/test", "message"=>"failed"}
           end
        end
end
