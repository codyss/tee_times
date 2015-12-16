require_relative 'kimono_ruby_oo'
require 'rest_client'

prompt = "Tee time search running 1) Look for some times, 2) Update db, 3) Quit"

puts prompt
choice = gets.strip

while choice.to_i != 3 
    if choice.to_i == 1
        puts "Let's find you a tee time"
        search
    else
        puts "Going to update the local db"
        update_db
    end
    puts prompt
    choice = gets.strip
end

