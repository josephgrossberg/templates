Templates
===========================

I'm using this repository to store my Rails 2.3+ templates. 

Base
--------
To use: `rails -m /path/to/base.rb new_project_name`

The base.rb template installs Authlogic, RSpec and JQuery (and removes Prototype), in addition to a few other essentials. It does not include the views for the Authlogic controllers, so you'll need to add those (or get a missing template error). The Hoptoad Notifier plugin is installed and you will need your Hoptoad API key handy.