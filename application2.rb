$:.unshift File.dirname(__FILE__)
require 'sinatra'

set :port, 4569           
use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 2592000,
                           :path => '/',
                           :secret => 'super_user'

helpers do

def current_user2
   session["user"]
end

def user
   params[:user]
end

def disconnect2
   session["user"] = nil
end

end

get '/welcome' do
   if current_user2
       redirect '/appli2/protected'
   else
       body "Bienvenue sur L'application Number 2 <a href=\"http://localhost:4567/appli2/authenticate?backup_url=http://localhost:4569/appli2/protected\">Log in</a>"
   end
end

get '/appli2/protected' do
   if current_user2
       body "Welcome #{params[:user]}  <a href=\"/appli2/disconnect\">Disconnect</a>"
   else
       if params[:secret] = 4321
           session["user"] = user
           body "Welcome #{user}  <a href=\"/appli2/disconnect\">Disconnect</a>"
       else
           status 404
           body "Authentification failed <a href=\"http://localhost:4567/appli2/authenticate?backup_url=http://localhost:4569/appli2/protected\">Log in</a>"
       end
   end
end

get '/appli2/disconnect' do
    if current_user2
        disconnect2
        body "Good bye  <a href=\"http://localhost:4567/appli2/authenticate?backup_url=http://localhost:4569/appli2/protected\">Log in</a>"
    else
        status 404
        body "Nobody was connected"
    end
end
