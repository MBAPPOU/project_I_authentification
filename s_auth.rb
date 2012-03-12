$:.unshift File.dirname(__FILE__)
require 'sinatra'
require 'database'
require 'user'
require 'appli'

helpers do

  #def current_user(word)
    #session[word]
  #end

  def cookies
     request.cookies
  end
  
  def redirection
     params[:backup_url] if (params[:backup_url] != "" && params[:backup_url] != "<% backup_url %>")
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
  
  def auth(word1)
     auth[word1]["current_user"] if auth[word1]
  end
  
  def initializeauth
     session["current_user"] = "test"
     auth["auth12"] = session
  end
  
  def disconnect(cookie)
     auth.delete[cookie]
  end

end


get '/' do
   if params[:secret]
      status 200
      body "Vous avez ete redirige apres authentification de l'application APPLI1"
   else
      status 404
      body "pas de secret"
   end
end


#-----------------------------------------------------------------------------------
# Authenfication et Création de compte directement sur le service d'authentification
# pour les utilisateurs
#-----------------------------------------------------------------------------------

get '/s_auth/user/register' do
   status 200
   erb:"sessions/new", :locals => {:post => "/register",:accueil => "Register now" , :message => "createaccount" , :backup_url => ""}
end

get '/s_auth/user/login' do
   h = cookies
   if h
       h.each do |k,m| 
          if auth(m)
             status 200
             body "You've been already logged"
          end
          break if auth(m)
       end
   else
       status 200
       erb:"sessions/new", :locals => {:post => "/login",:accueil => "Log in", :message => "" , :backup_url => ""}
   end
end

post '/register' do
   if (login && password && createaccount?)
       if (User.find_by_login(login) && User.find_by_login(login).password == password)
           status 404
           body "An account with these arguments already exists"
       else # Nouvel utilisateur
               u = User.new
               u.login = login
               u.password = password
               u.save
               status 200
               # body "Registring succeed : Login : #{login} Password : #{password}"
               # sleep 3
               redirect '/s_auth/user/login'
       end
   else
       if !login # pas de login
           status 404
           erb:"sessions/new", :locals => {:post => "/register",:accueil => "Register now : Field login is empty" , :message => "createaccount" , :backup_url => ""}
       else
           if !password # pas de mpd
               status 404
               erb:"sessions/new", :locals => {:post => "/register",:accueil => "Register now : Field password is empty" , :login => "#{login}", :message => "createaccount" , :backup_url => ""}
           else # createaccount? => false
               status 404
               erb:"sessions/new", :locals => {:post => "/register",:accueil => "Register now : An error occured ! try again" , :message => "createaccount" , :backup_url => ""}
           end
       end
   end
end

post '/login' do
   if  (User.find_by_login(login) &&  (User.find_by_login(login).password == password) && !(createaccount?))
       session["current_user"] = login
       uncookie = "#{generate_id}=auth#{generate_id}"
       auth[uncookie.split('=')[1]] = session
       status 200
       headers \
       "Set-Cookie" => "#{uncookie}"
       body "Authentification succeed <a href=\"/disconnect\">Disconnect</a>"
   else
      if !(User.find_by_login(login))
          status 404
          body "This account doesn't exist"
      else
          if !(User.find_by_login(login).password == password)
             status 404
             erb:"sessions/new", :locals => {:post => "/login",:accueil => "Log in : wrong password" , :message => "" , :backup_url => ""}
          end
      end    
   end
end

get '/administration'
h = cookies
if h
   h.each do |k,m| 
          if auth(m) == "super_user"
             status 200
             body "<a href=\"/list_Appli\">Liste d'applications</a> <a href=\"/delete_Appli\">delete application</a> <a href=\"/delete_User\">delete user</a>"
          end
          break if auth(m) == "super_user"
   end
else
   status 404
   redirect '/s_auth/user/login'
end

get '/delete_Appli' do
       h = cookies
       if h
           h.each do |k,m| 
                  if auth(m) == "super_user"
                     status 200
                     erb:"destroy" , :locals => {:accueil => "Delete an application" , :thing => "application" , :backup_url => "/administration", :post => "/delete_Appli"}
                  end
                  break if auth(m) == "super_user"
           end
        else
           status 404
           redirect '/s_auth/user/login'
        end
end

post '/delete_Appli' do
   if params[:application]
        a = Appli.find_by_name(params[:application])
        if a 
            a.destroy
            redirect "#{redirection}"
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
       h = cookies
       if h
        h.each do |k,m| 
                  if auth(m) == "super_user"
                     status 200
                     erb:"destroy" , :locals => {:accueil => "Delete a user" , :thing => "user" , :backup_url => "/administration", :post => "/delete_User"}
                  end
                  break if auth(m) == "super_user"
           end
       else
           status 404
           redirect '/s_auth/user/login'
       end  
end

post '/delete_User' do
   if params[:user]
        u = Appli.find_by_name(params[:user])
        if u 
            u.destroy
            redirect "#{redirection}"
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
   applis = Appli.find_all_by_name   
   body "#{applis}"
end

get '/disconnnect' do
   h = cookies
   a = false
   if h
       h.each do |k,m| 
          if auth(m)
             status 200
             disconnect(m)
             a = true
             body "You're disconnect"
          end
          break if a
       end
   else
        status 404
        body "You were not connect!"
   end
end



#-----------------------------------------------------------------------------------
# Enregistrement d'application
#-----------------------------------------------------------------------------------

get '/s_auth/application/register' do
   status 200
   erb:"applications/new", :locals => {:post => "/application",:accueil => "Register an application" , :backup_url => ""}
end

post '/application' do
   if  (User.find_by_login(login) &&  (User.find_by_login(login).password == password))
       session["current_user"] = login
       uncookie = "generate_id=auth#{generate_id}"
       auth[uncookie.split('=')[1]] = session
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
                headers \
                "Set-Cookie" => "#{uncookie}"
                body "Saving succeed : your secret is #{a.secret}"
            end
       else
           status 404
           erb:"applications/new", :locals => {:post => "/application",:accueil => "Register an application : Field Application name is empty" ,:login => "#{login}" ,:password => "#{password}" ,:backup_url => ""}
       end
   else
      if !(User.find_by_login(login))
          status 404
          erb:"applications/new", :locals => {:post => "/application",:accueil => "Register an application : This account doesn't exist" , :backup_url => ""}
      else
          if !(User.find_by_login(login).password == password)
             status 404
             erb:"applications/new", :locals => {:post => "/application",:accueil => "Register an application : bad password" ,:login => "#{login}" , :backup_url => ""}
          end
      end    
   end            
end

#-----------------------------------------------------------------------------------
# Authentification venant d'une application
#-----------------------------------------------------------------------------------
get '/s_auth/application/authenticate' do
   h = cookies
   application = params[:application]
   backup_url = params[:backup_url]
   if Appli.find_by_name(application) # Application connue
        if h # Le client a un cookie
            h.each do |k,m| 
                 if auth(m) # on identifie le client
                     status 200
                     if backup_url
                         a = Appli.find_by_name(application).secret
                         redirect "#{backup_url}?secret=#{a}"
                     else
                         body "You're have been already authenticate"
                     end
                 end
                 break if auth(m)
            end
        else
            if backup_url 
                erb:"sessions/new", :locals => {:post => "/authenticate?application=#{application}" ,:accueil => "Log in" , :message => "" , :backup_url => "#{backup_url}"}
            else
                status 404
                erb:"sessions/new", :locals => {:post => "/authenticate?application=#{application}" ,:accueil => "Log in" , :message => "" , :backup_url => ""}
               # body "Le parametre de redirection est invalide"
            end
        end
   else
        status 404
        body "Unknown application #{application}"
   end
end

post '/authenticate' do
   application = params[:application] # application ayant sollicité l'authentification
   if (User.find_by_login(login) && User.find_by_login(login).password == password && !(createaccount?))
        secret = Appli.find_by_name(application).secret
        session["current_user"] = login
        uncookie = "generate_id=auth#{generate_id}"
        auth[uncookie.split('=')[1]] = session
        if redirection
            headers \
            "Set-Cookie" => "#{uncookie}"
            redirect "#{redirection}?secret=#{secret}"
        else
            headers \
            "Set-Cookie" => "#{uncookie}"
            body "You're log in"
        end
   else
        status 404
        body "Authentification failed"
   end
end













