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
    profileId = profile?.id
    authenticatorUuid = @meshbluJSON.uuid
    authenticatorName = @meshbluJSON.name
    deviceModel = new DeviceAuthenticator authenticatorUuid, authenticatorName, meshblu: @meshbluConn, meshbludb: @meshbludb
    query = {}
    query[authenticatorUuid + '.id'] = profileId
    device = 
      name: profile.name
      type: 'octoblu:user'

    deviceCreateCallback = (error, createdDevice) => 
      debug 'device create error', error if error?
      debug 'device created', createdDevice
      createdDevice?.id = profileId
      done error, createdDevice

    deviceFindCallback = (error, foundDevice) =>
      debug 'device find error', error if error?
      debug 'device find', foundDevice
      if foundDevice
        foundDevice?.id = profileId
        return done null, foundDevice
      deviceModel.create query, device, profileId, accessToken, deviceCreateCallback
 
    debug 'device query', query
    deviceModel.findVerified query, accessToken, deviceFindCallback
    
  register: =>
    passport.use new GoogleStrategy googleOauthConfig, @onAuthentication

module.exports = GoogleConfig
