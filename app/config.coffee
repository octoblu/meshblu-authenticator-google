passport = require 'passport'
GoogleStrategy = require('passport-google-oauth2').Strategy
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
MeshbluDB = require 'meshblu-db'
debug = require('debug')('meshblu-google-authenticator:config')

googleOauthConfig =
  clientID: process.env.GOOGLE_CLIENT_ID
  clientSecret: process.env.GOOGLE_CLIENT_SECRET
  callbackURL: process.env.GOOGLE_CALLBACK_URL

class GoogleConfig
  constructor: (@meshbluConn, @meshbluJSON) ->
    @meshbludb = new MeshbluDB @meshbluConn

  onAuthentication: (accessToken, refreshToken, profile, done) =>
    debug 'Authenticated', accessToken
    authenticatorUuid = @meshbluJSON.uuid
    authenticatorName = @meshbluJSON.name
    deviceModel = new DeviceAuthenticator authenticatorUuid, authenticatorName, meshblu: @meshbluConn, meshbludb: @meshbludb
    query = {}
    query[authenticatorUuid + '.id'] = profile.id
    device = 
      name: profile.name
      type: 'octoblu:user'

    debug 'deviceModel.create', query, device, profile.id, accessToken
    deviceCallback = (error, createdDevice) => 
      debug 'device create error', error if error?
      debug 'device created', createdDevice
      createdDevice.id = profile.id
      done error, createdDevice

    deviceModel.create query, device, profile.id, accessToken, deviceCallback

  register: =>
    passport.use new GoogleStrategy googleOauthConfig, @onAuthentication

module.exports = GoogleConfig
