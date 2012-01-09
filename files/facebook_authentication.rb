require 'cgi'
# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

class FacebookAuthentication < Sinatra::Base

	get '/auth/facebook/authorize' do
    "You must replace this with proper business logic."
	end

end

