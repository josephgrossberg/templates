Templates
===========================

I'm using this repository to store my Rails 2.3+ templates. 

Base
--------
To use: `rails -m /path/to/intridea_base.rb new_project_name`

The intridea_base.rb template installs Authlogic, RSpec and JQuery (and removes Prototype), in addition to a few other essentials. 

*Plugins:*

* asset_packager
* browserized_styles
* hoptoad_notifier

*Gems:*

* authlogic
* carlosbrando-remarkable
* cucumber
* mislav-will_paginate
* rspec
* rspec-rails
* thoughtbot-factory_girl
* webrat

*JavaScript:*

* jquery
* jquery.form

*CSS:*

* Yahoo's reset-fonts-grids.css

It does not include the password reset for Authlogic, so you'll need to add this. The Hoptoad Notifier plugin is installed and you will need your Hoptoad API key handy.
