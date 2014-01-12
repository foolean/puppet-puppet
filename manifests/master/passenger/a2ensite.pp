# == Define: puppet::master::passenger::a2ensite
#
#   Executes Apache2's a2ensite utility to enable an Apache site
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
#   puppet::master::passenger::a2ensite { 'mysite': }
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
define puppet::master::passenger::a2ensite {
    exec { "puppet-passenger-a2ensite-${title}":
        path => [ '/bin', '/usr/bin', '/usr/sbin' ],
        command => "a2ensite ${title}",
        onlyif  => "test `apache2ctl -S 2>&1 | grep -c \"/${title}:\"` -eq 0",
        notify  => Exec['puppet-passenger-apache2ctl-graceful'],
        require => Package[$puppet::passenger_packages],
    }
}
