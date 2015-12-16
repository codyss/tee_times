require 'rest_client'
require 'mongo'


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
    attr_accessor :course, :date
    attr_reader :times_list, :times_update, :clean_times 

    def initilize
        @times_list = []
        @times_update = []
    end

    def on_demand
        response_on_demand = RestClient.get "https://www.kimonolabs.com/api/ondemand/4ujite74?apikey=REK0Ffj1XIg1BhGMU3wDHLBv9kQbB2ur&kimpath5=#{@date}&kimpath3=#{@course}"
        @times_update = JSON.parse(response_on_demand)["results"]["collection1"]
    end

    def full_search
        response = RestClient.get "https://www.kimonolabs.com/api/4ujite74?apikey=REK0Ffj1XIg1BhGMU3wDHLBv9kQbB2ur"
        @times_full_data = JSON.parse(response)
        @times_list = JSON.parse(response)["results"]["collection1"]
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
        @clean_times.map do |i|
            i['players'].each_with_index do |item, index|
                if item['class'].include?('blue')
                    i['num_players'] = index + 1
                end
            end
        end
    end


    def time_to_military
        @clean_times.map do |i|
            if i['time'][-2,2] == 'PM'
                if i['time'][0,2] == '12'
                    i['time'] = i['time'][0,i['time'].length-3]
                    i['time'] = i['time'].delete(':')
                else
                    i['time'] = i['time'][0,i['time'].length-3]
                    i['time'][0,2] = (i['time'][0,1].to_i + 12).to_s
                end
            elsif i['time'][0,2] == '12'
                i['time'] = i['time'][0,i['time'].length-3]
                i['time'][0,2] = (i['time'][0,1].to_i - 12).to_s
            else
                i['time'] = i['time'][0,i['time'].length-3]
                i['time'] = i['time'].delete(':')
            end
        end
    end

    def pull_out_course_date
        #method should pull out the course and the date for easy searching
        #method works on the full pull
        for i in @clean_times
            i['course'] = i['url'][i['url'].index('/at/')+4..i['url'].index('/on/')-1]
            i['date'] = i['url'][i['url'].index('/on/')+4..i['url'].length]
        end
        @clean_times
    end

    def label_course_date(course, date)
        #method adds the name of the course and the date to each tee time record
        @times_update.map do |i|
            i['course'] = course
            i['date'] = date
        end
    end

    def label_version_run_time
        @clean_times.map {|i| i['version_run_time'] = @times_full_data['thisversionrun']}
    end

    def kimono_records_count
        #returns the number of records in the first kimono search
        @times_full_data['count']
    end

    def count_tee_times
        #returns the number of tee times in the clean times list
        @clean_times.length
    end

    def cleaning
        remove_duplicates
        num_players
        time_to_military
        pull_out_course_date
        label_version_run_time
    end

    def on_demand_cleaning
        remove_duplicates
        num_players
        time_to_military
        label_course_date
    end

end


class UserSearch
    attr_reader :times, :course, :date

    def initialize(times)
        @times = times
        @times_course_date = []
        @times_on_demand = []
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
        #need a method that identifies when there are no times at course that day
        if @times_course_date == []
            true
        else
            false
        end
    end


    def filter_course_date
        #after pull out course date method, this will search the times fed to it based on the course, date provided by user
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
                request_time_i = @time_request[0,@time_request.index(':')+1].to_i*100 + @time_request[-2,2].to_i
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
        puts "What date would you like to play? (mmm-DD)"
        @date = gets.strip
    end
end


class LocalTimesDB
    attr_accessor :course, :date

    def initialize
        @client = Mongo::Client.new([ '127.0.0.1:27017' ], :database => 'tee_times')
        @times_collection = @client[:tee_times]
    end

    def times_to_save=(times_to_save)
        @times_to_save = times_to_save.clean_times
    end

    def save_times
        result = @times_collection.insert_many(@times_to_save)
    end

    def find_times
        @times = @times_collection.find()
    end

    def delete_prior_download
        #removes the current download from the live times collection
        result = @times_collection.delete_many
    end

    def archive_old_times
        #need to add an identifiying information to each tee time saved - like when it was pulled
        find_times
        @archived_times = @client[:archived_tee_times]
        @archived_times.insert_many(@times)
    end

end




def search

    #get the latest times - changed to pull from database

    times = LocalTimesDB.new
    tee_times = times.find_times

    #search should be on the local db, updates of the local db can be run regulary
    #can change back to initialize on times to make mongo work better


    search = UserSearch.new(tee_times)
    search.date_request
    search.course_search_to_long_name

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
    puts "#{times.count_tee_times} times downloaded"

    #download the times to the local database
    #should move old times to an archive
    local_times = LocalTimesDB.new
    local_times.archive_old_times
    local_times.delete_prior_download
    local_times.times_to_save = times
    local_times.save_times
end
