bcrypt = require 'bcrypt'
_ = require 'lodash'

class Device
  ERROR_DEVICE_ALREADY_EXISTS : 'device already exists'

  constructor: (dependencies={})->
    @meshbludb = dependencies.meshbludb
    @meshblu = dependencies.meshblu

  create: (query, data, authenticatorUuid, authenticatorName, id, secret, callback=->) =>
    @insert query, data, (error, device) =>
      return callback error if error?
      @hashSecret secret, (error, hashedSecret) =>
        return callback error if error?
        updateData = @buildDeviceUpdate(device.uuid, authenticatorUuid, authenticatorName, id, hashedSecret)
        @update updateData, callback

  verifySignature: (data) =>
    @meshblu.verify _.omit(data, 'signature'), data.signature

  exists: (query, callback=->) =>
    @meshbludb.findOne query, (error, device) =>
      callback device?

  hashSecret: (secret, callback=->) =>
    bcrypt.hash secret, 8, callback

  insert: (query, data, callback=->) =>
    @exists query, (deviceExists) =>
      return callback new Error @ERROR_DEVICE_ALREADY_EXISTS if deviceExists 
      @meshbludb.insert data, callback

  update: (data, callback=->) =>
    @meshbludb.update data, callback

  buildDeviceUpdate: (deviceUuid, authenticatorUuid, name, id, hashedSecret) =>
    data = {
      id: id
      name: name
      secret: hashedSecret
    }
    signature = @meshblu.sign(data)
    deviceUpdate = {
      uuid: deviceUuid
    }
    deviceUpdate[authenticatorUuid] = _.defaults({signature: signature}, data)
    return deviceUpdate

module.exports = Device
