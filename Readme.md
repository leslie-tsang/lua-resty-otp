Name
====

lua-resty-otp - Lua OTP lib for OpenResty


Table of Contents
=================

* [Name](#name)
* [Status](#status)
* [Usage](#usage)
    * [Calculate OTP token](#calculate-otp-token)
    * [Generate QR Code](#generate-qr-code)
    * [Verify OTP](#verify-otp)
* [Bugs and Patches](#bugs-and-patches)

Status
======

[![ci-ubuntu](https://github.com/leslie-tsang/lua-resty-otp/actions/workflows/ci-unit-test.yml/badge.svg)](https://github.com/leslie-tsang/lua-resty-otp/actions/workflows/ci-unit-test.yml)

This library is already usable though still highly experimental.

The Lua API is still in flux and may change in the near future without notice.

[Back to TOC](#table-of-contents)

Usage
================
## Calculate OTP token
```lua
local lib_otp = require ("resty.otp")
local TOTP = lib_otp.totp_init("JBSWY3DPEHPK3PXP")
-- UTC format of date `20200101 00:00:00` -> 946656000
-- use `ngx.time()` instead of `946656000` in prod env
ngx.say("TOTP_Token -> ", TOTP:calc_token(946656000))
```

> Output

```bash
458138
```

[Back to TOC](#table-of-contents)

## Generate QR Code
```lua
local lib_otp = require ("resty.otp")
local TOTP = lib_otp.totp_init("JBSWY3DPEHPK3PXP")
local url = TOTP:get_qr_url('OpenResty-TOTP', 'hello@example.com')
local html = [[
<img src='%s' />
]]

html = string.format(html, url)
ngx.header['Content-Type'] = 'text/html'
ngx.say(html)
```

> Output

![QR Code](https://chart.googleapis.com/chart?chs=200x200&cht=qr&chl=200x200&chld=M|0&chl=otpauth%3A%2F%2Ftotp%2Fhello%40example.com%3Fsecret%3DJBSWY3DPEHPK3PXP%26issuer%3DOpenResty-TOTP)

Scan the QR Code with Google Authenticator

[Back to TOC](#table-of-contents)

## Verify OTP
```lua
local lib_otp = require ("resty.otp")
local TOTP = lib_otp.totp_init("JBSWY3DPEHPK3PXP")
local token = ngx.var.arg_otp
ngx.say("Verify Token : ", TOTP:verify_token(token))
```

Use OTP from Google Authenticator

```bash
curl localhost/check?otp=734923
```

> Output

```bash
Verify Token : true
```

[Back to TOC](#table-of-contents)

Bugs and Patches
================

Please report bugs or submit patches by

1. Creating a ticket on the [GitHub Issue Tracker](https://github.com/leslie-tsang/lua-resty-otp/issues).

[Back to TOC](#table-of-contents)
