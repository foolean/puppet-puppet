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
# [*listen*]
#   The IP address that passenger (Apache) should listen to.  This option
#   is only valid when mode is set to 'passenger'.  The default is '127.0.0.1'.
#
# [*log_level*]
#   The logging level for passenger (Apache).  This option is only valid
#   when mode is set to 'passenger'.  The default is 'warn'.
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
#   are 'agent', 'master', or 'passenger'.   Puppetmasters will use
#   webbrick when mode is 'master' or passenger when mode is set to
#   'passenger'.  The default is 'agent'
#
# [*remote_ca*]
#   An array of URLs for remote CA workers.  This is used when configuring a
#   front-end balancer to backend CA workers.  Only the first two elements of
#   the array are used.
#
# [*remote_workers*]
#   An array of URLs for remote workers.  This is used when configuring a
#   front-end balancer to multiple backend workers.
#
# [*sites*]
#   Hash-of-hashes that denotes the sites the puppetmaster will
#   provide service for.
#
# [*user*]
#   User configuration block
#
# [*workers*]
#   The number of passenger workers to create.  This option only takes effect
#   when mode is set to 'passenger'.  Default is 1
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
    $mode           = 'agent',
    $agent_start    = false,
    $agent_opts     = '',
    $master_opts    = '',
    $sites          = false,
    $agent          = false,
    $main           = false,
    $master         = false,
    $workers        = 0,
    $listen         = '127.0.0.1',
    $remote_ca      = false,
    $remote_workers = false,
    $log_level      = 'warn',
)
{
    # We must declare ourselves as either an agent or master
    if ( $mode != 'agent' and $mode != 'master' and $mode != 'passenger' ) {
        fail("invalid mode '${mode}', must be 'agent', 'master', or 'passenger'")
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

    # apache2 group
    $apache2_group = $::operatingsystem ? {
        default => 'www-data'
    }

    # Path to apache2's sites-available directory
    $sites_available = $::operatingsystem ? {
        default => '/etc/apache2/sites-available'
    }

    # Make sure the client packages are installed
    package { $client_packages:
        ensure => 'installed',
    }

    # Only the puppet master may override the defaults
    include puppet::master::defaults
    if ( $mode == 'master' or $mode == 'passenger' ) {
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

    # Ensure that $settings::clientbucketdir is correct
    file { "${settings::clientbucketdir}":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $settings::client_datadir is correct
    file { "${settings::client_datadir}":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $settings::clientyamldir is correct
    file { "${settings::clientyamldir}":
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

    # Ensure that $settings::libdir is correct
    # NOTE:
    #   regardles of the value of manage_internal_file_permissions
    #   puppet will change this to $sys_user.$sys_group anyway
    #   so we might as well acquiesce even though being owned
    #   by puppet would seem to be better.
    file { "${settings::libdir}":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $sys_group,
        mode    => '0660',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $settings::ssldir is correct
    file { "${settings::ssldir}":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '0640',
        force   => true,
        recurse => true,
        require => File[$vardir],
    }

    # Ensure that $settings::statedir is correct
    file { "${settings::statedir}":
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
    if ( $mode == 'master' or $mode == 'passenger' ) {
        # Make sure we understand this operating system
        case $::operatingsystem {
            'centos','fedora','opensuse','redhat': {
                $puppetmaster_packages = [ 'puppet-server' ]
            }
            'debian','ubuntu': {
                $puppetmaster_packages = [ 'puppetmaster', 'puppetmaster-common' ]
            }
            default: {
                fail("${title} puppetmaster not configured for ${::operatingsystem}, exiting")
            }
        }

        # Install the puppetmaster packages
        package { $puppetmaster_packages:
            ensure => 'installed',
        }

        # If we're running passenger then we have more to do
        if ( $mode == 'passenger' ) {
            # We're going to disable puppetmaster since we're running passenger
            $master_start = false

            # Packages required for running passenger
            case $::operatingsystem {
                'debian','ubuntu': {
                    $passenger_packages = [ 'puppetmaster-passenger' ]
                }
                default: {
                    fail("${title} passenger not configured for ${::operatingsystem}, exiting")
                }
            }

            # Make sure the passenger packages are installed
            package { $passenger_packages:
                ensure => 'installed'
            }

            # If we've specified remote workers then we
            # don't need tocreate any local workers.
            if ( $remote_workers != false ) {
                $num_workers = 0
            } else {
                $num_workers = $workers
            }

            # Create the main balancer configuration
            file { "${sites_available}/30_puppetmaster_balancer_8140":
                owner   => $sys_user,
                group   => $sys_group,
                mode    => '0440',
                content => template( "${module_name}/${sites_available}/30_puppetmaster_balancer.conf" ),
                require => Package[$passenger_packages],
                notify  => Exec['puppet-passenger-apache2ctl-graceful'],
            }

            # Enable the balancer
            puppet::master::passenger::a2ensite { "30_puppetmaster_balancer_8140":
                require => File["${puppet::sites_available}/30_puppetmaster_balancer_8140"],
            }

            # Create the CA workers
            puppet::master::passenger::worker { 'ca-worker':
                workers       => 2,
                starting_port => 18138,
                listen        => $listen,
                log_level     => $log_level,
                require       => Package[$passenger_packages],
                notify        => Exec['puppet-passenger-apache2ctl-graceful'],
            }

            # Create the actual workers
            puppet::master::passenger::worker { 'worker':
                workers   => $num_workers,
                listen    => $listen,
                log_level => $log_level,
                require   => Package[$passenger_packages],
                notify    => Exec['puppet-passenger-apache2ctl-graceful'],
            }

            # Debian creates a default site named 'puppetmaster' that don't use
            puppet::master::passenger::a2dissite { 'puppetmaster': }

            # Make sure the required Apache modules are loaded
            puppet::master::passenger::a2enmod { 'ssl': }
            puppet::master::passenger::a2enmod { 'proxy': }
            puppet::master::passenger::a2enmod { 'proxy_balancer': }
            puppet::master::passenger::a2enmod { 'proxy_http': }
        } else {
            $master_start = true
        }

        # Packages useful for puppet development (e.g. writing manifests and such)
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

        # Ensure that $settings::bucketdir is correct
        file { "${settings::bucketdir}":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0640',
            force   => true,
            recurse => true,
            require => File[$vardir],
        }

        # Ensure that $settings::module_working_dir is correct
        file { "${settings::module_working_dir}":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0640',
            force   => true,
            recurse => true,
            require => File[$vardir],
        }

        # Ensure that $settings::reportdir is correct
        file { "${settings::reportdir}":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0640',
            force   => true,
            recurse => true,
            require => File[$vardir],
        }

        # Ensure that $settings::rrddir is correct
        file { "${settings::rrddir}":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0640',
            force   => true,
            recurse => true,
            require => File[$vardir],
        }

        # Ensure that $settings::server_datadir is correct
        file { "${settings::server_datadir}":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0640',
            force   => true,
            recurse => true,
            require => File[$vardir],
        }

        # Ensure that $settings::yamldir is correct
        file { "${settings::yamldir}":
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
                $puppetmaster_defaults = '/etc/default/puppetmaster'
            }
            default: {
                $puppetmaster_defaults = false
            }
        }

        # Copy in the /etc/default/puppetmaster file
        if ( $puppetmaster_defaults ) {
            file { '/etc/default/puppetmaster':
                owner   => $puppet::sys_user,
                group   => $puppet::sys_group,
                mode    => '0640',
                content => template( "${module_name}${puppetmaster_defaults}" ),
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
                    File[$puppetmaster_defaults],
                ],
            }
        } else {
            service { 'puppetmaster':
                ensure => 'stopped',
                enable => false,
            }

            # Exec to reload Apache if the puppet configuration changes
            exec { 'puppet-passenger-apache2ctl-graceful':
                path      => [ '/usr/sbin' ],
                command   => 'apache2ctl graceful',
                refreshonly => true,
                subscribe => [
                    File["${confdir}/auth.conf"],
                    File["${confdir}/fileserver.conf"],
                    File["${confdir}/puppet.conf"],
                ],
            }
        }
    }
}

