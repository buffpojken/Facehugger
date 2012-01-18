require File.dirname(__FILE__)+'/ascii.rb'
def pretty(msg);puts("\n---\t\t\t%s\t\t\t---" % msg);end
def configatron(key, value);"configatron.#{key} = '#{value}'\n";end
  
# Print header, ascii art and first instructions
put_header

# Add custom gem-host
pretty("Setting up custom gem-host")
add_source "http://gems.qubator.com"

# Add custom gems to gemfile
pretty("Adding standard gems to Gemfile")
gem("mini_fb", "1.1.10", :git => "git://github.com/buffpojken/mini_fb.git")
gem("configatron", "2.8.3")
gem("sinatra", "1.3.1")

# Set up initializer for configatron
pretty("Setting up Facebook-integration")
append_file(File.join("config", "environments", "development.rb"), configatron('facebook.app_id', ask("Facebook App ID:")))
append_file(File.join("config", "environments", "development.rb"), configatron('facebook.app_secret', ask("Facebook App Secret:")))
append_file(File.join("config", "environments", "development.rb"), configatron('base_url', "REPLACE THIS"))
append_file(File.join("config", "environments", "production.rb"), configatron('facebook.app_id', 'REPLACE THIS'))
append_file(File.join("config", "environments", "production.rb"), configatron('facebook.app_secret', 'REPLACE THIS'))
append_file(File.join("config", "environments", "production.rb"), configatron('base_url', "REPLACE THIS"))

# Remove public index
pretty("Removing index.html")
remove_file("public/index.html")

# Run Bundle
pretty("Run 'bundle install'")
run("bundle install")

# Installing restful_authentication and changing auth for FB
pretty("Installing restful_authentication")
run("rails plugin install git://github.com/Satish/restful-authentication.git")

# Configuring restful_authentication
pretty("Replacing password-checker in restful_authentication")
password_method_regexp = /[\s\t]*def\spassword_required\?[\n\s\t\r]*crypted_password\.blank\?\s\|\|\s!password.blank\?[\n\s\t\r]*end/
gsub_file(File.join("vendor", "plugins", "restful-authentication", "lib", "authentication", "by_password.rb"),password_method_regexp,%{
    def password_required?  
      if skip_password?
				false
			else
       (crypted_password.blank? || !password.blank?)                    
			end
    end
  })
pretty("Injecting password_check methods into User-generator")
inject_into_file(File.join("vendor", "plugins", "restful-authentication", "lib", "generators", "authenticated", "templates", "model.rb"), %{
	def skip_password?
		return !facebook_user_id.nil?
	end
}, {:after => "attr_accessible :login, :email, :name, :password, :password_confirmation"})
pretty("Injecting Facebook-attributes in user-migrations")
inject_into_file(File.join("vendor", "plugins", "restful-authentication", "lib", "generators", "authenticated", "templates", "migration.rb"), %{
  t.string  :facebook_user_id
  t.string  :facebook_access_token
}, {:after => "t.column :remember_token_expires_at, :datetime"})

# Inject Sinatra-based authentication metal
pretty("Create metal-folder for Facebook-authentication")
empty_directory(File.join("lib", "metal"))

pretty("Inject metal-files")
copy_file(File.join(File.dirname(__FILE__), "files", "facebook_authentication.rb"), File.join("lib", "metal", "facebook_authentication.rb"))

pretty("Setup metal-routes")
route("match '/auth/facebook(/:action(/:id(.:format)))',    :to => FacebookAuthentication")

# Add lib-autoloading
pretty("Adding lib to autoload-path")
inject_into_file(File.join("config", "application.rb"), 'config.autoload_paths += %W(#{File.join(Rails.root, "lib")})', {:after => "# Custom directories with classes and modules you want to be autoloadable."})
inject_into_file(File.join("config", "application.rb"), 'config.autoload_paths += %W(#{File.join(Rails.root, "lib", "metal")})', {:after => "# Custom directories with classes and modules you want to be autoloadable."})

# Integrate FBootstrap into application
pretty("Setting up GUI-framework")
is_tab = ask("Is this application a Facebook Page Tab? [y/n]")
copy_file(File.join(File.dirname(__FILE__), "files", "fbootstrap", "bootstrap.min.css"), File.join("app", "assets", "stylesheets", "bootstrap.css"))
directory(File.join(File.dirname(__FILE__), "files", "fbootstrap", "js"), File.join("app", "assets", "javascripts", "bootstrap"))

# Replace application.html.erb
pretty("Replacing HTML-layout")
remove_file(File.join("app", "views", "layouts", "application.html.erb"))
copy_file(File.join(File.dirname(__FILE__), "files", "application.html.erb"), File.join("app", "views", "layouts", "application.html.erb"))