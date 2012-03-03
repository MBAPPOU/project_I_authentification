# Rack chargé d'authentifier un utilisateur
$:.unshift File.dirname(__FILE__)
require '../user' 

class AuthApi
include User

  def initialize(app)
    @app = app
    @sessions = {}
    @indice = 0
  end

  def call(env)
    request = Rack::Request.new(env)
    #--------------------------------------------------------------------------------------------------------------------------
    # On verifie si l'environnement de la requête a un cookie
    #--------------------------------------------------------------------------------------------------------------------------
    cookieset = request.cookies() # On recupère un tableau de cookies s'il en existe ou pas
    status, headers, body = @app.call(env)
    headers["authentification"] = "unknow" # Par défaut aucune session en cours
    if cookieset # Si 'env' a un ou des cookies, on les compare au tableau de sessions initialisées
    cookieset.each { |n|
       @sessions.each { |k, v|
          if ( cookieset[n] = v ) # Si la correspondance est faite, alors l'utilisateur a une session en cours
             headers["authentification"] = "true"
             break
          end 
       }
       break if ( headers["authentification"] == "true" )
    }
    else
    #--------------------------------------------------------------------------------------------------------------------------
    # L'environnement ici n'a pas de cookie,donc on traite soit une demande de connexion,soit une demande de création de compte
    #--------------------------------------------------------------------------------------------------------------------------
        # On recupère les paramètres de l'environnement
        parametres = request.params[]
        @login = parametres[login]
        @password = parametres[password]
    
        # On crée un modèle d'utiisateur doté des paramètres récupérés
        p = User.new
        p.login = @login
        p.password = @password
    
        # On vérifie si l'utilisateur existe bien dans la base de donnée
        q = find(p.login)
    
        if q # Si l'utilisateur existe
            if ( p.login == q.login  && p.password == q.password ) # si l'authentification est correcte, on valide
               headers["authentification"] = "true"
               @index += 1
               val = generate_session_id 
               headers["Set-Cookie"] = "name=#{val}" # On initialise un cookie de session
               @sessions[@index] = "name=#{val}" # On enregistre le cookie
            else  # sinon on invalide car l'authentification s'est mal déroulée
               headers["authentification"] = "false"
            end
        else # l'utilisateur est inconnu ou il s'agit d'une demande de création de compte
           if ( headers["authentification"] == "unknow" && parametres[message] == "createaccount" )
              p.save
              headers.delete["authentification"]
           end
        end
    end
     [status, headers, body]
  end
  
  def generate_session_id(bit_size=32)
    rand(2**bit_size - 1)
  end
  
  def find(word)
     User.find_by_name(word.to_s())
  end
  
end
