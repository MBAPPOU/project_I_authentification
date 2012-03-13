class RackSession
  attr_reader :pool

  def initialize(app)
    @app = app
    @pool = Hash.new
  end

  def call(env)
    load_session(env)
    status, headers, body = @app.call(env)
    commit_session(env)
    [status, headers, body]
  end

  def load_session(env)
    sid = env["rack.session.id"]
    env["rack.session"] = @pool[sid] || @pool[sid] = {}
  end

  def commit_session(env)
    sid = env["rack.session.id"]
    @pool[sid] = env["rack.session"]
  end
end
