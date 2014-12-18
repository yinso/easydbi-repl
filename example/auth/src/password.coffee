crypto = require 'crypto'

b2h = []
h2b = {}
for i in [0...256] by 1
  b2h[i] = (i ^ 0x100).toString(16).substring(1)
  h2b[b2h[i]] = i

toHex = (bytes) ->
  for byte in bytes
    b2h[byte]

makeSalt = (size = 32) ->
  toHex(crypto.randomBytes(size)).join('')

combine = (salt, common, password) ->
  ("#{salt}:#{common}:#{password}" for i in [0...100]).join(';')

makeHmac = (type, key, salt, passwd) ->
  hmac = crypto.createHmac type, key
  hmac.update combine(salt, key, passwd)
  hmac.digest('hex')

passwordStrength = (passwd) ->
  countHelper = (ary) -> if ary then ary.length else 0
  normalize = (score) ->
    if score > 100
      100
    else if score < 0
      0
    else
      score
  totalLength = passwd.length * 4
  onlyLower = if passwd.match /^[a-z]+$/ then -30 else 0
  onlyUpper = if passwd.match /^[A-Z]+$/ then -20 else 0
  onlyDigit = if passwd.match /^[0-9]+$/ then -25 else 0
  symbols = countHelper(passwd.match /(\W)/g) * 5
  uppers = countHelper(passwd.match /([A-Z])/g) * 3
  digits = countHelper(passwd.match /([0-9])/g) * 2
  normalize(totalLength + onlyLower + onlyUpper + onlyDigit + symbols + uppers + digits)

class Password
  @hashType: 'sha256'
  @secret: 'default-secret'
  @strength: passwordStrength
  @saltSize: 32
  @threshold: 70
  @makeSalt: makeSalt
  @makeHmac: (salt, passwd) =>
    makeHmac @hashType, @secret, salt, passwd
  @generate: ({type, salt, password, confirm}, cb) =>
    #console.log 'Password.generate', type, salt, password, confirm
    salt ||= @makeSalt(@saltSize)
    try
      if password != confirm
        return cb new Error("password_does_not_match")
      strength = @strength(password)
      if strength > @threshold
        digest = makeHmac type, salt, password
        cb null, {salt: salt, hash: digest, type: type}
      else
        cb new Error("password_weak")
    catch e
      cb e
  @verify: ({type, salt, hash}, passwd, cb) =>
    try
      digest = makeHmac type, salt, passwd
      #console.log 'Password.verify', type, salt, hash, passwd, digest == hash
      cb null, digest == hash
    catch e
      cb e

module.exports = Password


