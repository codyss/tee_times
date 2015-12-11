require 'rest_client'

COURSES = {
    'NY Country Club' => 'new-york-country-club-new-york',
    'Galloping Hills' => 'galloping-hill-golf-course-new-jersey',
    'Richter Park' => 'richter-park-golf-course-connecticut',
    'Sterling-Farms' => 'sterling-farms-golf-course-connecticut',
    'Hudson Hills' => 'hudson-hills-golf-course-new-york',
    'Middle Bay' => 'south-bay-country-club-new-york',
    'Tallgrass' => 'tallgrass-golf-club-new-york',
    'Patriot Hills' => 'patriot-hills-golf-club-new-york',
    'River Vale' => 'river-vale-country-club-new-jersey',
    'Lido' => 'lido-golf-club-new-york',
    'Berkshire Valley' => 'berkshire-valley-golf-course-new-jersey',
    'Wind Watch' => 'wind-watch-golf-course-new-york',
    'Stonebridge' => 'wind-watch-golf-course-new-york'
}

def kimono_search_full
    response_on_demand = RestClient.get "https://www.kimonolabs.com/api/4ujite74?apikey=REK0Ffj1XIg1BhGMU3wDHLBv9kQbB2ur"
    times = JSON.parse(response_on_demand)["results"]["collection1"]
end

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