class AuthApi
  def self.decode_http_authorize(base64hash)
    base64hash.unpack('m')[0].split(':')
  end

  def user_model
    @user_model
  end
  
  def initialize(app, options = {})
    @app = app
    @user_model = options[:user_model]
    @find_method = options[:find_method]
  end

  def call(env)
    b64 = env.delete('HTTP_AUTHORIZATION')
    if b64 
      b64.gsub!(/Basic /,"") 
      login, key = AuthApi.decode_http_authorize(b64)
      user = @user_model.send(@find_method, key)
      env['rack.auth.api'] = user
    end
    status, headers, body = @app.call(env)
  end
end
