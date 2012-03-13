$:.unshift File.dirname(__FILE__)
require 'sinatra'
require 'database'
require 'user'
require 'appli'
#require_relative 'Rack/rack_cookie_session'
#require_relative 'Rack/rack_session'


use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 2592000,
                           :secret => 'super_user'
                           
#use Rack::Session::Pool, :expire_after => 2592000

#use RackCookieSession
#use RackSession

helpers do

  def current_user
    session["current_user"]
  end

  def cookies
     request.cookies["s_authcookie"]
  end
  
  def redirection
     params[:backup_url] 
  end
  
  def createaccount?
     params[:message] == "createaccount"
  end 
  
  def password
     params[:password]
  end
  
  def login
     params[:login]
  end
   
  def disconnect
    session["current_user"] = nil
  end
  
  def generate_secret(bit_size=1234567)
    rand(2**bit_size - 1)
  end
  
  def generate_id(bit_size=32)
    rand(2**bit_size - 1)
  end
  
  def auth
     
  end
    
  def disconnect
     session["current_user"] = nil
  end

end

#get '/test' do
   #body "#{request.env}"
#end


get '/test' do
   if params[:secret]
      body "Vous avez ete redirige apres authentification de l'application APPLI1"
   else
      status 404
      body "pas de secret"
   end
end

get '/' do
   if current_user == "super_user"
      if redirection
           redirect "#{redirection}" #if redirection != "/" or redirection != ""
       else
           body "Welcome #{current_user} \n \n <a href=\"/disconnect\">Disconnect</a> \n <a href=\"/administration\">Administrate</a>"
       end
   else
       if redirection
           redirect "#{redirection}" 
       else
           body "Welcome #{current_user} \n \n <a href=\"/disconnect\">Disconnect</a>"
       end
   end
end

#-----------------------------------------------------------------------------------
# Authenfication et Création de compte directement sur le service d'authentification
# pour les utilisateurs
#-----------------------------------------------------------------------------------

get '/s_auth/user/register' do
   message = params[:message]
   status 200
   erb:"sessions/new", :locals => {:commit => "Create Session#{message}",:post => "/register",:accueil => "Register now" , :message => "createaccount" , :backup_url => ""}
end

get '/s_auth/user/login' do
   if current_user
           if current_user == "super_user"
                if redirection != ""
                    redirect "#{redirection}" #if redirection != "/" or redirection != ""
                else
                    body "Welcome #{current_user} \n \n <a href=\"/disconnect\">Disconnect</a> \n <a href=\"/administration\">Administrate</a>"
                end
           else
               if redirection != ""
                   redirect "#{redirection}" 
               else
                   body "Welcome #{current_user} \n \n <a href=\"/disconnect\">Disconnect</a>"
               end
           end
   else
       message = params[:message]
       status 200
       erb:"sessions/new", :locals => {:commit => "Log in#{message}",:post => "/login",:accueil => "Log in", :message => "" , :backup_url => "#{redirection}"}
   end
end

post '/register' do
   if (login && login != "" && password && password != "" && createaccount?)
       if (User.find_by_login(login) && User.find_by_login(login).password == password)
           status 404
           body "An account with these arguments already exists"
       else # Nouvel utilisateur
           u = User.new
           u.login = login
           u.password = password
           u.save
           status 200
           body "Registering succeed <a href=/s_auth/user/login>Log in</a>"
       end
   else
      redirect '/s_auth/user/register?message=:Regsistering failed'
   end
end

post '/login' do
    if User.find_by_login(login) &&  (User.find_by_login(login).password == password) && (not createaccount?)
        session["current_user"] = login
        if current_user == "super_user"
             if redirection != ""
                 redirect "#{redirection}" #if redirection != "/" or redirection != ""
             else
                 body "Welcome #{current_user} \n \n <a href=\"/disconnect\">Disconnect</a> \n <a href=\"/administration\">Administrate</a>"
             end
        else
           if redirection != ""
               redirect "#{redirection}" 
           else
              body "Welcome #{current_user} \n \n <a href=\"/disconnect\">Disconnect</a>"
           end
        end
   else
       redirect '/s_auth/user/login?message=:Authentification failed'
   end
end

get '/administration' do
   if current_user == "super_user"
       body "<a href=\"/list_Appli\">Applications list</a> \n <a href=\"/list_User\">Users list</a> <a href=\"/delete_Appli\">delete application</a> <a href=\"/delete_User\">delete user</a>"
   else
       redirect '/s_auth/user/login?backup_url=/administration'
   end
end

get '/delete_Appli' do
   if current_user == "super_user"
       status 200
       erb:"destroy" , :locals => {:accueil => "Delete an application" , :thing => "application" , :backup_url => "", :post => "/delete_Appli"}
   else
       redirect '/s_auth/user/login?backup_url=/delete_Appli'
   end
end

post '/delete_Appli' do
   if params[:application]
       if Appli.find_by_name(params[:application])
           Appli.find_by_name(params[:application]).destroy
           redirect "/list_Appli"
       else
           status 404
           body "This application doesn't exist in database"
       end
   else
       status 404
       body "Field application is empty or doesn't exist"
   end
end

get '/delete_User' do
   if current_user == "super_user"
       status 200
       erb:"destroy" , :locals => {:accueil => "Delete a user" , :thing => "user" , :backup_url => "", :post => "/delete_User"}
   else
       redirect '/s_auth/user/login?backup_url=/delete_User'
   end 
end

post '/delete_User' do
   if params[:user]
       u = User.find_by_name(params[:user])
       if u 
           u.destroy
           redirect "/list_User"
       else
          status 404
          body "This account doesn't exist in database"
       end
   else
      status 404
      body "Field user is empty or doesn't exist"
   end
end

get '/list_Appli' do
   if current_user
       applis = []
       Appli.all.each{|p| applis << p.name}
       body "Applications List : #{applis.inspect}        <a href=\"/administration\">Back</a>"
   else
       redirect '/s_auth/user/login?backup_url=/list_Appli'
   end
end

get '/list_User' do
   if current_user == "super_user"
       user = []
       User.all.each{|u| user << u.login}
       body "Users List : #{user.inspect}            <a href=\"/administration\">Back</a>"
   else
       redirect '/s_auth/user/login?backup_url=/list_User'
   end
end

get '/disconnect' do
   if current_user
       status 200
       disconnect
       body "You're disconnect \n \n <a href=\"/s_auth/user/login\">Log in</a>"
   else
       status 404
       body "You were not connect!"
   end
end



#-----------------------------------------------------------------------------------
# Enregistrement d'application
#-----------------------------------------------------------------------------------

get '/s_auth/application/register' do
   message = params[:message]
   status 200
   erb:"applications/new", :locals => {:post => "/application",:accueil => "Register an application#{message}" , :backup_url => ""}
end

post '/application' do
   if  (User.find_by_login(login) &&  (User.find_by_login(login).password == password))
       session["current_user"] = login
       if params[:appli_name]
            if (Appli.find_by_name(params[:appli_name]))
                status 404
                body "Saving failed : An application with this name has been already registered"   
            else
                a = Appli.new
                a.name = params[:appli_name]
                a.secret = generate_secret
                a.save
                status 200
                body "Saving succeed : your secret is #{a.secret}"
            end
       else
           redirect '/s_auth/application/register?message=:Field Application is empty'
       end
   else
       redirect '/s_auth/application/register?message=:Authentification failed'
   end            
end

#-----------------------------------------------------------------------------------
# Authentification venant d'une application
#-----------------------------------------------------------------------------------
get '/s_auth/application/authenticate' do
   application = params[:application]
   if Appli.find_by_name(application) # Application connue
        if current_user
            if redirection != ""
                 secret = Appli.find_by_name(application).secret
                 redirect "#{backup_url}?secret=#{secret}"
            else
                 body "You're have been already authenticate"
            end
        else
            if redirection != ""
                status 200
                erb:"sessions/new", :locals => {:post => "/authenticate?application=#{application}" ,:accueil => "Log in" , :message => "" , :backup_url => "#{redirection}"}
            else
                status 200
                erb:"sessions/new", :locals => {:post => "/authenticate?application=#{application}" ,:accueil => "Log in" , :message => "" , :backup_url => ""}
            end
        end
   else
       status 404
       body "Unknown application #{application}"
   end
end

post '/authenticate' do
   application = params[:application]
   if User.find_by_login(login) && User.find_by_login(login).password == password
        secret = Appli.find_by_name(application).secret
        session["current_user"] = login
        if redirection != ""
            redirect "#{redirection}?secret=#{secret}"
        else
            body "You're log in"
        end
   else
       if redirection != ""
           redirect "#{redirection}"
       else
           status 404
           body "Authentification failed"
       end
   end
end
