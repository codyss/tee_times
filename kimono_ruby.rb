require 'rest_client'

COURSES = {
    'NY Country Club' => 'new-york-country-club-new-york',
    'Galloping Hills' => 'galloping-hill-golf-course-new-jersey'
    'Richter Park' => 'richter-park-golf-course-connecticut'
    'Sterling-Farms' => 'sterling-farms-golf-course-connecticut'
}

#richter-park-golf-course-connecticut,sterling-farms-golf-course-connecticut,hudson-hills-golf-course-new-york,south-bay-country-club-new-york,tallgrass-golf-club-new-york,new-york-country-club-new-york,patriot-hills-golf-club-new-york,river-vale-country-club-new-jersey,lido-golf-club-new-york,berkshire-valley-golf-course-new-jersey,galloping-hill-golf-course-new-jersey,wind-watch-golf-course-new-york,stonebridge-golf-links-country-club-new-york

def kimono_search(course, date)
    response_on_demand = RestClient.get "https://www.kimonolabs.com/api/ondemand/7m3qocvk?apikey=REK0Ffj1XIg1BhGMU3wDHLBv9kQbB2ur&kimpath5=#{date}&kimpath3=#{course}"
    times = JSON.parse(response_on_demand)["results"]["collection1"]
end


#search could save times to database and then only 
#search for additional times if time is over e.g. 30 min

def remove_duplicates(times_list, clean_times=[])
    #removes the duplicates, keeping the more expensive times for times_list returning clean_times
    for i in times_list do
        if clean_times.length == 0
            clean_times << i
        elsif clean_times[-1]['time'] != i['time']
            clean_times << i
        elsif clean_times[-1]['time'] == i['time']
            if clean_times[-1]['rate'] >= i['rate']
            elsif clean_times[-1]['rate'] < i['rate']
                clean_times[-1] = i
            end         
        end
    end
    clean_times
end


def num_players(times)
    #takes list of times and cleans data to show number of players
    for i in times
        i['players'].each_with_index do |item, index|
            if item['class'].include?('blue')
                i['num_players'] = index + 1
            end
        end
    end
    times
end

def find_time
    #prompts the user for a time they would like to play and returns their request time
    puts "What time do you want to play? HH:MM military format e.g. 14:30"
    gets.strip
end

def search_for_time(times, r)
    times.detect do |x| 
        tee_time_f = x['time'][0,x['time'].index(':')+1].to_i + x['time'][-2,2].to_f / 100
        request_time_f = r[0,r.index(':')+1].to_i + r[-2,2].to_f / 100
        tee_time_f >= request_time_f
    end
        #{|x| x['time'] >= request.}
# convert hour to number, minutes to decimal
end

def time_to_military(times)
    for i in times
        if i['time'][-2,2] == 'PM'
            if i['time'][0,2] == '12'
                i['time'] = i['time'][0,i['time'].length-3]
            else
                i['time'] = i['time'][0,i['time'].length-3]
                i['time'][0,2] = (i['time'][0,1].to_i + 12).to_s
            end
        else
            i['time'] = i['time'][0,i['time'].length-3]
        end
    end
    times
end


def pretty_print(time)
    #prints out the number of players at the time
    players = time['num_players']
    tee_time = time['time']
    puts "Nearest time available is a tee time for #{players} player#{'s' if players.to_i > 1} at #{tee_time}"
end    

def date_request
    puts "What date would you like to play? (mmm-DD) e.g. dec-11 "
    choice = gets.strip
end

def course_search_to_long_name
    course_list
    puts "which course would you like to play? Enter the name "
    choice_simple = gets.strip
    COURSES[choice_simple]
end

def course_list
    puts "Courses available:"
    for i,j in COURSES
        puts i
    end
end

def run_search
    course = course_search_to_long_name
    date = date_request
    puts "Hold while we search for times..."
    raw_times = kimono_search(course, date)
    puts "Tee times available"
    times = time_to_military(num_players(remove_duplicates(raw_times)))
    pretty_print(search_for_time(times, find_time))
end

