class RackCookieSession

  def initialize(app,env_session_id_key="rack.session.id",cookie_name="session_id")
    @app = app
    @env_session_id_key = env_session_id_key
    @cookie_name = cookie_name
  end

  def call(env)
    new_session = false
    unless session_id = extract_session_id(env)
      session_id = generate_session_id
      new_session = true
    end
    env[@env_session_id_key] = session_id
    
    
    env["request"] = Rack::Request.new(env).params()
    
    
    status, headers, body = @app.call(env)
    headers["Set-Cookie"] = "#{@cookie_name}=#{session_id}" if new_session
    [status, headers, body]
  end

  def extract_session_id(env)
    req = Rack::Request.new(env)
    req.cookies[@cookie_name]
  end

  def generate_session_id(bit_size=32)
    rand(2**bit_size - 1)
  end

end
    

