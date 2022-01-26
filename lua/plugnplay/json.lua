local json = {}

local helpers = require('plugnplay.helpers')

json.encode = helpers.is_minimum_version(0, 6, 0) and vim.json.encode or vim.fn.json_encode
json.decode = helpers.is_minimum_version(0, 6, 0) and vim.json.decode or vim.fn.json_decode

return json
