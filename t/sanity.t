use t::firmware 'no_plan';

repeat_each(2);
no_long_string();
no_root_location();

run_tests;

__DATA__

=== TEST 1: hello, world
This is just a simple demonstration of the
echo directive provided by ngx_http_echo_module.
--- config
location = /t {
    content_by_lua_block {
        ngx.say('hello, world!')
    }
}
--- request
GET /t
--- response_body
hello, world!
--- no_error_log
[error]
