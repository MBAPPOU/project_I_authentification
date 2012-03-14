$:.unshift File.dirname(__FILE__)
require 'sinatra'
require 'database'
require 'user'
require 'appli'
require 'authentification'


use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 2592000,
                           :secret => 'super_user'
helpers do

  def current_user
    session["current_user"]
  end

  def cookies
     request.cookies["s_authcookie"]
  end
  
  def redirection
     if params[:backup_url] == nil or params[:backup_url] == ""
         '%'
     else
         params[:backup_url]
     end
    
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
      if redirection != "%"
           redirect "#{redirection}"
       else
           body "Welcome #{current_user} \n \n <a href=\"/disconnect\">Disconnect</a> \n <a href=\"/administration\">Administrate</a>"
       end
   else
       if redirection != "%"
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
   erb:"sessions/new", :locals => {:commit => "Create Session",:post => "/register",:accueil => "Register #{message}" , :message => "createaccount",:backup_url => "#{redirection}" }
end

get '/s_auth/user/login' do
   if current_user
       redirect "/s_auth/protected"
   else
       message = params[:message]
       status 200
       erb:"sessions/new", :locals => {:commit => "Log in",:post => "/login",:accueil => "Log in #{message}", :message => "" , :backup_url => "#{redirection}"}
   end
end


get '/s_auth/protected' do
   if current_user == "super_user"
       if redirection != "%"
           redirect "#{redirection}" #if redirection != "/" or redirection != ""
       else
           body "Welcome #{current_user} \n \n <a href=\"/s_auth/protected/disconnect\">Disconnect</a> <a href=\"/s_auth/protected/usedApplis\">Used applications</a> <a href=\"/s_auth/protected/administration\">Administrate</a>"
       end
   else
      if redirection != "%"
           redirect "#{redirection}"
      else
          status 200
          body "Welcome #{current_user} \n \n <a href=\"/s_auth/protected/usedApplis\">Used applications</a> <a href=\"/s_auth/protected/disconnect\">Disconnect</a>"
      end
   end
end

get '/s_auth/protected/usedApplis' do
   if current_user
       used = Authentification.where(:user == current_user)
       body "#{used.inspect}  <a href=\"/s_auth/protected\">Back</a>"
   else
       redirect '/s_auth/user/login?backup_url=/s_auth/protected/usedApplis'
   end
end

post '/register' do
   if (login && login != "" && password && password != "" && createaccount?)
       if (User.find_by_login(login) && User.find_by_login(login).password == password)
           status 404
           body "An account with these arguments already exists <a href=/s_auth/user/register>Register</a> "   /s_auth/protected
       else # Nouvel utilisateur
           u = User.new
           u.login = login
           u.password = password
           u.save
           if redirection != "%"
               redirect "#{redirection}"
           else
               status 200
               body "Registering succeed <a href=/s_auth/user/login>Log in</a>"
           end
       end
   else
      redirect '/s_auth/user/register?message=failed'
   end
end

post '/login' do
    if User.find_by_login(login) &&  (User.find_by_login(login).password == password) && (not createaccount?)
        session["current_user"] = login
        redirect "/s_auth/protected"
   else
       redirect '/s_auth/user/login?message=failed'
   end
end

get '/s_auth/protected/administration' do
   if current_user == "super_user"
       body "<a href=\"/s_auth/protected/list_Appli\">Applications list</a> \n <a href=\"/s_auth/protected/list_User\">Users list</a> <a href=\"/s_auth/protected/delete_Appli\">delete application</a> <a href=\"/s_auth/application/register\">add application</a> <a href=\"/s_auth/protected/delete_User\">delete user</a> <a href=\"/s_auth/user/register\">add user</a> <a href=\"/s_auth/protected\">Retour</a>"
   else
       redirect '/s_auth/user/login?backup_url=/s_auth/protected/administration'
   end
end

get '/s_auth/protected/delete_Appli' do
   if current_user == "super_user"
       status 200
       erb:"applications/destroy"
   else
       redirect '/s_auth/user/login?backup_url=/s_auth/protected/delete_Appli'
   end
end

post '/s_auth/protected/delete_Appli' do
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

get '/s_auth/protected/delete_User' do
   if current_user == "super_user"
       status 200
       erb:"sessions/destroy"
   else
       redirect '/s_auth/user/login?backup_url=/s_auth/protected/delete_User'
   end 
end

post '/s_auth/protected/delete_User' do
   if params[:user]
       u = User.find_by_login(params[:user])
       if u 
           u.destroy
           redirect "/s_auth/protected/list_User"
       else
          status 404
          body "This account doesn't exist in database"
       end
   else
      status 404
      body "Field user is empty or doesn't exist"
   end
end

get '/s_auth/protected/list_Appli' do
   if current_user
       applis = []
       Appli.all.each{|p| applis << p.name}
       body "Applications List : #{applis.inspect}        <a href=\"/s_auth/protected/administration\">Back</a>"
   else
       redirect '/s_auth/user/login?backup_url=/s_auth/protected/list_Appli'
   end
end

get '/s_auth/protected/list_User' do
   if current_user == "super_user"
       user = []
       User.all.each{|u| user << u.login}
       body "Users List : #{user.inspect}            <a href=\"/s_auth/protected/administration\">Back</a>"
   else
       redirect '/s_auth/user/login?backup_url=/s_auth/protected/list_User'
   end
end

get '/s_auth/protected/disconnect' do
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
   erb:"applications/new", :locals => {:post => "/application",:accueil => "Register an application #{message}" , :backup_url => ""}
end

post '/application' do
   if  User.find_by_login(login) &&  (User.find_by_login(login).password == password)
       if (not current_user)
           session["current_user"] = login
       end
       if params[:application_name] != ""
            if Appli.find_by_name(params[:application_name])
                status 404
                body "Saving failed : An application with this name has been already registered  <a href=\"/s_auth/application/register\">Register an application</a>"   
            else
                a = Appli.new
                a.name = params[:appli_name]
                a.secret = generate_secret(32)
                a.save
                status 200
                body "Saving succeed : your secret is #{a.secret}" 
            end
       else
           redirect '/s_auth/application/register?message=Application_empty'
       end
   else
       redirect '/s_auth/application/register?message=failed'
   end            
end

#-----------------------------------------------------------------------------------
# Authentification venant d'une application
#-----------------------------------------------------------------------------------
get '/s_auth/application/authenticate' do
   application = params[:application]
   message = params[:message]
   if application != "" && Appli.find_by_name(application) # Application connue
        if current_user
            if redirection != "%"
                 secret = Appli.find_by_name(application).secret
                 auth = Authentification.new
                 auth.user = current_user
                 auth.application = Appli.find_by_name(application).name
                 auth.save
                 redirect "#{redirection}?secret=#{secret};user=#{current_user}"
            else
                 body "You're have been already authenticate"
            end
        else
            if redirection != "%"
                status 200
                erb:"sessions/new", :locals => {:post => "/authenticate?application=#{application}" ,:accueil => "Log in #{message}" , :message => "" , :backup_url => "#{redirection}",:commit => "Log in"}
            else
                status 200
                erb:"sessions/new", :locals => {:post => "/authenticate?application=#{application}" ,:accueil => "Log in #{message}" , :message => "" , :backup_url => ""}
            end
        end
   else
       status 404
       body "Unknown application #{application}"
   end
end

post '/authenticate' do
   application = params[:application]
   if login && login != "" && password && password != "" && User.find_by_login(login) && User.find_by_login(login).password == password
        secret = Appli.find_by_name(application).secret
        session["current_user"] = login
        if redirection != "%"
            redirect "#{redirection}?secret=#{secret};user=#{current_user}"
        else
            body "You're log in"
        end
   else
       if redirection != "%"
           redirect "#{redirection}"
       else
           status 404
           body "Authentification failed"
       end
   end
end
