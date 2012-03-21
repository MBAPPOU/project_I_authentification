$:.unshift File.dirname(__FILE__)
require 'sinatra'

set :port, 4568                          
use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 2592000,
                           :path => '/welcome',
                           :secret => 'super_user'

helpers do

def current_user1
   session["utilisateur"]
end

def user
   params[:user]
end

def disconnect1
   session["utilisateur"] = nil
end

end

get '/welcome' do
   if current_user1
       redirect '/appli1/protected'
   else
       body "Bienvenue sur L'application Number 1 <a href=\"http://localhost:4567/appli1/authenticate?backup_url=http://localhost:4568/appli1/protected\">Log in</a> "
   end
end

get '/appli1/protected' do
   if current_user1
       body "Welcome #{params[:user]}  <a href=\"/appli1/disconnect\">Disconnect</a> "
   else
       if params[:secret] = 1234
           session["utilisateur"] = user
           body "Welcome #{user}  <a href=\"/appli1/disconnect\">Disconnect</a>"
       else
           status 404
           body "Authentification failed <a href=\"http://localhost:4567/appli1/authenticate?backup_url=http://localhost:4568/appli1/protected\">Log in</a>"
       end
   end
end

get '/appli1/disconnect' do
    if current_user1
        disconnect1
        body "Good bye  <a href=\"http://localhost:4567/appli1/authenticate?backup_url=http://localhost:4568/appli1/protected\">Log in</a> "
    else
        status 404
        body "Nobody was connected"
    end
end
