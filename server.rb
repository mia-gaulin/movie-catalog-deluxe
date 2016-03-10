require "sinatra"
require "pg"

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/' do
  erb :index
end

get '/actors' do
  @actor_list = []

  db_connection do |conn|
    @actor_list = conn.exec("SELECT * FROM actors;")
  end

  erb :'actors/index'
end

get '/actors/:id' do
  @actor_info = []
  @actor_data = []

  db_connection do |conn|
    @actor_info = conn.exec("SELECT * FROM actors WHERE actors.id = ($1)", [params["id"]]).first
  end

  db_connection do |conn|
    @actor_data = conn.exec("SELECT movies.*, cast_members.character
    FROM movies JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE actors.id = ($1)
    ORDER BY movies.title", [params["id"]])
  end

  erb :'actors/show'
end

get '/movies' do
  @movie_list = []

  db_connection do |conn|
    @movie_list = conn.exec("SELECT movies.*, genres.name AS genre, studios.name AS studio FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    ORDER BY movies.title;")
  end

  erb :'movies/index'
end

get "/movies/:movie_id" do
  @movie_info = []
  @movie_data = []

  db_connection do |conn|
    @movie_info = conn.exec("SELECT movies.*, genres.name AS genre, studios.name AS studio, cast_members.character, actors.name AS actor, actors.id AS actor_id
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    LEFT JOIN cast_members ON movies.id = cast_members.movie_id
    LEFT JOIN actors ON cast_members.actor_id = actors.id
    WHERE movies.id = ($1)", [params["movie_id"]]).first
  end

  erb :'movies/show'
end
