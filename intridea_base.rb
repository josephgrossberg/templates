#################################
# INITIAL QUESTIONS
#################################
site_title = ask("What is the title of your website?")
site_url = ask("What is the URL of your website? (e.g. www.example.com)")

#################################
# CLEANING UP FILES
#################################
run "rm public/index.html"
run "rm public/images/rails.png"
run "rm README"
run "cp config/database.yml config/database.yml.example"
run "rm public/robots.txt"

#################################
# GIT SETUP
#################################
file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END
 
git :init
git :add => "."
git :commit => '-m "Initial commit."'

#################################
# PLUGINS AND GEMS
#################################
plugin 'asset_packager', :git => 'script/plugin install git://github.com/sbecker/asset_packager.git'
plugin 'hoptoad_notifier', :git => 'git://github.com/thoughtbot/hoptoad_notifier.git'
plugin 'browserized_styles', :git => 'git://github.com/mbleigh/browserized-styles.git'

hoptoad_key = ask("What is your Hoptoad API key?")

file 'config/initializers/hoptoad.rb', <<-CODE
HoptoadNotifier.configure do |config|
  config.api_key = "#{hoptoad_key}"
end
CODE

gem 'authlogic'
gem 'cucumber'
gem 'rspec', :lib => false
gem 'rspec-rails', :lib => false
gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
gem 'carlosbrando-remarkable', :lib => 'remarkable', :source => 'http://gems.github.com'
gem 'relevance-rcov', :lib => 'rcov', :source => 'http://gems.github.com'
gem 'webrat'
gem 'mislav-will_paginate', :version => '~> 2.2.3',
  :lib => 'will_paginate', :source => 'http://gems.github.com'

if yes?("Run rake gems:install? (yes/no)")
  rake("gems:install", :sudo => true)
end

if yes?("Unpack gems? (yes/no)")
  rake("gems:unpack")
end

if yes?("Freeze Rails? (yes/no)")
  freeze!
end

#################################
# JS AND CSS
#################################
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"
file 'public/javascripts/application.js', <<-CODE
    jQuery.ajaxSetup({ 
        'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
    });
CODE

run "curl -L http://yui.yahooapis.com/2.7.0/build/reset/reset-min.css > public/stylesheets/reset-min.css"
run "curl -L http://yui.yahooapis.com/2.7.0/build/fonts/fonts-min.css > public/stylesheets/fonts-min.css"
run "touch public/stylesheets/application.css"


#################################
# RSPEC AND CUCUMBER
#################################
generate('rspec')
generate('cucumber')

#################################
# AUTHLOGIC
#################################
generate('session', 'user_session')
generate('rspec_scaffold', 'user login:string crypted_password:string password_salt:string persistence_token:string single_access_token:string perishable_token:string login_count:integer last_request_at:datetime last_login_at:datetime current_login_at:datetime last_login_ip:string current_login_ip:string')

file 'app/models/user.rb', <<-CODE
class User < ActiveRecord::Base
  acts_as_authentic

  def deliver_password_reset_instructions!(url)
    Notifier.deliver_password_reset_instructions(self, url)
  end
end
CODE

file 'app/models/notifier.rb', <<-CODE
class Notifier < ActionMailer::Base
  default_url_options[:host] = "#{site_url}"

  def password_reset_instructions(user, url)
    subject       "Password Reset Instructions for #{site_title}"
    recipients    user.login
    sent_on       Time.now                     
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token) 
  end         
end
CODE

file 'app/views/notifier/password_reset_instructions.html.erb', <<-CODE
A request to reset your password has been made. If you did not make this request, simply ignore this email. If you did make this request just click the link below:
 
<%= @edit_password_reset_url %>
 
If the above URL does not work try copying and pasting it into your browser. If you continue to have problem please feel free to contact us.
CODE

file 'app/controllers/user_sessions_controller.rb', <<-CODE
class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
CODE

file 'app/controllers/users_controller.rb', <<-CODE
class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
CODE

file 'app/controllers/application_controller.rb', <<-CODE
class ApplicationController < ActionController::Base
  filter_parameter_logging :password, :password_confirmation
  helper_method :current_user_session, :current_user

  private
   
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
  
end
CODE

file 'app/helpers/application_helper.rb', <<-CODE
# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def clearfix
    "<div class='clearfix'></div>"
  end
end
CODE

body_tag = '<body class="<%=h "#{params[:controller]} #{params[:action]} #{params[:controller]}_#{params[:action]}" %>">'

file 'app/views/layouts/application.html.erb', <<-CODE
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
    "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>#{site_title}</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8" />
    <link rel="shortcut icon" href="/favicon.ico" />
    <%= stylesheet_link_tag "reset-min", "fonts-min", "application" %>
    <%= javascript_include_tag "prototype", "jquery" %>
    <script type="text/javascript">jQuery.noConflict();</script>
    <%= javascript_include_tag "jquery-form", "application" %>
  </head>
  #{body_tag}
    <div id="container">
      <%= render :partial => "layouts/header" %>
      <div id="content">
        <% unless flash[:notice].blank? %>
          <p class="flash_notice"><%= flash[:notice] %></p>
        <% end %>
        <% unless params[:message_string].blank? %>
          <p class="flash_notice"><%= params[:message_string] %></p>
        <% end %>
        <%= yield %>
      </div> <!-- end: #content -->
      <%= clearfix %>
      <%= render :partial => "layouts/footer" %>
    </div> <!-- end: #container -->
  </body>
</html>
CODE

file 'app/views/layouts/_header.html.erb', <<-CODE
<% if !current_user %>
  <%= link_to "Register", new_account_path %> |
  <%= link_to "Log In", new_user_session_path %>
<% else %>
  <%= link_to "My Account", account_path %> |
  <%= link_to "Log Out", user_session_path, :method => :delete, :confirm => "Are you sure you want to logout?" %>
<% end %>
CODE

run 'touch app/views/layouts/_footer.html.erb'
run 'rm app/views/layouts/users.html.erb'

file 'app/controllers/password_resets_controller.rb', <<-CODE
class PasswordResetsController < ApplicationController
  before_filter :load_user_using_perishable_token, :only => [:edit, :update]
  before_filter :require_no_user
  
  def new
    render
  end

  def create
    @user = User.find_by_login(params[:email])
    if @user
      @user.deliver_password_reset_instructions! request.env['HTTP_HOST']
      flash[:notice] = "Instructions to reset your password have been emailed to you. " +
        "Please check your email."
      redirect_to home_url
    else
      flash[:notice] = "No user was found with that email address"
      render :action => :new
    end
  end

  def edit
    render
  end
  
  def update
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]
    if @user.save
      flash[:notice] = "Password successfully updated"
      redirect_to home_url
    else
      render :action => :edit
    end
  end
  
  private
  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:id])
    unless @user
      flash[:notice] = "We're sorry, but we could not locate your account. " +
                       "If you are having issues, try copying and pasting " +
                       "the URL from your email into your browser or " +
                       "starting the <a href=\"" + new_password_reset_path + 
                       "\">reset password</a> process again."
      redirect_to home_url
    end
  end

end
CODE

file 'app/views/password_resets/new.html.erb', <<-CODE
<h1>Forgot Password</h1>
 
Fill out the form below and instructions to reset your password will be emailed to you:<br />
<br />
 
<% form_tag password_resets_path do %>
  <label>Email:</label><br />
  <%= text_field_tag "email" %><br />
  <br />
  <%= submit_tag "Reset my password" %>
<% end %>
CODE

file 'app/views/password_resets/edit.html.erb', <<-CODE
<h1>Change My Password</h1>
 
<% form_for @user, :url => password_reset_path, :method => :put do |f| %>
  <%= f.error_messages %>
  <%= f.label :password %><br />
  <%= f.password_field :password %><br />
  <br />
  <%= f.label :password_confirmation %><br />
  <%= f.password_field :password_confirmation %><br />
  <br />
  <%= f.submit "Update my password and log me in" %>
<% end %>
CODE

file 'app/views/user_sessions/new.html.erb', <<-CODE
<h1>Login</h1>
 
<% form_for @user_session, :url => user_session_path do |f| %>
  <%= f.error_messages %>
  <%= f.label :login %><br />
  <%= f.text_field :login %><br />
  <br />
  <%= f.label :password %><br />
  <%= f.password_field :password %><br />
  <br />
  <%= f.check_box :remember_me %><%= f.label :remember_me %><br />
  <br />
  <%= f.submit "Login" %>
<% end %>

<p><%= link_to "Forgot password?", new_password_reset_path %></p>
CODE

file 'app/views/users/_form.html.erb', <<-CODE
<%= form.label :login %><br />
<%= form.text_field :login %><br />
<br />
<%= form.label :password, form.object.new_record? ? nil : "Change password" %><br />
<%= form.password_field :password %><br />
<br />
<%= form.label :password_confirmation %><br />
<%= form.password_field :password_confirmation %><br />
CODE

file 'app/views/users/edit.html.erb', <<-CODE
<h1>Edit My Account</h1>
 
<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Update" %>
<% end %>
 
<br /><%= link_to "My Profile", account_path %>
CODE

file 'app/views/users/new.html.erb', <<-CODE
<h1>Register</h1>
 
<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Register" %>
<% end %>
CODE

file 'app/views/users/show.html.erb', <<-CODE
<p>
  <b>Login:</b>
  <%=h @user.login %>
</p>
 
<p>
  <b>Login count:</b>
  <%=h @user.login_count %>
</p>
 
<p>
  <b>Last request at:</b>
  <%=h @user.last_request_at %>
</p>
 
<p>
  <b>Last login at:</b>
  <%=h @user.last_login_at %>
</p>
 
<p>
  <b>Current login at:</b>
  <%=h @user.current_login_at %>
</p>
 
<p>
  <b>Last login ip:</b>
  <%=h @user.last_login_ip %>
</p>
 
<p>
  <b>Current login ip:</b>
  <%=h @user.current_login_ip %>
</p>
 
<%= link_to 'Edit', edit_account_path %>
CODE

#################################
# ROUTES
#################################
route 'map.resource :user_session'
route 'map.resource :account, :controller => "users"'
route 'map.resources :users'
route 'map.resources :password_resets'
route 'map.home \'/\', :controller => "user_sessions", :action => "new"'
route 'map.root :controller => "user_sessions", :action => "new"'

#################################
# GIT CHECK-IN
#################################
git :add => "."
git :commit => '-m "Adding templates, plugins and gems"'

#################################
# DATABASE
#################################
if yes?("Create and migrate databases now? (yes/no)")
  rake("db:create:all")
  rake("db:migrate")
  git :add => "."
  git :commit => '-m "First migration adding users"'
end

#################################
# TO-DO
#################################
puts "TO-DO checklist:"
puts "* Test your Hoptoad installation with: rake hoptoad:test"
puts "* Generate your asset_packager config with: rake asset:packager:create_yml"
puts "* import this repo into github or Unfuddle"
