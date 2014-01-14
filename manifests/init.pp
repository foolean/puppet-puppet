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
# [*clients*]
#   An array of IP addresses that the default site will provide puppet
#   service to.  The default is an empty array.
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
# [*modules*]
#   An array of modules that should be installed.  The modules must exist
#   in the PuppetLab's Module Forge.  The default is an empty array.
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
# [*site_privacy_warning*]
#   Toggle the display of the warning that detailes the lack of privacy
#   between sites.  The default is true
#
# [*sites*]
#   Hash-of-hashes that denotes the sites the puppetmaster will
#   provide service for.
#
# [*sslverifyclient*]
#   Sets the SSLVerifyClient option in the Apache2 configuration.  The
#   possible values are 'require' and 'optional'.  Setting the value to
#   'optional' will mimic standalone puppetmaster behavior.
#   The default is 'require'
#
# [*tidy*]
#   Toggle the tidying of the clientbucket directory for agents and the
#   buckket and reports directories for masters.  The default is true
#
# [*tidy_age*]
#   The age to tidy the bucket, clientbucket, and reports directories to.
#   The default is '52w'
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
# === Examples
#
#   node myagent {
#       class { 'puppet':
#           mode => 'agent',
#       }
#   }
#
#   # accomplishes the same thing done for 'myagent' above
#   node myotheragent {
#       class { 'puppet': }
#   }
#
#   node smallagent {
#       class { 'puppet':
#           tidy_age => '4w',
#       }
#   }
#
#   node mymaster {
#       class { 'puppet':
#           mode    => 'master',
#           clients => [ 'host1', 'host2', etc ],
#           modules => [
#               'foolean-ssh'
#           ],
#       }
#   }
#
#   # A puppetmaster running passenger
#   node myothermaster {
#       class { 'puppet':
#           mode    => 'passenger',
#           workers => 5,
#           clients => [ 'host1', 'host2', etc ],
#           modules => [
#               'foolean-ssh'
#           ],
#       }
#   }
#
#   # A puppetmaster running passenger and multiple sites
#   node mysitemaster {
#       class { 'puppet':
#           mode    => 'passenger',
#           workers => 5,
#           clients => [ 'host1', 'host2', etc ],
#           modules => [
#               'foolean-ssh'
#           ],
#           sites   => {
#               'site1' => {
#                   'clients' => [ 'host1', 'host2', etc ],
#               },
#               'site2' => {
#                   'clients' => [ 'host1', 'host2', etc ],
#               },
#           },
#       }
#   }
#
# === CAVEAT EMPTOR!
# 
#   ******************************************************
#   *** DO NOT USE MORE THAN ONE SITE PER PUPPETMASTER ***
#   *** IF YOU NEED TO MAINTAIN PRIVACY BETWEEN SITES! ***
#   ******************************************************
#
#   Puppet allows for the execution of arbitrary ruby code on the puppetmaster.
#   This can be accomplished in manifest files by using the inline_template
#   function or in template files themselves.  The arbitrary code will execute
#   in the context of the puppet daemon, typically uid:puppet, gid:puppet. While
#   it limits the scope of readable and writable files over the entire file
#   system it does also mean that any file puppet can read so can anyone with
#   the rights to upload manifests and templates.  Because of this "feature"
#   there is no way to ensure privacy between sites.
#
#   See the README file for examples
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
    $tidy                 = true,
    $tidy_age             = '52w',
    $mode                 = 'agent',
    $agent_start          = false,
    $agent_opts           = '',
    $master_opts          = '',
    $sites                = false,
    $agent                = false,
    $main                 = false,
    $master               = false,
    $workers              = 1,
    $listen               = '127.0.0.1',
    $remote_ca            = false,
    $remote_workers       = false,
    $log_level            = 'warn',
    $modules              = [],
    $clients              = [],
    $developers           = [],
    $site_privacy_warning = true,
    $recurse              = false,
    $sslverifyclient      = 'require',
)
{
    # We must have puppet version 2.7 or higher
    if ( versioncmp( $::puppetversion, '2.7' ) < 0 ) {
        fail( 'This module requires puppet version 2.7 or greater' )
    }

    # We must declare ourselves as either an agent or master
    if ( $mode != 'agent' and $mode != 'master' and $mode != 'passenger' ) {
        fail("invalid mode '${mode}', must be 'agent', 'master', or 'passenger'")
    }

    # sslverifyclient must be either 'require' or 'optional'
    if ( $sslverifyclient != 'require' and $sslverifyclient != 'optional' ) {
        fail("invalid sslverifyclient '${sslverifyclient}', must be 'require' or 'optional'")
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

    # Path to the puppet defaults files
    $puppet_defaults = $::operatingsystem ? {
        'debian' => '/etc/default/puppet',
        'ubuntu' => '/etc/default/puppet',
        default  => false
    }

    # Path to the puppetmaster defaults files
    $puppetmaster_defaults = $::operatingsystem ? {
        'debian' => '/etc/default/puppetmaster',
        'ubuntu' => '/etc/default/puppetmaster',
        default  => false
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

    # Copy in the rundir script
    file { "${confdir}/rundir":
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0750',
        content => template( "${module_name}/etc/puppet/rundir" ),
        require => [
            File[$confdir],
        ],
    }

    # Create the pre-run.d directory
    file { "${confdir}/pre-run.d":
        ensure  => 'directory',
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0750',
        require => [
            File[$confdir],
        ],
    }

    # Create the post-run.d directory
    file { "${confdir}/post-run.d":
        ensure  => 'directory',
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0750',
        require => [
            File[$confdir],
        ],
    }

    # Copy in the 90_permissions script
    file { "${confdir}/post-run.d/90_permissions":
        owner   => $puppet::sys_user,
        group   => $puppet::puppet_group,
        mode    => '0750',
        content => template( "${module_name}/etc/puppet/post-run.d/90_permissions" ),
        require => [
            File[$confdir],
            File["${confdir}/post-run.d"],
        ],
    }

    # Ensure that puppet $vardir is correct
    file { $vardir:
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $puppet_group,
        mode    => '2750',
        require => Package[$client_packages],
    }

    # Ensure that $settings::clientbucketdir is correct
    file { "${settings::clientbucketdir}":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $puppet_group,
        mode    => '2750',
        require => File[$vardir],
    }

    # Keep $settings::clientbucketdir pruned to $age
    if ( $tidy ) {
        tidy { $settings::clientbucketdir:
            age     => $tidy_age,
            backup  => false,
            recurse => true,
            rmdirs  => true,
            type    => 'ctime',
            require => File[$settings::clientbucketdir],
        }
    }

    # Ensure that $settings::client_datadir is correct
    file { "${settings::client_datadir}":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $puppet_group,
        mode    => '2750',
        require => File[$vardir],
    }

    # Ensure that $settings::clientyamldir is correct
    file { "${settings::clientyamldir}":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $puppet_group,
        mode    => '2750',
        require => File[$vardir],
    }

    # Ensure that $vardir/facts is correct
    file { "${vardir}/facts":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $puppet_group,
        mode    => '2750',
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
        mode    => '0770',
        require => File[$vardir],
    }

    # Ensure that $settings::ssldir is correct
    file { "${settings::ssldir}":
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '2700',
        require => File[$vardir],
    }

    # Ensure that $settings::statedir is correct
    file { "${settings::statedir}":
        ensure  => 'directory',
        owner   => $sys_user,
        group   => $puppet_group,
        mode    => '2750',
        require => File[$vardir],
    }

    # OS Specific configuration files
    if ( $puppet_defaults ) {
        # Copy in the /etc/default/puppet file
        file { $puppet_defaults:
            owner   => $puppet::sys_user,
            group   => $puppet::sys_group,
            mode    => '0640',
            content => template( "${module_name}${puppet_defaults}" ),
        }
    }

    # Make sure the agent is started if we've askef for it to be
    if ( $agent_start ) {
        service { 'puppet':
            ensure    => 'running',
            enable    => true,
            subscribe => File["${confdir}/puppet.conf"],
            require   => [
                Package[$client_packages],
                File[$vardir],
                File["${vardir}/facts"],
                File[$settings::clientbucketdir],
                File[$settings::client_datadir],
                File[$settings::clientyamldir],
                File[$settings::libdir],
                File[$settings::ssldir],
                File[$settings::statedir],
            ],
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
            file { "${sites_available}/30_puppetmaster_balancer_8140.conf":
                owner   => $sys_user,
                group   => $sys_group,
                mode    => '0440',
                content => template( "${module_name}/${sites_available}/30_puppetmaster_balancer.conf" ),
                require => Package[$passenger_packages],
                notify  => Exec['puppet-passenger-apache2ctl-graceful'],
            }

            # Enable the balancer
            puppet::master::passenger::a2ensite { "30_puppetmaster_balancer_8140.conf":
                require => File["${puppet::sites_available}/30_puppetmaster_balancer_8140.conf"],
                notify  => Exec['puppet-passenger-apache2ctl-graceful'],
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
            puppet::master::passenger::a2dissite { 'puppetmaster':
                require => Package[$passenger_packages],
                before  => Exec['puppet-passenger-apache2ctl-graceful'],
            }

            # Make sure the required Apache modules are loaded
            puppet::master::passenger::a2enmod { 'ssl':
                require => Package[$passenger_packages],
                before  => Exec['puppet-passenger-apache2ctl-graceful'],
            }
            puppet::master::passenger::a2enmod { 'proxy':
                require => Package[$passenger_packages],
                before  => Exec['puppet-passenger-apache2ctl-graceful'],
            }
            puppet::master::passenger::a2enmod { 'proxy_balancer':
                require => Package[$passenger_packages],
                before  => Exec['puppet-passenger-apache2ctl-graceful'],
            }
            puppet::master::passenger::a2enmod { 'proxy_http':
                require => Package[$passenger_packages],
                before  => Exec['puppet-passenger-apache2ctl-graceful'],
            }
            # This is really for Apache2 v2.4 or greater
            # but I'm trying to keep this class autonomous.
            if ( $::operatingsystem == 'ubuntu' ) {
                puppet::master::passenger::a2enmod { 'lbmethod_byrequests':
                    require => Package[$passenger_packages],
                    before  => Exec['puppet-passenger-apache2ctl-graceful'],
                }
            }
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
            owner   => $sys_user,
            group   => $puppet_group,
            mode    => '2750',
            require => [
                Package[$puppetmaster_packages],
                File[$vardir],
            ],
        }

        # Keep $settings::bucketdir pruned to $age
        if ( $tidy ) {
            tidy { $settings::bucketdir:
                age     => $tidy_age,
                backup  => false,
                recurse => true,
                rmdirs  => true,
                type    => 'ctime',
                require => File[$settings::bucketdir],
            }
        }

        # Ensure that $settings::module_working_dir is correct
        file { "${settings::module_working_dir}":
            ensure  => 'directory',
            owner   => $sys_user,
            group   => $puppet_group,
            mode    => '2750',
            require => [
                Package[$puppetmaster_packages],
                File[$vardir],
            ],
        }

        # Ensure that $settings::reportdir is correct
        file { "${settings::reportdir}":
            ensure  => 'directory',
            owner   => $sys_user,
            group   => $puppet_group,
            mode    => '2750',
            require => [
                Package[$puppetmaster_packages],
                File[$vardir],
            ],
        }

        # Keep $settings::reportdir pruned to $age
        if ( $tidy ) {
            tidy { $settings::reportdir:
                age     => $tidy_age,
                backup  => false,
                recurse => true,
                rmdirs  => true,
                type    => 'ctime',
                require => File[$settings::reportdir],
            }
        }

        # Ensure that $settings::rrddir is correct
        file { "${settings::rrddir}":
            ensure  => 'directory',
            owner   => $sys_user,
            group   => $puppet_group,
            mode    => '2750',
            require => [
                Package[$puppetmaster_packages],
                File[$vardir],
            ],
        }

        # Ensure that $settings::server_datadir is correct
        file { "${settings::server_datadir}":
            ensure  => 'directory',
            owner   => $sys_user,
            group   => $puppet_group,
            mode    => '2750',
            require => [
                Package[$puppetmaster_packages],
                File[$vardir],
            ],
        }

        # Ensure that $settings::yamldir is correct
        file { "${settings::yamldir}":
            ensure  => 'directory',
            owner   => $puppet_user,
            group   => $puppet_group,
            mode    => '0770',
            require => [
                Package[$puppetmaster_packages],
                File[$vardir],
            ],
        }

        # Create the top-level directory for this site
        file { "${vardir}/sites":
            ensure  => 'directory',
            owner   => $sys_user,
            group   => $puppet_group,
            mode    => '0660',
            require => File[$vardir],
        }

        # Copy in the CA certificate if we have one
        $cacert = file(
            "${settings::vardir}/sites/default/${environment}/private/${::fqdn}/${settings::cacert}",
            $settings::cacert,
            '/dev/null'
        )
        if ( $cacert ) {
            file { $settings::cacert:
                mode    => '0600',
                owner   => $puppet_user,
                group   => $puppet_group,
                content => $cacert,
                require => [
                    Package[$puppetmaster_packages],
                    File[$settings::ssldir],
                ],
            }
        }

        # Copy in the CA key if we have one
        $cakey = file(
            "${settings::vardir}/sites/default/${environment}/private/${::fqdn}/${settings::cakey}",
            $settings::cakey,
            '/dev/null'
        )
        if ( $cakey ) {
            file { $settings::cakey:
                mode    => '0600',
                owner   => $puppet_user,
                group   => $puppet_group,
                content => $cakey,
                require => [
                    Package[$puppetmaster_packages],
                    File[$settings::ssldir],
                ],
            }
        }

        # Copy in the CA pass if we have one
        $capass = file(
            "${settings::vardir}/sites/default/${environment}/private/${::fqdn}/${settings::capass}",
            $settings::capass,
            '/dev/null'
        )
        if ( $capass ) {
            file { $settings::capass:
                mode    => '0600',
                owner   => $puppet_user,
                group   => $puppet_group,
                content => $capass,
                require => [
                    Package[$puppetmaster_packages],
                    File[$settings::ssldir],
                ],
            }
        }

        # Copy in the puppetmaster defaults file
        if ( $puppetmaster_defaults ) {
            file { $puppetmaster_defaults:
                owner   => $puppet::sys_user,
                group   => $puppet::sys_group,
                mode    => '0640',
                content => template( "${module_name}${puppetmaster_defaults}" ),
            }
        }

        # Create the site's directory structures
        if ( $use_sites ) {
            if ( $use_sites['default'] ) {
                fail( "ERROR: 'default' can not be defined in the 'sites' parameter" )
            } else {
                if ( $site_privacy_warning ) {
                    notify { 'sites-warning':
                        message => "\nWARNING:\nWARNING: Puppet's ability to run arbitrary ruby code means there is no way to\nWARNING: ensure privacy between sites.  The 'sites' feature may be removed in\nWARNING: the future.  See the 'CAVEAT' in the README file for more details.\nWARNING: This message can be suppressed by setting 'site_privacy_warning' to\nWARNING: false in the class declaration\nWARNING:\n",
                        loglevel => 'warning',
                    }
                }
            }
            create_resources( puppet::master::site, $use_sites )
        }
        puppet::master::site { 'default':
            clients    => $clients,
            developers => $developers,
        }

        # Make sure the service is running if it's supposed to be
        if ( $master_start ) {
            service { 'puppetmaster':
                ensure    => 'running',
                enable    => true,
                subscribe => [
                    Package[$puppetmaster_packages],
                    File["${confdir}/auth.conf"],
                    File["${confdir}/fileserver.conf"],
                    File["${confdir}/puppet.conf"],
                    File[$puppetmaster_defaults],
                ],
            }
        } else {
            service { 'puppetmaster':
                ensure  => 'stopped',
                enable  => false,
                require => [
                    Package[$puppetmaster_packages],
                    File[$settings::bucketdir],
                    File[$settings::cacert],
                    File[$settings::cakey],
                    File[$settings::capass],
                    File[$settings::clientbucketdir],
                    File[$settings::client_datadir],
                    File[$settings::clientyamldir],
                    File[$settings::libdir],
                    File[$settings::module_working_dir],
                    File[$settings::reportdir],
                    File[$settings::rrddir],
                    File[$settings::server_datadir],
                    File[$settings::ssldir],
                    File[$settings::statedir],
                    File[$settings::yamldir],
                    File[$vardir],
                    File["${vardir}/facts"],
                    File["${vardir}/sites"],
                ],
            }

            # Exec to reload Apache if the puppet configuration changes
            exec { 'puppet-passenger-apache2ctl-graceful':
                path        => [ '/bin', '/usr/bin', '/sbin', '/usr/sbin' ],
                command     => 'apache2ctl graceful',
                refreshonly => true,
                require     => [
                   Service['puppetmaster'],
                ],
                subscribe   => [
                    File["${confdir}/auth.conf"],
                    File["${confdir}/fileserver.conf"],
                    File["${confdir}/puppet.conf"],
                ],
            }
        }
    }

    # Install any modules that were requested.  The extensive
    # require list is just to ensure that $modulepath exists
    # prior to actually trying to install the modules.
    if ( $modules ) {
        puppet::module { $modules:
            require => [
                Package[$puppetmaster_packages],
                File[$settings::bucketdir],
                File[$settings::cacert],
                File[$settings::cakey],
                File[$settings::capass],
                File[$settings::clientbucketdir],
                File[$settings::client_datadir],
                File[$settings::clientyamldir],
                File[$settings::libdir],
                File[$settings::module_working_dir],
                File[$settings::reportdir],
                File[$settings::rrddir],
                File[$settings::server_datadir],
                File[$settings::ssldir],
                File[$settings::statedir],
                File[$settings::yamldir],
                File[$vardir],
                File["${vardir}/facts"],
                File["${vardir}/sites"],
            ],
        }
    }
}
