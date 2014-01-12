# == Class: puppet::master::defaults
#
#   This class is a defaults class used to centralize default values that
#   should be used across both the puppet::master and puppet::client workflows.
#   Heira could have been used but for now the puppet module is not heira
#   aware.
#
#   The variables contained herin were part of the main puppet class however
#   since they could be site specific it was decided to separate them into a
#   separate file that could be readily maintained by the site administrator.
#
#   The idea is that rather than forcing the clients to specify parameters or
#   requiring the site administrator to modify the master or client classes,
#   the common defaults could be presented here.  The other option would be
#   to recommend that each site create a site specific class which then feeds
#   the values to this module.
#
#   Example:
#   class mysite::puppet::client {
#       class { 'puppet::client':
#           agent => {
#               $option => $value,
#               etc.
#           },
#       }
#   }
#
#   The current behavior is up for debate and may be changed in the future.
#
# === Parameters
#
#   None
#
# === Variables
#
# [*agent*]
#   Default custom agent configuration block
#
# [*master*]
#   Default custom master configuration block
#
# === Supported Operating Systems
#
#   * CentOS
#   * Debian
#   * Fedora
#   * OpenSUSE
#   * RedHat
#   * Ubuntu
#
# === Authors
#
#   Bennett Samowich <bennett@foolean.org>
#
# === Copyright
#
#   Copyright (c) 2013 Foolean.org
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
class puppet::master::defaults {
    $agent = {
        pluginsync      => true,
        reports         => 'log',
        runinterval     => 315360000,
        server          => $::servername,
        show_diff       => true,
        summarize       => true,
        postrun_command => "${puppet::confdir}/rundir post",
        prerun_command  => "${puppet::confdir}/rundir pre",
    }

    $main = {
        vardir                           => $puppet::vardir,
        confdir                          => $puppet::confdir,
        config_version                   => '/bin/date +%Y%m%d%H%M%S.%N',
        factpath                         => '$vardir/lib/facter',
        logdir                           => '/var/log/puppet',
        rundir                           => '/var/run/puppet',
        ssldir                           => '$vardir/ssl',
        manage_internal_file_permissions => false,
    }

    $master = {
        autosign => false,
        reports  => 'store,log',
        ssl_client_header => 'SSL_CLIENT_S_DN',
        ssl_client_verify_header => 'SSL_CLIENT_VERIFY',
    }
}
