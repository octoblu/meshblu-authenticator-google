passport = require 'passport'
debug = require('debug')('meshblu-google-authenticator:routes')
url = require 'url'

class Router
  constructor: (@app) ->

  register: =>
    @app.get  '/', (request, response) => response.status(200).send status: 'online'

    @app.get '/login', @storeCallbackUrl, passport.authenticate 'google', scope: ['profile', 'email']

    @app.get '/oauthcallback', passport.authenticate('google', { failureRedirect: '/login' }), @afterPassportLogin

  afterPassportLogin: (request, response) =>
    {callbackUrl} = request.session
    return response.status(401).send(new Error 'Invalid User') unless request.user
    return response.status(201).send(request.user) unless callbackUrl?
    uriParams = url.parse callbackUrl
    uriParams.query ?= {}
    uriParams.query.uuid = request.user.uuid
    uriParams.query.token = request.user.token
    return response.redirect(url.format uriParams)

  defaultRoute: (request, response) =>
    response.render 'index'

  storeCallbackUrl: (request, response, next) =>
    request.session.callbackUrl = request.query.callbackUrl
    next()

module.exports = Router
