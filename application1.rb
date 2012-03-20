$:.unshift File.dirname(__FILE__)
require 'sinatra'

set :port, 4568

use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 259000,
                           :secret => 'appli1'

helpers do

def current_user
   session["utilisateur"]
end

def user
   params[:user]
end

def disconnect
   session["utilisateur"] = nil
end

end

get '/welcome' do
   if current_user
       redirect '/appli1/protected'
   else
       body "Bienvenue sur L'application Number 1 <a href=\"http://localhost:4567/s_auth/application/authenticate?application=Baby&&backup_url=http://localhost:4568/Baby/protected\">Log in</a>"
   end
end

get '/Baby/protected' do
   if current_user
       body "Welcome #{params[:user]}"
   else
       if params[:secret] = "1869323054"
           session["utilisateur"] = user
           body "Welcome #{user} <a href=\"/Baby/disconnect\">Disconnect</a>"
       else
           status 404
           body "Authentification failed <a href=\"http://localhost:4567/s_auth/application/authenticate?application=Baby1&&backup_url=http://localhost:4568//Baby/protected\">Log in</a>"
       end
   end
end

get '/Baby/disconnect' do
    if current_user
        disconnect
        body "Good bye"
    else
        status 404
        body "Nobody was connected"
    end
end
