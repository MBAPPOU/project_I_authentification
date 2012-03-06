$:.unshift File.dirname(__FILE__)
require 'sinatra'
#require 'Rack/auth_api'
require 'Rack/auth_api1'
require 'Rack/app_auth'

use AuthApi
#use AppAuth

helpers do
end

#-----------------------------------------------------------------------------------
# Authenfication et Création de compte directement sur le service d'authentification
# pour les utilisateurs
#-----------------------------------------------------------------------------------
get '/' do
   erb:"test", :locals => {:valeur => "Hello"}
end

get '/s_auth/user/register' do
   erb :"sessions/new", :locals => {:accueil => "Register" , :valeur => "createaccount" , :lien => ""}
end

get '/s_auth/user/login' do
   erb :"sessions/new", :locals => {:accueil => "Log in", :valeur => "createaccount" , :lien => ""}
end

post '/sessions' do
   body "login et password = #{env["logpass"]}  ;authentification =  #{env["authentification"]}"
end


post '/session' do
   #on lit les parametres de la requête pour savoir vers quoi rediriger si besoin
   user = params[:login]
   r_auth = env["authentification"] # retour d'authentification d'un utilisateur
   if ( r_auth == "true" ) # Authentification valide
       body "Congratulations ! You're log in as #{user} !"
   else
       if ( r_auth == "false" ) # Authentification invalide
           erb :"sessions/new" , :locals => {:accueil => "Authentification failed ! Log in again",:valeur => "" , :lien => ""}
       else 
           if ( r_auth == "unknow" ) # Utilisateur inconnu
              erb :"sessions/new", :locals => {:accueil => "Create a new account", :valeur => "createaccount" , :lien => ""}
           end
       end
   end
end

#-----------------------------------------------------------------------------------
# Enregistrement d'application
#-----------------------------------------------------------------------------------

get '/s_auth/application/new' do
   erb:"applications/new", :locals => {:accueil => "Register an application" , :lien => ""}
end

post '/application' do
   secret = env["appli_save"]
   ra_auth = env["appli_known"] # retour d'authentification d'application
   r_auth = env["authentification"]
   appli_name = params[appli_name]
   if ( ra_auth == "true" && secret ) # L'enregistrement de l'application s'est bien passé
      erb:"message" , :locals => {:message => "appli enregistree"}
#"L'enregistrement de l'application #{appli_name} s'est bien passé.Lorsque vous solliciterez de nouveau notre service pour authentifier vos utilisateurs sur votre application , ceux-ci devront vous fournir la clé secrète : secret=#{secret}.Veuillez le conserver précieusement pour votre application."}
   else # env["authentification"] == "false" ou env["authentification"] == "unknow"
       if ( r_auth == "unknow" )
           erb:"message" , :locals => {:message => "user unknown"}
           #"L'enregistrement de l'application #{appli_name} ne s'est bien passée car l'utilisateur est inconnu.Vous allez être redirigé pour créer un compte." }
           sleep(3)
           redirect '/s_auth/user/register'
       else
           if ( r_auth == "false" )
              erb:"message" , :locals => {:message => "login and password are incorrect"}
              #"L'enregistrement de l'application #{appli_name} ne s'est bien passée car login ou mot de passe incorrects.Vous allez être redirigé pour vous authentifier de nouveau."}
              sleep(3)
              redirect '/s_auth/application/new'
           end
       end
   end
end

#-----------------------------------------------------------------------------------
# Authentification venant d'une application
#-----------------------------------------------------------------------------------

get '/s_auth/application/register' do
   if  ( env["application_known"] == "true" ) # Application connue du service d'authentification
       erb :"sessions/new", :locals => {:accueil => "Log in" , :valeur => "" , :lien => ""}
   else # Application inconnue du service d'authentification
      status 404
      body "Page inconnue !"
   end
end


#env = request.env
#env.delete("url_appli")
#headers.delete("secret_appli")
#env.delete("authentification")
#env.delete("appli_save")


post '/application/authenticate' do
   if ( env["appli_known"] == "true" && env["authentification"] == "true" ) # Redirection vers une apllication
       url_appli = env["url_appli"]
       cookie = env["Set-Cookie"]
       status 304
       headers \
       "Set-Cookie" => "#{cookie}",
       "Location" => "#{url_appli}"
   else
        if ( env["appli_known"] == "false" )
           erb:"Application inconnue. Vous serez redirige vers la page d'enregistrement d'application"
           sleep (3)
           redirect '/s_auth/application/new'
       else
           "Utilisateur inconnu ou mot de passe et login incorrects "
       end
   end
end














