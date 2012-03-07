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

        #context "when asking for registring" do
           #it "should return a formular" do
              #get '/s_auth/user/register'
              #last_response.status.should == 200
           #end
        #end
        before(:each) do
              User.all.each{|p| p.destroy}
              Appli.all.each{|p| p.destroy}
        end


        context "when registring somebody" do
           it "should return 200 if no problem " do
              post '/register' , params = {"login"=>"ok1", "password"=>"ok1","message"=>"createaccount"}              
              last_response.status.should == 200
           end
        
           it "should return Registring succeed if no problem " do
              post '/register' , params = {"login"=>"ok", "password"=>"ok","message"=>"createaccount"}
              last_response.body.should == "Registring succeed"
           end
                                 
           it "should redirect you on register page if problem " do
              post '/register' , params = {"login"=>"ok", "password"=>"ok","message"=>""}
              last_response.status.should == 302
           end
           
           it "should return Registring failed if problem " do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/register' , params = {"login"=>"ok", "password"=>"ok","message"=>"createaccount"}
              last_response.body.should == "An account with these arguments already exists"
           end
           
        end
        
        
        context "when authenticate somebody" do
           it "should return auth succeed if no problem" do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/login', params = {"login"=>"ok", "password"=>"ok","message"=>""}
              last_response.body.should == "Authentification succeed"
           end
           
           it "should redirect you on login page if problem" do
              post '/login', params = {"login"=>"ok", "password"=>"lfd","message"=>""}
              last_response.status.should == 302
           end
        end
        
        
        context "when registring an application" do
          # it "should return a secret to the application's administrator " do
              #get '/s_auth/application/register'
              #last_response.status.should == 200
           #end
           
           it "should return saving succeed if no problem " do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              post '/application', params = {"login"=>"ok", "password"=>"ok",:appli_name => "APPLI1"}
              last_response.body.should == "Saving succeed"
           end
           
           it "should return Saving failed : this appli have already been registered if problem " do
              u = User.new
              u.login = "ok"
              u.password = "ok"
              u.save
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              post '/application', params = {"login"=>"ok", "password"=>"ok",:appli_name => "APPLI1"}
              last_response.body.should == "Saving failed : this appli have already been registered"
           end
                    
        end
        
        
        context "when authenticating somebody on knowned application" do
           
           it "should return Le parametre de redirection est vide if backup_url not sets" do
              a = Appli.new
              a.name = "APPLI1"
              a.secret = "1234"
              a.save
              get '/s_auth/application/authenticate?APPLI1;'
              last_response.body.should == "Le parametre de redirection est invalide"
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
              post '/authenticate' , params = {"login" => "ok","password"=>"ok",:message => "" ,:backup_url => "/localhost:3289/protected"}
              last_response.status.should == 500
           end

        end

        
        context "when authenticating somebody on unknowned application" do
           it "should return Unknow application : APPLI1 if Authentification service does'nt know this application" do
              get '/s_auth/application/authenticate?APPLI1;/localhost:3289/protected'
              last_response.body.should == "Unknow application : APPLI1"
           end
           
        end
        

end
