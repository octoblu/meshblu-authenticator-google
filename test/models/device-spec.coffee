Device = require '../../app/models/device'
bcrypt = require 'bcrypt'

describe 'Device', ->
  describe '->buildDeviceUpdate', ->
    beforeEach ->
      @meshblu = {}
      @meshblu.sign = sinon.stub()
      @dependencies = {meshblu:@meshblu}
      @sut = new Device @dependencies

    describe 'when called with data', ->
      beforeEach ->
        @sut.buildDeviceUpdate "auuid", 'authenticators-r-us', 'name', '1', "pretendyoucantreadthis"

      it 'should call meshblu.sign', ->
        expect(@meshblu.sign).to.have.been.calledWith {id: '1', name: 'name', secret: 'pretendyoucantreadthis'}

  describe '->create', ->
    beforeEach ->
      @meshblu = sinon.stub()
      @dependencies = {meshblu: @meshblu}
      @sut = new Device @dependencies

    describe 'calling exists', ->
      beforeEach ->
        @sut.exists = sinon.spy()
        @sut.create 'google.id': '959', {}, '','','',''

      it 'should call exists', ->
        expect(@sut.exists).to.have.been.calledWith 'google.id' : '959'

    describe 'when exists yields true', ->
      beforeEach (done) ->
        @sut.exists = sinon.stub().yields true
        @sut.insert = sinon.spy()
        @sut.create 'google.id': '595', {}, '','','','', (@error) => done()

      it 'should not call insert', ->
        expect(@sut.insert).not.to.have.been.called

      it 'should have a device already exists error', ->
        expect(@error.message).to.equal @sut.ERROR_DEVICE_ALREADY_EXISTS

    describe 'when exists yields false', ->
      beforeEach ->
        @sut.exists = sinon.stub().yields false
        @sut.insert = sinon.spy()
        @sut.create 'google.id': '595', {google:{id: 123}}, '','','',''

      it 'should call insert', ->
        expect(@sut.insert).to.have.been.calledWith {google:{id: 123}}

    describe 'when exists yields false and insert yields an error', ->
      beforeEach (done) ->
        @sut.exists = sinon.stub().yields false
        @sut.insert = sinon.stub().yields new Error
        @sut.create 'google.id': '595', {}, '','','','', (@error) => done()

      it 'should have an error', ->
        expect(@error).to.exist

    describe 'when exists yields false and insert yields a device', ->
      beforeEach (done) ->
        @meshblu.sign = sinon.stub().returns 'trust-me'
        @sut.exists = sinon.stub().yields false
        @sut.insert = sinon.stub().yields null, {uuid: 'wobbly-table'}
        @sut.hashSecret = sinon.stub().yields null
        @sut.update = sinon.stub().yields null
        @sut.create 'google.id': '595', {}, '','','','secret', (@error) => done()

      it 'should call hashSecret', ->
        expect(@sut.hashSecret).to.have.been.calledWith 'secret'

    describe 'when exists yields false and insert yields a device and hashSecret yields an error', ->
      beforeEach (done) ->
        @sut.exists = sinon.stub().yields false
        @sut.insert = sinon.stub().yields null, {uuid: 'wobbly-table'}
        @sut.hashSecret = sinon.stub().yields new Error
        @sut.create 'google.id': '595', {}, '','','',null, (@error) => done()

      it 'should have an error', ->
        expect(@error).to.exist

    describe 'when exists yields false and insert yields a device and hashSecret yields a secret', ->
      beforeEach (done) ->
        @meshblu.sign = sinon.stub().returns 'trust-me'
        @sut.exists = sinon.stub().yields false
        @sut.insert = sinon.stub().yields null, {uuid: 'wobbly-table'}
        @sut.hashSecret = sinon.stub().yields null, '$$$$$$$$$$'
        @sut.update = sinon.stub().yields null
        @sut.create 'google.id': '595', {}, 'auth-id', 'authenticator', '1', 'secret', (@error) => done()

      it 'should call update', ->
        expect(@sut.update).to.have.been.calledWith {uuid: 'wobbly-table', 'auth-id': {name : 'authenticator', id: '1', secret: '$$$$$$$$$$', signature: 'trust-me'}}

    describe 'when creating a different device and exists yields false and insert yields a device and hashSecret yields a secret', ->
      beforeEach (done) ->
        @meshblu.sign = sinon.stub().returns 'i-know-what-you-did'
        @sut.exists = sinon.stub().yields false
        @sut.insert = sinon.stub().yields null, {uuid: 'terrible-soda'}
        @sut.hashSecret = sinon.stub().yields null, '########'
        @sut.update = sinon.stub().yields null
        @sut.create 'google.id': '595', {}, 'not-auth-id', 'also-an-authenticator', '11', 'not-so-secret', (@error) => done()

      it 'should call update', ->
        expect(@sut.update).to.have.been.calledWith {uuid: 'terrible-soda', 'not-auth-id': {name : 'also-an-authenticator', id: '11', secret: '########', signature: 'i-know-what-you-did'}}

  describe '->exists', ->
    beforeEach ->
      @meshbludb = findOne: =>
      @dependencies = meshbludb: @meshbludb
      @sut = new Device @dependencies

    describe 'when exists is called', ->
      beforeEach ->
        sinon.spy @meshbludb, 'findOne'
        @sut.exists 'google.id': '123'

      it 'should call findOne with query', ->
        expect(@meshbludb.findOne).to.have.been.calledWith 'google.id': '123'

    describe 'when exists yields an device', ->
      beforeEach (done) ->
        sinon.stub(@meshbludb, 'findOne').yields null, uuid: 'label-maker'
        @sut.exists 'google.id' : '12350', (@exists) => done()

      it 'should have an device', ->
        expect(@exists).to.be.true

    describe 'when exists yields nothing', ->
      beforeEach (done) ->
        sinon.stub(@meshbludb, 'findOne').yields null
        @sut.exists 'google.id' : '12350', (@exists) => done()

      it 'should not have an device', ->
        expect(@exists).to.be.false

  describe '->insert', ->
    beforeEach ->
      @meshbludb = {}
      @meshbludb.insert = sinon.stub()
      @dependencies = {meshbludb:@meshbludb}
      @sut = new Device @dependencies

    describe 'when insert is called', ->
      beforeEach (done) ->
        @meshbludb.insert.yields null, {}
        @sut.insert {'pen':'sharpie'}, (@error, @device) => done()

      it 'should call meshbludb.insert', ->
        expect(@meshbludb.insert).to.have.been.calledWith {'pen': 'sharpie'}

      it 'should yield a device', ->
        expect(@device).to.exist

    describe 'when insert is called with a different device', ->
      beforeEach ->
        @sut.insert {'skinny': 'stick'}

      it 'should call meshbludb.insert', ->
        expect(@meshbludb.insert).to.have.been.calledWith {'skinny': 'stick'}

  describe '->hashSecret', ->
    beforeEach ->
      @sut = new Device

    describe 'when hashSecret is called', ->
      beforeEach (done) ->
        @sut.hashSecret null, (@error) => done()

      it 'should yield an error', ->
        expect(@error).to.exist

    describe 'when bcryptn', ->
      beforeEach (done) ->
        @sut.hashSecret 'shhh', (@error, @hashedSecret) => done()

      it 'should yield a bcrypted secret', ->
        expect(bcrypt.compareSync('shhh', @hashedSecret)).to.be.true

  describe '->update', ->
    beforeEach ->
      @meshbludb = {}
      @meshbludb.update = sinon.stub()
      @dependencies = {meshbludb:@meshbludb}
      @sut = new Device @dependencies

    describe 'when update yields an error', ->
      beforeEach (done) ->
        @meshbludb.update.yields new Error
        @sut.update {}, (@error) => done()

      it 'should yield an error', ->
        expect(@error).to.exist

    describe 'when update is called', ->
      beforeEach (done) ->
        @meshbludb.update.yields null
        @sut.update {some: 'stuff'}, (@error) => done()

      it 'should get called with stuff', ->
        expect(@meshbludb.update).to.have.been.calledWith {some: 'stuff'}

  describe '->verifySignature', ->
    beforeEach ->
      @meshblu = {}
      @meshblu.verify = sinon.spy()
      @dependencies = {meshblu: @meshblu}
      @sut = new Device @dependencies

    describe 'when called', ->
      beforeEach ->
        @sut.verifySignature id: 'foo', signature: 'this-is-my-rifle'

      it 'should meshblu.verify', ->
        expect(@meshblu.verify).to.have.been.calledWith {id: 'foo'}, 'this-is-my-rifle'

    describe 'when called with a different device', ->
      beforeEach ->
        @sut.verifySignature id: 'bar', signature: 'this-is-my-gun'

      it 'should meshblu.verify', ->
        expect(@meshblu.verify).to.have.been.calledWith {id: 'bar'}, 'this-is-my-gun'
