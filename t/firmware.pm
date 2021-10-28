#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package t::firmware;

use lib 'lib';
use Cwd qw(cwd);
use Test::Nginx::Socket::Lua::Stream -Base;

repeat_each(1);
log_level('debug');
no_long_string();
no_shuffle();
no_root_location(); # avoid generated duplicate 'location /'
worker_connections(1024);
master_on();

my $runtime_dir = $ENV{'WORKBENCH_DIR'} || cwd();
my $nginx_binary = $ENV{'TEST_NGINX_BINARY'} || 'nginx';

# extension function
sub run_or_exit ($) {
    my ($cmd) = @_;
    my $output = `$cmd`;
    if ($?) {
        warn "$output";
        exit 1;
    }
}

# hijack inject nginx conf
add_block_preprocessor(sub {
    # fetch nginx test
    my ($block) = @_;

    # prefetch default
    my $http_config = $block->http_config // '';

    my $lua_deps_path = <<_EOC_;
    lua_package_path "${runtime_dir}/lib/?.lua;;";
    lua_package_cpath "${runtime_dir}/lib/?.lua;;";
_EOC_

    $http_config .= $lua_deps_path;

    # reset default http_config env
    $block->set_value("http_config", $http_config);

    # add default error handler to fetch overview error log
    # $block->set_value("no_error_log", "[error]");

    # reload
    $block;
});

add_cleanup_handler(sub {

});
