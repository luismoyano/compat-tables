gem uninstall shiny_json_logic json_logic_ruby json-logic-rb json_logic
gem install shiny_json_logic
export LIBRARY="shiny_json_logic"
ruby main.rb

gem uninstall shiny_json_logic json_logic_ruby json-logic-rb json_logic
gem install json_logic_ruby
export LIBRARY="json_logic_ruby"
ruby main.rb

gem uninstall shiny_json_logic_ruby json_logic_ruby json-logic-rb json_logic
gem install json-logic-rb
export LIBRARY="json-logic-rb"
ruby main.rb

gem uninstall shiny_json_logic_ruby json_logic_ruby json-logic-rb json_logic
gem install json_logic
export LIBRARY="json_logic"
ruby main.rb
