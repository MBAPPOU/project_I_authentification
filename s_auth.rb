$:.unshift File.dirname(__FILE__)
require 'sinatra'
require 'database'
require 'user'
require 'appli'

helpers do
  

  def current_user(word)
    session[word]
  end

  def cookies
     request.cookies
  end
  
  def redirection
     params[:backup_url] if (params[:backup_url] != "")
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
  
  def generate_secret(bit_size=32)
    rand(2**bit_size - 1)
  end
  
  def cookie
     id = "cookie#{generate_secret}"
     cookies[id] = generate_secret
     cookies[id]
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
   if current_user(password)
       status 200
       body "deja connecte"
   else
       status 200
       erb:"sessions/new", :locals => {:post => "/login",:accueil => "Log in", :message => "" , :backup_url => ""}
   end
end

post '/register' do
   if createaccount?
       if (User.find_by_login(login) && User.find_by_password(password) && User.find_by_login(login).login == User.find_by_password(password).login)
           status 404
           body "An account with these arguments already exists"
       else
               u = User.new
               u.login = params[:login]
               u.password = params[:password]
               u.save
               status 200
               body "Registring succeed"
       end
   else
       status 404
       body "Registring failed"
       sleep 3
       redirect '/s_auth/user/register'
   end
end

post '/login' do
   if  (User.find_by_login(login) &&  User.find_by_login(login).password == password && params[:message] != "createaccount")
       session[password] = login
       status 200
       headers \
       "Set-Cookie" => "#{cookie}"
       body "Authentification succeed"
   else
      status 404
      body "Authentification failed"
      sleep 3
      redirect '/s_auth/user/login'
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
   if (Appli.find_by_name(application))
       status 404
       body "Saving failed : this appli have already been registered"    
   else
       a = Appli.new
       a.name = params[:appli_name]
       a.secret = generate_secret
       a.save
       status 200
       body "Saving succeed" #. Your secret is : #{a.secret}"
   end
end

#-----------------------------------------------------------------------------------
# Authentification venant d'une application
#-----------------------------------------------------------------------------------

get '/s_auth/application/authenticate' do
   application , backup_url = request.query_string.split(';')
   if (Appli.find_by_name(application))
       if (backup_url && backup_url != "")
           status 404
           erb:"sessions/new" , :locals => {:post => "/authenticate?#{application}" ,:accueil => "Log in" ,:message => "" ,:backup_url => "#{backup_url}"} 
       else
           status 404
           body "Le parametre de redirection est invalide"
       end
   else
        status 404
        body "Unknow application : #{application}"
   end
end


#env = request.env
#env.delete("url_appli")
#headers.delete("secret_appli")
#env.delete("authentification")
#env.delete("appli_save")


post '/authenticate' do
   application = request.query_string
   if (User.find_by_login(login) && User.find_by_login(login).password == password)
        secret = Appli.find_by_name(application).secret
        redirect "#{redirection}?#{secret}"
   else
        status 404
        body "Authentification failed"
   end
end













