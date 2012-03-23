$:.unshift File.dirname(__FILE__)
require 'sinatra'
require 'database'
require_relative 'lib/user'
require_relative 'lib/appli'
require_relative 'lib/authentification'


use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 2592000,
                           :path => '/',
                           :secret => 'super_user'
helpers do

  def current_user
    session["current_user"]
  end
  
  def redirection
     if params[:backup_url] == nil or params[:backup_url] == ""
         '%'
     else
         params[:backup_url]
     end
  end
  
  def message
     params[:message]
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
   erb:"users/new", :locals => {:message => message,:backup_url => "#{redirection}" }
end

post '/users' do
   if (login && login != "" && password && password != "")
       if User.find_by_login(login) 
           if User.find_by_login(login).password == password
               status 404
               body "An account with these arguments already exists </br></br> <a href=/users/new>Register</a> </br> <a href=/sessions/new>Log in</a> "
           else
               redirect '/users/new?message=failed'
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
               body "Registering succeed </br></br> <a href=/sessions/new>Log in</a>"
           end
       end
   else
      redirect '/users/new?message=failed'
   end
end

# Se loguer
get '/sessions/new' do
   if current_user
       u = User.find_by_login(current_user)
       redirect "/users/#{u.id}"
   else
       status 200
       erb:"sessions/new", :locals => {:message => "#{message}" , :backup_url => redirection}
   end
end

post '/sessions' do
   if login && password
       u = User.find_by_login(login)
       if u &&  (u.password == password)
           session["current_user"] = login
           if redirection != "%"
              redirect redirection
           else
              redirect "/users/#{u.id}"
           end
       else
          redirect "/sessions/new?message=failed"
       end
   else
       redirect "/sessions/new?message=failed"
   end
end

# Partie protégée de l'application
get '/users/:id' do
    u = User.find_by_id(params[:id])
    if u
       if current_user
          @user = current_user
          if @user == "super_user"
             @menu = "</br></br> <a href=\"/users/usedApplis/#{u.id}\">Used applications</a> </br> <a href=\"/users/administration/#{u.id}\">Administrate</a> </br> <a href=\"/sessions/disconnect\">Disconnect</a>"
          else
             @menu = "</br></br> <a href=\"/applications/list\">Applications list</a> </br> <a href=\"/users/usedApplis/#{u.id}\">Used applications</a> </br> <a href=\"/applications/new\">Register an application</a> </br>  <a href=\"/applications/delete\">delete an application</a> </br> <a href=\"/sessions/disconnect\">Disconnect</a>"
          end
          status 200
          erb:"users/profile", :locals => {:user => @user, :menu => @menu}
      else
         redirect '/sessions/new'
      end
   else
       status 403
       "forbidden"
   end
end

# Applis ayant authentifié un utilisateur
get '/users/usedApplis/:id' do
   u = User.find_by_id(params[:id])
   if u
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
          body "Used Applications : #{infos.inspect} </br></br> <a href=\"/users/#{u.id}\">Back</a>"
      else
         backup = "/users/usedApplis/#{u.id}"
         redirect "/sessions/new?backup_url=#{backup}"
      end
   else
       status 403
       "forbidden"
   end
end

#--------------------------------------------------------
# Partie d'administration du service d'authentification
#--------------------------------------------------------
get '/users/administration/:id' do
        if current_user == "super_user"
             u = User.find_by_login(current_user)
             @user = current_user
             @menu = "</br></br> <a href=\"/applications/list\">Applications list</a> </br> <a href=\"/users/list\">Users list</a> </br> <a href=\"/applications/delete\">delete application</a> </br> <a href=\"/applications/new\">add application</a> </br> <a href=\"/users/delete\">delete user</a> </br> <a href=\"/users/new\">add user</a> </br> <a href=\"/users/#{u.id}\">Back</a>"
            erb:"users/profile",:locals => {:user => @user, :menu => @menu}
        else
           status 403
           "forbidden"
        end
end

# Supprimer une application
get '/applications/delete' do
        if current_user
            back = User.find_by_login(current_user).id
            status 200
            erb:"applications/destroy", :locals => {:back => back, :message => message}
        else
           redirect "/sessions/new?backup_url=/applications/delete"
        end
end

post '/Applidelete' do
    u = User.find_by_login(current_user)
    if params[:application]
        a = Appli.find_by_name(params[:application])
        if a
            if a.author == current_user || current_user == "super_user"
                a.destroy
                redirect "/applications/list"
            else
                status 404
                body "You're not the author of application \"#{params[:application]}\" and you don't have rights to delete it </br> <a href=\"/users/#{u.id}\">Back</a>"
            end
       else
           status 404
           body "Unknow application </br> <a href=\"/users/#{u.id}\">Back</a>"
       end
   else
       redirect "/applications/delete?message=Fied_empty"
   end
end

# Supprimmer un utilisateur
get '/users/delete' do
      if current_user && current_user == "super_user"
         u = User.find_by_login(current_user)
         status 200
         erb:"users/destroy", :locals => {:message => message,:back => u.id}
      else
          if not current_user
              redirect "/sessions/new"
          else
              if current_user != "super_user"
              status 403
              body "forbidden"
              end
          end
         #body "You don't have permissions to reach this page  </br></br>    <a href=\"/users/#{u.id}\">Back</a> "
      end
end

post '/Userdelete' do
   if params[:user]
       u = User.find_by_login(params[:user])
       if u 
           u.destroy
           redirect "/users/list"
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
get '/applications/list' do
   if current_user
       u = User.find_by_login(current_user)
       applis = []
       Appli.all.each{|p| applis << p.name}
       body "Applications List : #{applis.inspect}    </br></br>    <a href=\"/users/#{u.id}\">Back</a>"
   else
       redirect '/sessions/new'
   end
end

# Lister les comptes utilisateurs enregistrés
get '/users/list' do
      if current_user && current_user == "super_user"
         u = User.find_by_login(current_user)
         users = []
         User.all.each{|usr| users << usr.login}
         body "Users List : #{users.inspect}    </br></br>        <a href=\"/users/#{u.id}\">Back</a>"
      else
          if not current_user
              #redirect '/sessions/new'
          else
             status 403
             body "forbidden"
          end
         #body "You don't have rights to reach this page    </br></br>   <a href=\"/users/#{u.id}\">Back</a>"
     end
end

# Se déconnecter
get '/sessions/disconnect' do
   if current_user
       disconnect
       status 200
       
       body "You're disconnect </br></br> <a href=\"/sessions/new\">Log in</a>"
   else
       status 404
       body "You were not connect!"
   end
end


#-----------------------------------------------------------------------------------
# Enregistrement d'application
#-----------------------------------------------------------------------------------
get '/applications/new' do
   if current_user
       status 200
       erb:"applications/new", :locals => {:message => message}
   else
       redirect '/sessions/new'
   end
end


post '/applications' do
    if params[:application_name] != ""
       u = User.find_by_login(current_user)
       if Appli.find_by_name(params[:application_name])
           status 404
           body "Saving failed : An application with this name has been already registered  </br></br> <a href=\"/applications/new\">Register an application</a>  <a href=\"/users/#{u.id}\">Back</a>"
       else
          a = Appli.new
          a.name = params[:application_name]
          a.author = current_user
          a.secret = generate_secret(32)
          a.save!
          status 200
          body "Saving succeed </br></br> Your secret is #{a.secret} </br> <a href=\"/users/#{u.id}\">Back</a>" 
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
            erb :"authenticate/new",:locals => {:post => "/authenticate?application=#{params[:application]}" , :message => message , :backup_url => "#{redirection}"}
        end
   else
       status 404
       body "Unknown application #{params[:application]}"
   end
end

post '/authenticate' do
        application = params[:application]
        if application
            backup = redirection
            if login && login != "" && password && password != "" && User.find_by_login(login) && User.find_by_login(login).password == password
                secret = Appli.find_by_name(application).secret
                session["current_user"] = login
                auth = Authentification.new
                auth.user = User.find_by_login(current_user).id
                auth.application = Appli.find_by_name(application).id
                auth.save!
                if backup != "%"
                    redirect "#{backup}?secret=#{secret};user=#{current_user}"
                else
                    body "You're log in"
                end
            else
               if backup != "%"
                   redirect "/#{application}/authenticate?backup_url=#{backup}&message=failed"
               else
                   redirect "/#{application}/authenticate?message=failed"
               end
            end
        else
            "ERROR missing params[:application]"
        end
end
