class App < Sinatra::Base
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
        @leaders = db.execute('SELECT * FROM leaders')
        erb(:"placeholder/index")
    end

    get '/placeholder/new' do
        erb(:"placeholder/new")
    end

    get '/placeholder/game' do
        @leaders = db.execute('SELECT * FROM leaders')
        erb(:"placeholder/game")
    end

    post '/placeholder' do
        p params
        name = params["leader_name"]
        country = params["leader_country"]
        continent = params["leader_continent"]
        img = params["leader_img"]
        db.execute("INSERT INTO leaders (name, country, continent, img) VALUES(?,?,?,?)", [name, country, continent, img])
        redirect "/placeholder"
    end

    get '/new_user' do 
        erb(:"/new_user")
    end

    get '/placeholder/result' do 
        erb(:"/placeholder/result")
    end
    
    post '/new_user' do
        p params
        password_hashed = BCrypt::Password.create(params["password"])
        user = params["user"]
        db.execute("INSERT INTO users (user, password) VALUES(?,?)", [user, password_hashed])
        redirect "/placeholder"
    end

    post '/placeholder/:id/status_update' do |id| 
        current_status = db.execute('SELECT status FROM leaders WHERE id = ?', [id]).first['status'] 
        new_status = current_status == 0 ? 1 : 0
        db.execute('UPDATE leaders SET status = ? WHERE id = ?', [new_status, id])
        redirect "/placeholder"
    end

    post '/placeholder/:id/delete' do |id|
        db.execute('DELETE FROM leaders WHERE id = ?', id)
        redirect "/placeholder"
    end

    post '/placeholder/logout' do
        session.destroy
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

    get '/login' do
        erb :"/login"
    end

    post '/login' do
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
end
