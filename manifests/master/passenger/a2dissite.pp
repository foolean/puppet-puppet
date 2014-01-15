# == Define: puppet::master::passenger::a2dissite
#
#   Executes Apache2's a2dissite utility to disable an Apache site
#
# === Parameters
#
#   None
#
# === Variables
#
#   None
#
# === Example
#
#   puppet::master::passenger::a2dissite { 'mysite': }
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
define puppet::master::passenger::a2dissite {

    # Apache 2.4 will append '.conf' to the site name so we must
    # test for both apachesite and apachesite.conf formats.
    exec { "puppet-passenger-a2dissite-${title}":
        path => [ '/bin', '/usr/bin', '/usr/sbin' ],
        command => "a2dissite ${title}",
        onlyif  => "test -L /etc/apache2/sites-enabled/${title}.conf || test -L /etc/apache2/sites-enabled/${title}",
        notify  => Exec['puppet-passenger-apache2ctl-graceful'],
        require => Package[$puppet::passenger_packages],
    }
}
