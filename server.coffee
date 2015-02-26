express = require 'express'
morgan = require 'morgan'
bodyParser = require 'body-parser'
errorHandler = require 'errorhandler'
cookieParser = require 'cookie-parser'
session = require 'express-session'
passport = require 'passport'
Router = require './app/routes'
Config = require './app/config'
debug = require('debug')('meshblu-google-authenticator:server')

port = process.env.MESHBLU_GOOGLE_AUTHENTICATOR_PORT ? 8008

app = express()
app.use morgan('dev')
app.use errorHandler()
app.use bodyParser.json()
app.use bodyParser.urlencoded(extended: true)
app.use cookieParser()

app.use session
  secret: 'super awesome cool secret'
  resave: false
  saveUninitialized: true

app.use passport.initialize()
app.use passport.session()

passport.serializeUser (user, done) =>
  done null, user.id

passport.deserializeUser (user, done) =>
  done null, user

app.engine 'html', require('ejs').renderFile

app.set 'view engine', 'html'

app.set 'views', __dirname + '/app/views'

app.listen port, =>
  debug "Meshblu Google Authenticator..."
  debug "Listening at localhost:#{port}"

  config = new Config
  config.register()

  router = new Router(app)
  router.register()
