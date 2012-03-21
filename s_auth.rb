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
      
  def generate_secret(bit_size=1234567)
    rand(2**bit_size - 1)
  end
  
  def generate_id(bit_size=32)
    rand(2**bit_size - 1)
  end
  
      
  def disconnect
     session["current_user"] = nil
  end

end

get '/test' do
   if params[:secret]
      body "Vous avez ete redirige apres authentification de l'application APPLI1"
   else
      status 404
      body "pas de secret"
   end
end

get '/' do
   body "#{headers["Set-Cookie"].inspect}"
end

#-----------------------------------------------------------------------------------
# Authenfication et Création de compte directement sur le service d'authentification
# pour les utilisateurs
#-----------------------------------------------------------------------------------

# Creer un compte
get '/users/new' do
   message = params[:message]
   if redirection == "%"
      redirection = ""
   end
   status 200
   erb:"users/new", :locals => {:commit => "Create Session",:post => "/users",:accueil => "Register #{message}" , :message => "createaccount",:backup_url => "#{redirection}" }
end

post '/users' do
   if (login && login != "" && password && password != "" && createaccount?)
       if User.find_by_login(login) 
           if User.find_by_login(login).password == password
               status 404
               body "An account with these arguments already exists </br></br> <a href=/users/new>Register</a> "
           else
               redirect '/user/new?message=failed'
           end
       else # Nouvel utilisateur
           u = User.new
           u.login = login
           u.password = password
           u.save!
           if redirection != "%"
               redirect "#{redirection}"
           else
               status 200
               body "Registering succeed </br></br> <a href=/users/login>Log in</a>"
           end
       end
   else
      redirect '/users/new?message=failed'
   end
end

# Se loguer
get '/users/login' do
   if current_user
       redirect "/users/#{current_user}/profile"
   else
       message = params[:message]
       status 200
       erb:"users/new", :locals => {:commit => "Log in",:post => "/login",:accueil => "Log in #{message}", :message => "" , :backup_url => "#{redirection}"}
   end
end

post '/login' do
   if login != "" && password != "" && User.find_by_login(login) &&  (User.find_by_login(login).password == password) && (not createaccount?)
        session["current_user"] = login
        if redirection != "%"
           redirect redirection
        else
           redirect "/users/#{login}/profile"
        end
   else
       redirect "/users/login?message=failed"
   end
end

# Partie protégée de l'application
get '/users/:name/profile' do
if User.find_by_login(params[:name])
   if current_user
       if redirection != "%"
          redirect "#{redirection}"
       else
          @user = current_user
          if current_user == "super_user"
             @menu = "</br></br> <a href=\"/users/#{current_user}/usedApplis\">Used applications</a> </br> <a href=\"/users/#{current_user}/administration\">Administrate</a> </br> <a href=\"/users/#{current_user}/disconnect\">Disconnect</a>"
          else
             @menu = "</br></br> <a href=\"/users/#{current_user}/list_Appli\">Applications list</a> </br> <a href=\"/users/#{current_user}/usedApplis\">Used applications</a> </br> <a href=\"/application/new\">Register an application</a> </br>  <a href=\"/users/#{current_user}/delete_Appli\">delete an application</a> </br> <a href=\"/users/#{current_user}/disconnect\">Disconnect</a>"
          end
          status 200
          erb:"users/profile", :locals => {:user => @user, :menu => @menu}
       end
   else
       redirect '/users/login' #?backup_url=/users/protected'
   end
else
   403
end
end

# Applis ayant authentifié un utilisateur
get '/users/:name/usedApplis' do
if User.find_by_login(params[:name])
   if current_user
       tmp = User.find_by_login(current_user)
       used = Authentification.find_all_by_user(tmp.id)
       reponse = []
       infos = []
       used.each do |u|
          reponse = Appli.find_all_by_id(u.application)
          reponse.each do |r|
              infos << r.name
          end
       end
       body "#{infos.inspect} </br></br> <a href=\"/users/#{current_user}/profile\">Back</a>"
   else
       redirect "/users/login" #?backup_url=/users/#{current_user}/usedApplis"
   end
else
   403
end
end

#--------------------------------------------------------
# Partie d'administration du service d'authentification
#--------------------------------------------------------
get '/users/:name/administration' do
if User.find_by_login(params[:name])
   if current_user == "super_user"
       @user = current_user
       @menu = "</br></br> <a href=\"/users/#{current_user}/list_Appli\">Applications list</a> </br> <a href=\"/users/#{current_user}/list_User\">Users list</a> </br> <a href=\"/users/#{current_user}/delete_Appli\">delete application</a> </br> <a href=\"/applications/new\">add application</a> </br> <a href=\"/users/#{current_user}/delete_User\">delete user</a> </br> <a href=\"/users/#{current_user}/register\">add user</a> </br> <a href=\"/users/#{current_user}/profile\">Back</a>"
       erb:"users/profile",:locals => {:user => @user, :menu => @menu}
   else
       redirect "/users/login" #?backup_url=/users/#{current_user}/profile"
   end
else
   403
end
end

# Supprimer une application
get '/users/:name/delete_Appli' do
if User.find_by_login(params[:name])
   if current_user
       status 200
       body eval "erb:\"applications/destroy\""
   else
       redirect "/user/login" # backup_url=/users/#{current_user}/delete_Appli"
   end
else
   403
end
end

post '/delete_Appli' do
    if params[:application]
        a = Appli.find_by_name(params[:application])
        if a
            if a.author == current_user || current_user == "super_user"
                a.destroy
                redirect "/users/#{current_user}/list_Appli"
            else
                    status 404
                    body "You're not the author of application \"#{params[:application]}\" and you don't have rights to delete it </br> <a href=\"/users/#{current_user}/profile\">Back</a>"
            end
       else
           status 404
           body "Unknow application </br> <a href=\"/users/#{current_user}/profile\">Back</a>"
       end
   else
       redirect "/users/#{current_user}/delete_Appli?message=Fied_empty"
   end
end

# Supprimmer un utilisateur
get '/users/:name/delete_User' do
if User.find_by_login(params[:name])
   if current_user
      if current_user == "super_user"
          status 200
          erb:"users/destroy"
      else
         status 404
         body "You don't have permissions to reach this page  </br></br>    <a href=\"/users/#{current_user}/profile\">Back</a> "
      end
   else
      redirect "/users/login"
   end
else
   403
end
end

post '/delete_User' do
   if params[:user]
       u = User.find_by_login(params[:user])
       if u 
           u.destroy
           redirect "/users/#{current_user}/list_User"
       else
          status 404
          body "This account doesn't exist in database"
       end
   else
      status 404
      body "Field user is empty or doesn't exist"
   end
end

# Lister les applications enregistrées
get '/users/:name/list_Appli' do
if User.find_by_login(params[:name])
   if current_user
       applis = []
       Appli.all.each{|p| applis << p.name}
       body "Applications List : #{applis.inspect}    </br></br>    <a href=\"/users/#{current_user}/profile\">Back</a>"
   else
       redirect '/users/login' #?backup_url=/users/#{current_user}/list_Appli'
   end
else
   403
end
end

# Lister les comptes utilisateurs enregistrés
get '/users/:name/list_User' do
if User.find_by_login(params[:name])
   if current_user == "super_user"
       user = []
       User.all.each{|u| user << u.login}
       body "Users List : #{user.inspect}    </br></br>        <a href=\"/users/#{current_user}/administration\">Back</a>"
   else
       redirect "/users/login" #?backup_url=/users/#{current_user}/list_User"
   end
else
   403
end
end

# Se déconnecter
get '/users/:name/disconnect' do
if User.find_by_login(params[:name])
   if current_user
       status 200
       disconnect
       body "You're disconnect </br></br> <a href=\"/users/#{current_user}/login\">Log in</a>"
   else
       status 404
       body "You were not connect!"
   end
else
   403
end
end


#-----------------------------------------------------------------------------------
# Enregistrement d'application
#-----------------------------------------------------------------------------------
# Enregistrer une application
get '/applications/new' do
   if current_user
       message = params[:message]
       status 200
       erb:"applications/new", :locals => {:post => "/applications",:accueil => "Register an application #{message}" , :backup_url => ""}
   else
       redirect '/users/login?backup_url=/applications/new'
   end
end


post '/applications' do
   if params[:application_name] != ""
       if Appli.find_by_name(params[:application_name])
           status 404
           body "Saving failed : An application with this name has been already registered  </br></br> <a href=\"/applications/new\">Register an application</a>  <a href=\"/users/#{current_user}/profile\">Back</a>"
       else
          a = Appli.new
          a.name = params[:application_name]
          a.author = current_user
          a.secret = generate_secret(32)
          a.save!
          status 200
          body "Saving succeed </br></br> Your secret is #{a.secret} </br> <a href=\"/users/#{current_user}/profile\">Back</a>" 
       end
   else
       redirect '/applications/new?message=application_empty'
   end         
end

#-----------------------------------------------------------------------------------
# Authentification venant d'une application
#-----------------------------------------------------------------------------------
get '/:application/authenticate' do
   message = params[:message]
   if Appli.find_by_name(params[:application]) # Application connue
        if current_user
            secret = Appli.find_by_name(params[:application]).secret
            auth = Authentification.new
            auth.user = User.find_by_login(current_user).id
            auth.application = Appli.find_by_name(params[:application]).id
            auth.save!
            if redirection != "%"
                 redirect "#{redirection}?secret=#{secret};user=#{current_user}"
            else
                body "You're have been already authenticate"
            end
        else
            if redirection != "%"
                redirection = ""
            end
            erb:"users/new", :locals => {:post => "/authenticate?application=#{params[:application]}" ,:accueil => "Log in #{message}" , :message => "" , :backup_url => "#{redirection}",:commit => "Log in"}
        end
   else
       status 404
       body "Unknown application #{params[:application]}"
   end
end

post '/authenticate' do
   application = params[:application]
   if login && login != "" && password && password != "" && User.find_by_login(login) && User.find_by_login(login).password == password
        secret = Appli.find_by_name(application).secret
        session["current_user"] = login
        auth = Authentification.new
        auth.user = User.find_by_login(current_user).id
        auth.application = Appli.find_by_name(application).id
        auth.save!
        if redirection != "%"
            redirect "#{redirection}?secret=#{secret};user=#{current_user}"
        else
            body "You're log in"
        end
   else
       redirect "/#{application}/authenticate?backup_url=#{redirection}"
       #if redirection != "%"
           #redirect "#{redirection}"
       #else
           #status 404
           #body "Authentification failed"
       #end
   end
end
