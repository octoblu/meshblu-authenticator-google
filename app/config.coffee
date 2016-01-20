passport = require 'passport'
GoogleStrategy = require('passport-google-oauth2').Strategy
{DeviceAuthenticator} = require 'meshblu-authenticator-core'
debug = require('debug')('meshblu-google-authenticator:config')

googleOauthConfig =
  clientID: process.env.GOOGLE_CLIENT_ID
  clientSecret: process.env.GOOGLE_CLIENT_SECRET
  callbackURL: process.env.GOOGLE_CALLBACK_URL
  passReqToCallback: true

class GoogleConfig
  constructor: ({@meshbluHttp, @meshbluJSON}) ->

  onAuthentication: (request, accessToken, refreshToken, profile, done) =>
    profileId = profile?.id
    fakeSecret = 'google-authenticator'
    authenticatorUuid = @meshbluJSON.uuid
    authenticatorName = @meshbluJSON.name
    deviceModel = new DeviceAuthenticator {authenticatorUuid, authenticatorName, @meshbluHttp}
    query = {}
    query[authenticatorUuid + '.id'] = profileId
    device =
      name: profile.name
      type: 'octoblu:user'

    getDeviceToken = (uuid) =>
      @meshbluHttp.generateAndStoreToken uuid, (error, device) =>
        device.id = profileId
        done null, device

    deviceCreateCallback = (error, createdDevice) =>
      return done error if error?
      getDeviceToken createdDevice?.uuid

    deviceFindCallback = (error, foundDevice) =>
      # return done error if error?
      return getDeviceToken foundDevice.uuid if foundDevice?
      deviceModel.create
        query: query
        data: device
        user_id: profileId
        secret: fakeSecret
      , deviceCreateCallback

    deviceModel.findVerified query: query, password: fakeSecret, deviceFindCallback

  register: =>
    passport.use new GoogleStrategy googleOauthConfig, @onAuthentication

module.exports = GoogleConfig
