$:.unshift File.dirname(__FILE__)
require 'sinatra'

set :port, 4569           
enable :sessions

helpers do

def current_user
   session["user"]
end

def user
   params[:user]
end

def disconnect
   session["user"] = nil
end

end

get '/welcome' do
   if current_user
       redirect '/appli2/protected'
   else
       body "Bienvenue sur L'application Number 2 <a href=\"http://localhost:4567/appli2/authenticate?backup_url=http://localhost:4568/appli2/protected/\">Log in</a>"
   end
end

get '/appli2/protected' do
   if current_user
       body "Welcome #{params[:user]}  <a href=\"/appli2/disconnect\">Disconnect</a>"
   else
       if params[:secret] = 4321
           session["user"] = user
           body "Welcome #{user}  <a href=\"/appli2/disconnect\">Disconnect</a>"
       else
           status 404
           body "Authentification failed <a href=\"http://localhost:4567/appli2/authenticate?backup_url=http://localhost:4568/appli2/protected\">Log in</a>"
       end
   end
end

get '/appli2/disconnect' do
    if current_user
        disconnect
        body "Good bye"
    else
        status 404
        body "Nobody was connected"
    end
end
