require 'sinatra'
require 'Rack/auth_api'
require 'user'

use AuthApi

helpers do
end

# Utilisateurs
get '/s_auth/register' do
   erb :"sessions/new", :locals => {:accueil => "Register" , :valeur => "createaccount"}
end

get '/s_auth/login' do
   erb :"sessions/new", :locals => {:accueil => "Log in"}
end

post '/session' do
   #on lit les parametres de la requête pour savoir vers quoi rediriger si besoin
   user = params[login]
   if ( env["authentification"] == "true" ) # Authentification valide
       "Congratulations ! You're log in as #{user} !"
   else
       if ( env["authentification"] == "false" ) # Authentification invalide
          erb :"sessions/new" , :locals => {:accueil => "Authentification failed ! Log in again"}
       else 
          if ( env["authentification"] == "unknow" ) # Utilisateur inconnu
             erb :"sessions/new", :locals => {:accueil => "Create a new account", :valeur => "createaccount"}
          end
      end
   end
end



post '/session' do
   
   
end


















