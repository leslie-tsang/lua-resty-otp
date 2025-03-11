use t::firmware 'no_plan';

repeat_each(2);
no_long_string();
no_root_location();

run_tests;

__DATA__

=== TEST 1: Unit test
--- config
location = /t {
    content_by_lua_block {
        -- load common libs
        local resty_otp = require("resty.otp")

        local TOTP = resty_otp.totp_init("JBSWY3DPEHPK3PXP")
        -- UTC - 20200101 00:00:00
        ngx.print(TOTP:calc_token(946656000))
    }
}
--- request
GET /t
--- response_body chomp
458138
--- no_error_log
[error]


=== TEST 2: Verify instance independence
--- config
location = /t {
    content_by_lua_block {
        -- load common libs
        local resty_otp = require("resty.otp")

        local TOTP_1 = resty_otp.totp_init("JBSWY3DPEHPK3PXP")
        local TOTP_2 = resty_otp.totp_init("JBSWY3DPEHPK3PX2")
        -- UTC - 20200101 00:00:00
        ngx.print(TOTP_1:calc_token(946656000))
    }
}
--- request
GET /t
--- response_body chomp
458138
--- no_error_log
[error]


=== TEST 3: Fixed random seed
--- config
location = /t {
    content_by_lua_block {
        -- load common libs
        local resty_otp = require("resty.otp")
        resty_otp.randomseed(42)

        local TOTP = resty_otp.totp_init()
        -- UTC - 20200101 00:00:00
        ngx.print(TOTP:calc_token(946656000))
    }
}
--- request
GET /t
--- response_body chomp
171492
--- no_error_log
[error]
