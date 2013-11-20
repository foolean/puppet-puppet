# == Class: puppet
#
#   The puppet class handles the maintenance of both puppet agents
#   and the master.
#
# === Parameters
#
# [*agent*]
#   Agent configuration block
#
# [*agent_opts*]
#   Options to pass along to the puppet agent when starting at boot
#   The default is an empty string.
#
# [*agent_start*]
#   Specifies whether to start the puppet agent at boot
#   The default is 'false'
#
# [*main*]
#   Main configuration block
#
# [*master*]
#   Master configuration block
#
# [*master_opts*]
#   Options to pass along to the puppetmaster when starting
#   The default is an empty string.
#
# [*mode*]
#   The mode of operation the module is to run as.  Possible values
#   are 'agent' and 'master'.   The default is 'agent'
#
# [*sites*]
#   Hash-of-hashes that denotes the sites the puppetmaster will
#   provide service for.
#
# [*user*]
#   User configuration block
#
# === Variables
#
# [*confdir*]
#   The main Puppet configuration directory. The default for this setting is
#   calculated based on the user. If the process is running as root or the
#   user that Puppet is supposed to run as, it defaults to a system directory,
#   but if it's running as any other user, it defaults to being in the user's
#   home directory.
#
# [*client_packages*]
#   Array of packages that 'agents' need.
#
# [*dev_packages*]
#   Puppet developer packages to be installed.
#
# [*puppet_group*]
#   The puppet user's group name.
#
# [*puppet_user*]
#   The user that puppet will operate as, typcially 'puppet'.
#
# [*sys_group*]
#   The sytem user's group name, typically root but can be different
#   depending on the OS.
#
# [*sys_user*]
#   The sytem username, typically root but can be different
#   depending on the OS.
#
# [*vardir*]
#   Where Puppet stores dynamic and growing data. 
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
class puppet (
    $mode        = 'agent',
    $agent_start = false,
    $agent_opts  = '',
    $master_opts = '',
    $sites       = false,
    $agent       = false,
    $main        = false,
    $master      = false,
    $passenger   = false,
)
{
    # We must declare ourselves as either an agent or master
    if ( $mode != 'agent' and $mode != 'master' ) {
        fail("invalid mode '${mode}', must be 'agent' or 'master'")
    }

    # Select the client packages
    $client_packages = $::operatingsystem ? {
        'centos'   => 'puppet',
        'debian'   => [ 'puppet', 'puppet-common' ],
        'fedora'   => 'puppet',
        'opensuse' => 'puppet',
        'redhat'   => 'puppet',
        'ubuntu'   => [ 'puppet', 'puppet-common' ],
        default    => false,
    }

    # Fail if we aren't configured for this operating system
    if ( ! $client_packages ) {
        fail( "Unknown OS '${::operatingsystem}', unable to select packages" )
    }

    # sys_user
    $sys_user = $::operatingsystem ? {
        default => 'root',
    }

    # sys_group
    $sys_group = $::operatingsystem ? {
        default => 'root',
    }

    # puppet_user
    $puppet_user = $::operatingsystem ? {
        default => 'puppet',
    }

    # puppet_group
    $puppet_group = $::operatingsystem ? {
        default => 'puppet',
    }

    # confdir
    $confdir = $::operatingsystem ? {
       default  => '/etc/puppet',
    }

    # vardir
    $vardir = $::operatingsystem ? {
        default  => '/var/lib/puppet',
    }

    # Make sure the client packages are installed
    package { $client_packages:
        ensure => 'installed',
    }

    # Only the puppet master may override the defaults
    include puppet::master::defaults
    if ( $mode == 'master' ) {
        if ( $main ) {
            $use_main = $main
        } else {
            $use_main = $puppet::master::defaults::main
        }
        if ( $agent ) {
            $use_agent = $agent
        } else {
            $use_agent = $puppet::master::defaults::agent
        }
        if ( $master ) {
            $use_master = $master
        } else {
            $use_master = $puppet::master::defaults::master
        }
        $use_sites = $sites
    } else {
        $use_main   = $puppet::master::defaults::main
        $use_agent  = $puppet::master::defaults::agent
        $use_master = false
        $use_sites  = false
    }

    # Create the configuration files
    class { 'puppet::config':
        agent  => $use_agent,
        main   => $use_main,
        master => $use_master,
        sites  => $use_sites,
    }

    # Ensure that puppet $vardir is correct
    file { $vardir:
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0750',
        require => Package[$client_packages],
    }

    # Ensure that $vardir/clientbucket is correct
    file { "${vardir}/clientbucket":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $vardir/client_data is correct
    file { "${vardir}/client_data":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $vardir/client_yaml is correct
    file { "${vardir}/client_yaml":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $vardir/facts is correct
    file { "${vardir}/facts":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $vardir/lib is correct
    # NOTE:
    #   regardles of the value of manage_internal_file_permissions
    #   puppet will change this to $sys_user.$sys_group anyway
    #   so we might as well acquiesce even though being owned
    #   by puppet would seem to be better.
    file { "${vardir}/lib":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $sys_group,
        mode    => '0660',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $vardir/ssl is correct
    file { "${vardir}/ssl":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $vardir/state is correct
    file { "${vardir}/state":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $sys_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # OS Specific configuration files
    case $::operatingsystem {
        'debian': {
            # Copy in the /etc/default/puppet file
            file { '/etc/default/puppet':
                owner   => $puppet::sys_user,
                group   => $puppet::sys_group,
                mode    => '0640',
                content => template( "${module_name}/etc/default/puppet" ),
            }
        }
    }

    # Make sure the agent is started if we've askef for it to be
    if ( $agent_start ) {
        service { 'puppet':
            ensure    => 'running',
            enable    => true,
            subscribe => File["${confdir}/puppet.conf"],
        }
    } else {
        service { 'puppet':
            ensure => 'stopped',
            enable => false,
        }
    }

    # Puppet master specific configurations
    if ( $mode == 'master' ) {
        if ( $passenger ) {
            $master_start = false
        } else {
            $master_start = true
        }

        $dev_packages = $::operatingsystem ? {
            'centos'   => [ 'rubygem-puppet-lint', 'vim-puppet' ],
            'debian'   => [ 'puppet-lint', 'vim-puppet' ],
            'fedora'   => [ 'rubygem-puppet-lint', 'vim-puppet' ],
            'opensuse' => false,
            'redhat'   => [ 'rubygem-puppet-lint', 'vim-puppet' ],
            'ubuntu'   => [ 'puppet-lint', 'vim-puppet' ],
            default    => false,
        }

        # Ensure the development packages are installed and up to date.
        if ( $dev_packages ) {
            package { $dev_packages: ensure => 'latest' }
        }

        # Ensure that $vardir/bucket is correct
        file { "${vardir}/bucket":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0640',
            force   => true,
            recurse => true,
            require => File[$vardir],
        }

        # puppet-module
        file { "${vardir}/puppet-module":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0640',
            force   => true,
            recurse => true,
            require => File[$vardir],
        }

        # Create the top-level directory for this site
        file { "${vardir}/sites":
            ensure  => 'directory',
            owner   => $sys_user,
            group   => $puppet_group,
            mode    => '0660',
            require => File[$vardir],
        }

        # OS Specific configuration files
        case $::operatingsystem {
            'debian': {
                # Copy in the /etc/default/puppetmaster file
                file { '/etc/default/puppetmaster':
                    owner   => $puppet::sys_user,
                    group   => $puppet::sys_group,
                    mode    => '0640',
                    content => template( "${module_name}/etc/default/puppetmaster" ),
                }
            }
        }

        # Create the site's directory structures
        create_resources( puppet::master::site, $sites )

        # Make sure the service is running if it's supposed to be
        if ( $master_start ) {
            service { 'puppetmaster':
                ensure    => 'running',
                enable    => true,
                subscribe => [
                    File["${confdir}/auth.conf"],
                    File["${confdir}/fileserver.conf"],
                    File["${confdir}/puppet.conf"],
                ],
            }
        } else {
            service { 'puppetmaster':
                ensure => 'stopped',
                enable => false,
            }
        }
    }
}

