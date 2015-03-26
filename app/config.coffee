passport = require 'passport'
GoogleStrategy = require('passport-google-oauth2').Strategy
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
MeshbluDB = require 'meshblu-db'
debug = require('debug')('meshblu-google-authenticator:config')

googleOauthConfig =
  clientID: process.env.GOOGLE_CLIENT_ID
  clientSecret: process.env.GOOGLE_CLIENT_SECRET
  callbackURL: process.env.GOOGLE_CALLBACK_URL
  passReqToCallback: true

class GoogleConfig
  constructor: (@meshbluConn, @meshbluJSON) ->
    @meshbludb = new MeshbluDB @meshbluConn

  onAuthentication: (request, accessToken, refreshToken, profile, done) =>
    profileId = profile?.id
    fakeSecret = 'google-authenticator'
    authenticatorUuid = @meshbluJSON.uuid
    authenticatorName = @meshbluJSON.name
    deviceModel = new DeviceAuthenticator authenticatorUuid, authenticatorName, meshblu: @meshbluConn, meshbludb: @meshbludb
    query = {}
    query[authenticatorUuid + '.id'] = profileId
    device =
      name: profile.name
      type: 'octoblu:user'

    getDeviceToken = (uuid) =>
      @meshbluConn.generateAndStoreToken uuid: uuid, (device) =>
        device.id = profileId
        done null, device

    deviceCreateCallback = (error, createdDevice) =>
      return done error if error?
      getDeviceToken createdDevice?.uuid

    deviceFindCallback = (error, foundDevice) =>
      # return done error if error?
      return getDeviceToken foundDevice.uuid if foundDevice?
      deviceModel.create query, device, profileId, fakeSecret, deviceCreateCallback

    deviceModel.findVerified query, fakeSecret, deviceFindCallback

  register: =>
    passport.use new GoogleStrategy googleOauthConfig, @onAuthentication

module.exports = GoogleConfig
