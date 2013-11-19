# == Class: puppet::config
#
#   The puppet::config class handles the maintenance of the puppet
#   configuration directory and files.
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
# === File and Directory Permissions
#
#   This class attempts to remove all 'world' permissions and set ownership
#   to the puppet user and puppet group as there is really no reason for any
#   other users to access the puppet files.   The premis is that only an
#   administrator (e.g. someone with root) should be running puppet on a
#   system.  Likewise only an administrator or someone in the puppet group
#   should be looking at any of the puppet files.
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
        mode    => '2750',
        require => Package[$puppet::client_packages],
    }

    # We don't need the modules, manifests, and templates directory
    # in $confdir because we're setting up our own structure under
    # $vardir/sites.  However, puppet seems create a manifests
    # directory in $confdir each time it starts so we'll just symlink
    # it to the production manifests area if we're the puppetmaster
    if ( $master ) {
        # We're the master; symlink $confdir/manifests to the production default
        file { "${confdir}/manifests":
            ensure  => "${puppet::vardir}/sites/default/production/manifests",
            require => File["${puppet::vardir}/sites/default/production/manifests"],
            force   => true,
        }
    } else {
        file { "${confdir}/manifests":
            ensure => 'absent',
            force  => true,
        }
    }
    file { "${confdir}/modules":
        ensure => 'absent',
        force  => true,
    }
    file { "${confdir}/templates":
        ensure => 'absent',
        force  => true,
    }

    # Debian ships with etckeeper-commit-pre and etckeeper-commit-post
    # script to be used with the prerun_command and postrun_command
    # configuration options.  We're removing world permissions so we'll
    # need to handle these two files directly.
    file { "${confdir}/etckeeper-commit-pre":
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0750',
        require => Package[$puppet::client_packages],
    }
    file { "${confdir}/etckeeper-commit-post":
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

    # Remove any remaining world permissions from $confdir
    exec { "remove-world-perms-from-${confdir}":
        path    => [ '/bin', '/usr/bin' ],
        command => "chmod -R o-rwx \"${confdir}\"",
        onlyif  => "test `find \"${confdir}\" \! -type l \( -perm -o=r -o -perm -o=w -o -perm -o=x \) | wc -l` -ge 1",
        require => [
            File[$confdir],
            File["${confdir}/auth.conf"],
            File["${confdir}/fileserver.conf"],
            File["${confdir}/puppet.conf"],
        ],
    }

    # Ensure user and group ownership for $confdir
    exec { "enforce-ownership-in-${confdir}":
        path    => [ '/bin', '/usr/bin' ],
        command => "chown -R ${puppet::sys_user}.${puppet::puppet_group} \"${confdir}\"",
        onlyif  => "test `find /etc/puppet \( \! -group puppet \) -o \( \! -user root \) | wc -l` -ge 1",
        require => [
            File[$confdir],
            File["${confdir}/auth.conf"],
            File["${confdir}/fileserver.conf"],
            File["${confdir}/puppet.conf"],
        ],
    }
}
