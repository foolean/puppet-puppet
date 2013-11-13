# == Class: puppet::config
#
#   The puppet::config class handles the maintenance of the puppet.conf
#   file
#
# === Parameters
#
# [*agent*]
#   Agent configuration block
#
# [*master*]
#   Master configuration block
#
# [*main*]
#   Main configuration block
#
# [*user*]
#   User configuration block
#
# [*sites*]
#   Hash-of-hashes that denotes the sites the puppetmaster will
#   provide service for.
#
# === Variables
#
# [*confdir*]
#   The configuration directory, typically /etc/puppet, that will be used.
#   The actual value is determined by first looking for the confdir value
#   in the 'master' parameter block then in the 'main' parameter block.  If
#   neither block contains the confdir value then /etc/puppet is used as
#   a last resort.
#
# === Supported Operating Systems
#
#   * CentOS
#   * Debian
#   * Fedora
#   * RedHat
#   * Ubuntu
#
# === Notes
#
#   * The CentOS operating system assumes the use of RepoForge 
#     to obtain the puppet package as the EPEL repo is too out
#     of date.
#
#     See: http://repoforge.org/use/
#
# === Authors
#
#   Bennett Samowich <bennett@foolean.org>
#
# === Copyright
#
# Copyright (c) 2013 Foolean.org
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class puppet::config (
    $agent = {
        'server'      => $::servername,
        'show_diff'   => true,
        'summarize'   => true,
        'pluginsync'  => true,
        'runinterval' => '315360000',
    },
    $main = {
        'vardir'   => $puppet::vardir,
        'confdir'  => '/etc/puppet',
	'factpath' => '$vardir/lib/facter',
        'logdir'   => '/var/log/puppet',
        'rundir'   => '/var/run/puppet',
        'ssldir'   => '$vardir/ssl',
    },
    $master = false,
    $user   = false,
    $sites  = false,
)
{

    # Master's confdir will take precedence over main's
    if ( $master and $master['confdir'] ) {
        $confdir = $main['confdir']
    } else {
        if ( $main['confdir'] ) {
            $confdir = $main['confdir']
        } else {
            $confdir = $puppet::confdir
        }
    }

    # Ensure the puppet $confdir is correct
    file { $confdir:
        ensure  => 'directory',
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0750',
        require => Package[$puppet::client_packages],
    }

    # Copy in the puppet.conf file
    file { "${confdir}/puppet.conf":
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0640',
        content => template( "${module_name}/etc/puppet/puppet.conf" ),
        require => [
            File[$confdir],
        ],
    }

    # Copy in the fileserver.conf file
    file { "${confdir}/fileserver.conf":
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0640',
        content => template( "${module_name}/etc/puppet/fileserver.conf" ),
        require => [
            File[$confdir],
        ],
    }

    # Copy in the auth.conf file
    file { "${confdir}/auth.conf":
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0640',
        content => template( "${module_name}/etc/puppet/auth.conf" ),
        require => [
            File[$confdir],
        ],
    }
}
