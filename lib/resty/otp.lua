-- load comment libs
local require = require

-- local function
local ngx            = ngx
local ngx_hmac_sha1  = ngx.hmac_sha1
local ngx_time       = ngx.time
local bit_band       = bit.band
local bit_lshift     = bit.lshift
local bit_rshift     = bit.rshift
local math_floor     = math.floor
local math_random    = math.random
local string_char    = string.char
local string_format  = string.format
local string_reverse = string.reverse
local table_concat   = table.concat
local table_insert   = table.insert
local table_unpack   = table.unpack


local BASE32_HASH = {
    [0 ] = 65, [1 ] = 66, [2 ] = 67, [3 ] = 68, [4 ] = 69, [5 ] = 70,
    [6 ] = 71, [7 ] = 72, [8 ] = 73, [9 ] = 74, [10] = 75, [11] = 76,
    [12] = 77, [13] = 78, [14] = 79, [15] = 80, [16] = 81, [17] = 82,
    [18] = 83, [19] = 84, [20] = 85, [21] = 86, [22] = 87, [23] = 88,
    [24] = 89, [25] = 90,
    [26] = 50, [27] = 51, [28] = 52, [29] = 53, [30] = 54, [31] = 55,

    [50] = 26, [51] = 27, [52] = 28, [53] = 29, [54] = 30, [55] = 31,
    [65] = 0,  [66] = 1,  [67] = 2,  [68] = 3,  [69] = 4,  [70] = 5,
    [71] = 6,  [72] = 7,  [73] = 8,  [74] = 9,  [75] = 10, [76] = 11,
    [77] = 12, [78] = 13, [79] = 14, [80] = 15, [81] = 16, [82] = 17,
    [83] = 18, [84] = 19, [85] = 20, [86] = 21, [87] = 22, [88] = 23,
    [89] = 24, [90] = 25,
}

-- module define
local _M = {
    _VERSION = '0.01.01',
}


local function base32_decode(secret_str)
    local secret_token = {secret_str:byte(1, -1)}
    local secret_token_base32 = {}

    local n = 0
    local bs = 0

    for i, v in ipairs(secret_token) do
        n = bit_lshift(n, 5)
        n = n + BASE32_HASH[v]
        bs = (bs + 5) % 8
        if (bs < 5) then
            secret_token_base32[#secret_token_base32 + 1] = bit_rshift(bit_band(n, bit_lshift(0xFF, bs)), bs)
        end
    end

    return string_char(table_unpack(secret_token_base32))
end


local function base32_encode(secret_str)
    local secret_token = {secret_str:byte(1, -1)}
    local secret_token_base32 = {}
    local tmp_char = 0

    local c = 0
    local n = 0
    local tmp_n = 0
    local bs = 0

    for i, v in ipairs(secret_token) do
        n = bit_lshift(n, 8)
        n = n + v
        c = c + 8
        bs = c % 5
        tmp_n = bit_rshift(n, bs)

        for j = c - bs - 5, 0, -5 do
            tmp_char = bit_rshift(bit_band(tmp_n, bit_lshift(0x1F, j)), j)
            secret_token_base32[#secret_token_base32 + 1] = BASE32_HASH[tmp_char]
        end

        c = bs
        n = bit_band(n, bit_rshift(0xFF, 8 - bs))
    end

    return string_char(table_unpack(secret_token_base32))
end


local function percent_encode_char(c)
    return string_format("%%%02X", c:byte())
end


local function url_encode(str)
    local r = str:gsub("[^a-zA-Z0-9.~_-]", percent_encode_char)
    return r
end


local function totp_time_calc(ngx_time)
    local ngx_time_str = {}

    for i = 1, 8 do
        table_insert(ngx_time_str, bit_band(ngx_time, 0xFF))
        ngx_time = bit_rshift(ngx_time, 8)
    end

    return string_reverse(string_char(table_unpack(ngx_time_str)))
end


local function totp_new_key()
    local tmp_k = ""
    math.randomseed(ngx.time())
    for i = 1, 10 do
        tmp_k = tmp_k .. string_char(math_random(0, 255))
    end
    return base32_encode(tmp_k)
end


------ TOTP functions ------
local TOTP_MT = {}


function _M.totp_init(secret_key)
    local m = {
        type = "totp",
    }
    setmetatable(m, { __index = TOTP_MT, __tostring = TOTP_MT.serialize })
    m:new_key(secret_key)
    return m
end


function TOTP_MT:new_key(secret_key)
    self.key = secret_key or totp_new_key()
    self.key_decoded = base32_decode(self.key)
end


function TOTP_MT:calc_token(var_time)
    local ngx_time = math_floor(var_time / 30)
    local HMAC_buffer = {ngx_hmac_sha1(self.key_decoded, totp_time_calc(ngx_time)):byte(1, -1)}

    local HMAC_offset = bit_band(HMAC_buffer[20], 0xF)
    local TOTP_token = 0

    for i = 1, 4 do
        TOTP_token = TOTP_token + bit_lshift(HMAC_buffer[HMAC_offset + i], (4 - i) * 8 )
    end

    TOTP_token = bit_band(TOTP_token, 0x7FFFFFFF)
    TOTP_token = TOTP_token % 1000000
    return string_format("%06d", TOTP_token)
end


function TOTP_MT:verify_token(token)
    return (token == self:calc_token(ngx_time()))
end


function TOTP_MT:get_url(issuer, account)
    return table_concat{
        "otpauth://totp/",
        account,
        "?secret=", self.key,
        "&issuer=", issuer,
    }
end


function TOTP_MT:get_qr_url(issuer, account)
    return table_concat{
        "https://chart.googleapis.com/chart",
        "?chs=", "200x200",
        "&cht=qr",
        "&chl=200x200",
        "&chld=M|0",
        "&chl=", url_encode(self:get_url(issuer, account)),
    }
end

function TOTP_MT:serialize()
    return table_concat{
        "type:totp\n",
        "secret:", self.key,
        "secret_decoded", self.key_decoded,
    }
end

return _M
