#
class puppet (
    $mode   = 'agent',
    $sites  = false,
    $agent  = false,
    $main   = false,
    $master = false,
)
{
    # We must declare ourselves as either an agent or master
    if ( $mode != 'agent' and $mode != 'master' ) {
        fail("invalid mode '${mode}', must be 'agent' or 'master'")
    }

    # Select the client packages
    $client_packages = $::operatingsystem ? {
        'centos' => 'puppet',
        'debian' => [ 'puppet', 'puppet-common' ],
        default  => false,
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

    # Ensure the puppet $vardir is correct
    file { $vardir:
        ensure  => 'directory',
        owner   => $puppet_user,
        group   => $puppet_group,
        mode    => '2750',
        require => Package[$client_packages],
    }

    # Puppet master specific configurations
    if ( $mode == 'master' ) {
        $puppet_dev_packages = $::operatingsystem ? {
            'centos' => 'rubygem-puppet-lint',
            'debian' => [ 'puppet-lint', 'vim-puppet' ],
            default  => false,
        }

        # Ensure the development packages are installed and up to date.
        if ( $puppet_dev_packages ) {
            package { $puppet_dev_packages: ensure => 'latest' }
        }

        # Create the top-level directory for this site
        file { "${vardir}/sites":
            ensure  => 'directory',
            owner   => $sys_group,
            group   => $puppet_group,
            mode    => '2660',
            require => File[$vardir],
        }

        # Create the site's directory structures
        create_resources( puppet::master::site, $sites )
    }
}

