require_relative 'kimono_ruby_oo'
require 'rest_client'



puts "Looking for some 1) times or a 2) db update"
choice = gets.strip

if choice.to_i == 1
    puts "Let's find you a tee time"
    search
else
    puts "Going to update the local db"
    update_db
end

