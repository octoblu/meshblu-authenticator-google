passport = require 'passport'

class Router
  constructor: (@app) ->

  register: =>
    @app.get '/', (request, response) =>
      response.render 'index'

    @app.get '/login', passport.authenticate 'google', scope: ['profile', 'email']

    @app.get '/api/auth/callback',
      passport.authenticate('google', { failureRedirect: '/login' }),
      (request, response) =>
        response.redirect '/'

module.exports = Router
