# Rack chargé d'authentifier un utilisateur
$:.unshift File.dirname(__FILE__)
require_relative '../user'
require_relative '../database'

class AuthApi

  def initialize(app)
    @app = app
    @sessions = {}
    @indice = 0
  end

  def self.add(word)
      @sessions[@indice]=word
  end

  def call(env)
    request = Rack::Request.new(env)
    status, headers, body = @app.call(env)
    #puts "-------------------"
    #puts request.form_data?()
    #puts "-------------------"
    #puts request.POST()
    #puts "-------------------"
    # On recupère les paramètres du formulaire
    if ( request.form_data?() )
       @login = request.POST()["login"] 
       @password = request.POST()["password"]
       headers["logpass"] = [ @login , @password ].join(':')
    else
       @login = nil
       @password = nil
    end
    #--------------------------------------------------------------------------------------------------------------------------
    # On verifie si l'environnement de la requête a un cookie
    #--------------------------------------------------------------------------------------------------------------------------
    cookieset = request.cookies() # On recupère un tableau de cookies s'il en existe ou pas
    headers["authentification"] = "unknow" # Par défaut aucune session en cours
    if ( cookieset || (@login && @password) )# Si 'env' a un ou des cookies, on les compare au tableau de sessions initialisées
          if ( cookieset )
              cookieset.each { |n,m|
                 @sessions.each { |k, v|
                     if ( m = v ) # Si la correspondance est faite, alors l'utilisateur a une session en cours
                         headers["authentification"] = "true"
                     break
                     end 
                 }
                 break if ( headers["authentification"] == "true" )
              }
          end
          if ( @login && @password )
              # On crée un modèle d'utiisateur doté des paramètres récupérés
              p = User.new
              if p 
              p.login = @login
              p.password = @password if p
              # On vérifie si l'utilisateur existe bien dans la base de donnée
              q = find(p.login)
              if ( q ) # Si l'utilisateur existe
                   if ( p.login == q.login  && p.password == q.password ) # si l'authentification est correcte, on valide
                       @indice += 1
                       val = "name=generate_session_id"
                       headers["Set-Cookie"] = [ env["Set-Cookie"], "#{val}" ].join(';') 
                       @sessions[@indice] = "#{val}" # On enregistre le cookie dans sessions
                       headers["authentification"] = "true"
                   else  # sinon on invalide car l'authentification s'est mal déroulée
                       headers["authentification"] = "false"
                   end
              else # l'utilisateur est inconnu ou il s'agit d'une demande de création de compte
                   if ( headers["authentification"] == "unknow" && request.POST()["message"] == "createaccount" )
                       p.save
                       headers["authentification"] = "true"
                   else
                       headers["authentification"] = "false"
                   end
              end
              end
          end
    else
    #--------------------------------------------------------------------------------------------------------------------------
    # L'environnement ici n'a pas de cookie et aucun paramètres login et mdp
    #--------------------------------------------------------------------------------------------------------------------------
    end
     [status, headers, body]
  end
  
  def generate_session_id(bit_size=32)
    rand(2**bit_size - 1)
  end
  
  def find(word)
     User.find_by_name( word.to_s() )
  end
  
end
