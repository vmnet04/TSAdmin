# Define a subclass of Ramaze::Controller holding your defaults for all controllers. Note
# that these changes can be overwritten in sub controllers by simply calling the method
# but with a different value.

class Controller < Ramaze::Controller
  layout :default
  helper :auth
  helper :xhtml
  helper :link
  helper :flash
  engine :etanni

  def login
    if logged_in?
      call(r('/'))
    else
      super
    end
  end

  private

  def auth_template
    <<-TEMPLATE.strip!
      <div class="grid_12 content login"><header><h2>Login</h2></header><div class="list-form">#{super}</div></div>
    TEMPLATE
  end

  def auth_login(username, password)
    return unless username and password
    return if username.empty? or password.empty?

    authenticated = false
    auth = APP_CONFIG['auth'].is_a?(Array) ? APP_CONFIG['auth'] : [APP_CONFIG['auth']]
    auth.each do |a|
      next unless a['username'].downcase == username.downcase
      next unless a['password'] == Digest::SHA1.hexdigest(password)
      authenticated = true
    end

    return unless authenticated

    session[:logged_in] = true
    session[:username] = username.downcase
  end

  def login_required
    super
    @username = session[:username]
  end

  def traffic_server
    @_traffic_server ||= ::TSAdmin::TrafficServer.new(APP_CONFIG['traffic_server'])
  end

  def restart_traffic_server
    @@restart_scheduled = true
    @@restart_thread = Thread.new do
      while @@restart_scheduled
        @@restart_scheduled = false
        traffic_server.restart
      end
      @@restart_thread = nil
    end if !defined?(@@restart_thread) || @@restart_thread.nil?
  end

end

# Here you can require all your other controllers. Note that if you have multiple
# controllers you might want to do something like the following:
Dir.glob("#{__DIR__}/*.rb").each do |controller|
  require(controller)
end
