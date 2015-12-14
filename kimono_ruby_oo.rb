require 'rest_client'
require 'mongo'
require 'pry'

COURSES = {
    'NY Country Club' => 'new-york-country-club-new-york',
    'Galloping Hill' => 'galloping-hill-golf-course-new-jersey',
    'Richter Park' => 'richter-park-golf-course-connecticut',
    'Sterling Farms' => 'sterling-farms-golf-course-connecticut',
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

class TeeTimeSearch
    def initilize
        @times_list = []
        @times_update = []
    end

    def on_demand_course=(course)
        @course = course
    end

    def course
        @course
    end

    def on_demand_date=(date)
        @date = date
    end

    def date
        @date
    end

    def view_times
        @times_list
    end

    def times_update
        @times_update
    end

    def view_clean_times
        @clean_times
    end

    def on_demand
        response_on_demand = RestClient.get "https://www.kimonolabs.com/api/ondemand/4ujite74?apikey=REK0Ffj1XIg1BhGMU3wDHLBv9kQbB2ur&kimpath5=#{@date}&kimpath3=#{@course}"
        @times_update = JSON.parse(response_on_demand)["results"]["collection1"]
    end

    def full_search
        response = RestClient.get "https://www.kimonolabs.com/api/4ujite74?apikey=REK0Ffj1XIg1BhGMU3wDHLBv9kQbB2ur"
        @times_list = JSON.parse(response)["results"]["collection1"]
    end

    def start_update_pull
        #do a kimomo on demand pull for the user request to confirm that the requests match, and can update the full data set
        #going to set course and date in User Search class, then just run a on-demand pull with the course and date        
    end

    def remove_duplicates
       #removes the duplicates, keeping the more expensive times for times_list returning clean_times
        @clean_times = []
        for i in @times_list do
            if @clean_times.length == 0
                @clean_times << i
            elsif @clean_times[-1]['time'] != i['time']
                @clean_times << i
            elsif @clean_times[-1]['time'] == i['time']
                if @clean_times[-1]['rate'] >= i['rate']
                elsif @clean_times[-1]['rate'] < i['rate']
                    @clean_times[-1] = i
                end         
            end
        end
        @clean_times
    end

    def num_players
        #takes list of times and cleans data to show number of players
        for i in @clean_times
            i['players'].each_with_index do |item, index|
                if item['class'].include?('blue')
                    i['num_players'] = index + 1
                end
            end
        end
        @clean_times
    end


    def time_to_military
        for i in @clean_times
            if i['time'][-2,2] == 'PM'
                if i['time'][0,2] == '12'
                    i['time'] = i['time'][0,i['time'].length-3]
                else
                    i['time'] = i['time'][0,i['time'].length-3]
                    i['time'][0,2] = (i['time'][0,1].to_i + 12).to_s
                end
            elsif i['time'][0,2] == '12'
                i['time'] = i['time'][0,i['time'].length-3]
                i['time'][0,2] = (i['time'][0,1].to_i - 12).to_s
            else
                i['time'] = i['time'][0,i['time'].length-3]
            end
        end
        @clean_times
    end

    def pull_out_course_date
        #function should pull out the course and the date for easy searching
        #function works on the full pull
        for i in @clean_times
            i['course'] = i['url'][i['url'].index('/at/')+4..i['url'].index('/on/')-1]
            i['date'] = i['url'][i['url'].index('/on/')+4..i['url'].length]
        end
        @clean_times
    end

    def label_course_date(course, date)
        for i in @times_update
            i['course'] = course
            i['date'] = date
        end
        times_update
    end

    def cleaning
        remove_duplicates
        num_players
        time_to_military
        pull_out_course_date
    end

    def on_demand_cleaning
        remove_duplicates
        num_players
        time_to_military
        label_course_date
    end

end


class UserSearch
    def initialize(times)
        @times = times
        @times_course_date = []
        @times_on_demand = []
    end

    def view
        @times
    end

    def course
        @course
    end

    def date
        @date
    end

    def times_on_demand=(times_on_demand)
        @times_on_demand = times_on_demand
    end

    def find_time
        #prompts the user for a time they would like to play and returns their request time
        puts ""
        puts "What time do you want to play? HH:MM military format e.g. 14:30"
        @time_request = gets.strip
        puts "How many players in your group?"
        @players = gets.strip
    end

    def no_times
        #need a function that identifies when there are no times at course that day
        if @times_course_date == []
            true
        else
            false
        end
    end


    def filter_course_date
        #after pull out course date function, this will search the times fed to it based on the course, date provided by user
        if @times == {}
        else
            @times.each do |x| 
                if x['course'] == @course && x['date'] == @date  && x['num_players'].to_i >= @players.to_i
                    @times_course_date << x
                end
            end
        end
        @times_course_date
    end


    def search_for_time
        if @times_course_date.length < 1
            @time = {'num_players'=> '0', 'time'=> 'None'}
        else
            @time = @times_course_date.detect do |x| 
                tee_time_i = x['time'].to_i
                request_time_i = @time_request[0,@time_request.index(':')+1].to_i + @time_request[-2,2].to_i
                tee_time_i >= request_time_i
            end
        end
    end

    def course_list
        puts "Courses available:"
        for i,j in COURSES
            puts i
        end
        #COULD print out the number of tee times at each course
    end

    def course_search_to_long_name
        course_list
        puts ""
        puts "Which course would you like to play? Enter the name "
        choice_simple = gets.strip
        while COURSES[choice_simple] == nil
            puts "please write the course name exactly like above"
            choice_simple = gets.strip
        end
        @course = COURSES[choice_simple]
    end

    def pretty_print
        #prints out the number of players at the time
        if @time['num_players'] == '0'
            puts "No times available that meet your request"
        else
            players = @time['num_players']
            tee_time = @time['time']
            puts "Nearest time available is a tee time for #{players} player#{'s' if players.to_i > 1} at #{tee_time}"
        end
    end    

    def date_request
        puts "What date would you like to play? (mmm-DD) e.g. dec-11 "
        @date = gets.strip
        #@times.on_demand_date=(@date)
        #@times.on_demand_course=(@course)
    end
end


class LocalTimesDB
    def initialize
        @client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'tee_times')
    end

    def times_to_save=(times_to_save)
        @times_to_save = times_to_save.view_clean_times
    end

    def save_times
        result = @client[:tee_times].insert_many(@times_to_save)
    end

    def course=(course)
        @course = course
    end

    def date=(date)
        @date = date
    end

    def find_times
        @times = @client[:tee_times].find()
    end

end




def search

    #get the latest times - changed to pull from database
    #times = TeeTimeSearch.new
    #times.full_search
    #times.cleaning

    times = LocalTimesDB.new
    tee_times = times.find_times

    #search should be on the local db, updates of the local db can be run regulary
    #can change back to initialize on times to make mongo work better
    


    search = UserSearch.new(tee_times)
    search.date_request
    search.course_search_to_long_name
    #run the on-demand tee times to confirm available
    #times.on_demand_course=search.course
    #times.on_demand_date=search.date
    #times.on_demand
    #times.label_course_date(search.course, search.date)
    #search.times_on_demand=times.times_update
    search.find_time
    search.filter_course_date
    search.search_for_time
    search.pretty_print

#still need to add an on demand search to check


end

def update_db
    times = TeeTimeSearch.new
    times.full_search
    times.cleaning
    puts "times downloaded"

    #download the times to the local database
    local_times = LocalTimesDB.new
    local_times.times_to_save = times
    local_times.save_times
end
