class App < Sinatra::Base
    enable :sessions

    def db
        return @db if @db
        @db = SQLite3::Database.new("db/WEB.sqlite")
        @db.results_as_hash = true
        return @db
    end

    get '/' do
        redirect('/placeholder')
    end

    get '/placeholder' do
        session[:time] = 60
        session[:question_index] = 1
        session[:score] = 0
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        @leaders = db.execute('SELECT * FROM leaders')
        erb(:"placeholder/index")
    end

    get '/placeholder/new' do
        session[:time] = 60
        session[:question_index] = 1
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        session[:score] = 0
        erb(:"placeholder/new")
    end

    get '/placeholder/game' do
        @TIME = session[:time]
        if session[:user_id]
            index = session[:question_index]
            leaders = session[:leaders]
            @current_leader = leaders[index]
            # If we've run out of questions
            if @current_leader.nil?
                redirect '/placeholder/result'
            end
            erb(:"placeholder/game")
        else
            redirect '/login'
        end
    end
    

    post '/placeholder' do
        session[:time] = 60
        session[:question_index] = 1
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        session[:score] = 0
        p params
        name = params["leader_name"]
        country = params["leader_country"]
        continent = params["leader_continent"]
        img = params["leader_img"]
        db.execute("INSERT INTO leaders (name, country, continent, img) VALUES(?,?,?,?)", [name, country, continent, img])
        redirect "/placeholder"
    end

    get '/new_user' do
        session[:time] = 60
        session[:question_index] = 1
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        session[:score] = 0
        erb(:"/new_user")
    end

    get '/placeholder/result' do
        @leaders = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        @score = session[:score]
        p session[:user_id]
        p @score
        score = params[""]
        if db.execute('SELECT score FROM users WHERE id = ?', session[:user_id]).first['score']== nil
            db.execute('UPDATE users SET score = ? WHERE id = ?', [@score, session[:user_id]])
            @message = "New High Score!"
        elsif @score >= db.execute('SELECT score FROM users WHERE id = ?', session[:user_id]).first['score']
            db.execute('UPDATE users SET score = ? WHERE id = ?', [@score, session[:user_id]])
            @message = "New High Score!"
        else
            @message = "Try again!"
        end
        session[:score] = 0
        session[:time] = 60
        session[:question_index] = 1
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        erb(:"/placeholder/result")
    end
    
    post '/new_user' do
        session[:score] = 0
        session[:time] = 60
        session[:question_index] = 1
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        p params
        password_hashed = BCrypt::Password.create(params["password"])
        user = params["user"]
        db.execute("INSERT INTO users (user, password) VALUES(?,?)", [user, password_hashed])
        redirect "/placeholder"
    end



    post '/placeholder/:id/delete' do |id|
        db.execute('DELETE FROM leaders WHERE id = ?', id)
        redirect "/placeholder"
    end

    post '/placeholder/logout' do
        session.delete(:user_id)
        redirect "/placeholder"
    end

    get '/placeholder/:id/edit' do |id|
        @leader = db.execute('SELECT * FROM leaders WHERE id = ?', id.to_i).first
        erb (:'placeholder/edit')
    end

    post '/placeholder/:id/update' do |id|
        p params
        name = params["leader_name"]
        country = params["leader_country"]
        continent = params["leader_continent"]
        img = params["leader_img"]
        db.execute('UPDATE leaders SET name = ?, country = ?, continent = ?, img WHERE id = ?', [name, country, continent, img, id])
        redirect "/placeholder"
    end

    # Define a POST route to check the name in the database
    post '/check_name' do
        name = params["leader_name"]
    
        # Query the database to check if the name exists
        leader = db.execute("SELECT * FROM leaders WHERE name = ?", name).first
  
        if leader.nil?
            # If name is not found, redirect to a failure or error page
            @error_message = "Leader not found!"
            redirect "/placeholder/game"  # Or you can render an error page
        else
            # If name is found, trigger the appropriate function
            # For example, set session or update database, etc.
            # You can redirect or render based on your needs
            @leader_found = leader
            session[:score] += 1
            redirect "/placeholder/game"  # Redirect to the game with the leader found
        end
        session[:question_index] += 1
    end
  

    get '/login' do
        session[:time] = 60
        session[:score] = 0
        session[:question_index] = 1
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        erb :"/login"
    end

    post '/login' do
        session[:time] = 60
        session[:score] = 0
        session[:question_index] = 1
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        username = params['user']
        cleartext_password = params['password'] 
        current_user = db.execute('SELECT * FROM users WHERE user = ?', username).first
        if current_user.empty?
            @error_message = "please insert username"
            return erb(:"/login")
        end
        if current_user == nil
            @error_message = "Wrong Username"
            return erb(:"/login")
        end

        password_from_db = BCrypt::Password.new(current_user['password'])
        if current_user.empty?
            @error_message = "please insert password"
            return erb(:"/login")
        end

        if password_from_db == cleartext_password 
            session[:user_id] = current_user['id'] 
            redirect "/placeholder"
        else
            @error_message = "Wrong password"
            return erb(:"/login")
        end

        p current_user
        p cleartext_password
    end

    get '/leaderboard' do
        session[:time] = 60
        session[:question_index] = 1
        session[:score] = 0
        session[:leaders] = db.execute('SELECT * FROM leaders ORDER BY RANDOM()')
        @users = db.execute('SELECT * FROM users ORDER BY score DESC')
        erb (:"placeholder/leaderboard")
    end

end
