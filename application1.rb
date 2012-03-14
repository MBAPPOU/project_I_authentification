$:.unshift File.dirname(__FILE__)
require 'sinatra'

set :port, 4568

use Rack::Session::Cookie, :key => 'rack.session',
                           :expire_after => 259000,
                           :secret => 'appli1'

helpers do

def current_user
   session["current_user"]
end

def user
   params[:user]
end

def disconnect
   session["current_user"] = nil
end

end

get '/welcome' do
   if current_user
       redirect '/appli1/protected'
   else
       body "Bienvenue sur L'application Number 1 <a href=\"http://localhost:4567/s_auth/application/authenticate?application=APPLI1;backup_url=http://localhost:4568//appli1/protected\">Log in</a>"
   end
end

get '/appli1/protected' do
   if current_user
       body "Welcome #{params[:user]}"
   else
       if params[:secret] = "1234"
           session[current_user] = user
           body "Welcome #{user}"
       else
           status 404
           body "Authentification failed <a href=\"http://localhost:4567/s_auth/application/authenticate?application=APPLI1;backup_url=http://localhost:4568//appli1/protected\">Log in</a>"
       end
   end
end

get 'appli1/disconnect' do
    if current_user
        disconnect
        body "Good bye"
    else
        status 404
        body "Nobody was connected"
    end
end
