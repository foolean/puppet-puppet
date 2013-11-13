# == Class: puppet::master::bootstrap
#
#   This class is a bootstrap class for building a puppetmaster.  It primary
#   function is to create the initial directory structure and pull down the
#   actual puppet class from github.
#
# === Parameters
#
#   None
#
# === Variables
#
#   None
#
# === Examples
#
#   This class includes a generic node definition which is designed
#   to allow any host to be bootstrapped into being a puppetmaster
#   and should be called on its own.
#
#   *** DO NOT INCLUDE IT IN THE NORMAL NODE DEFINITIONS ***
#
#   To download the bootstrap.pp file directly use the following URL:
#
#       https://raw.github.com/foolean/puppet-puppet/master/manifests/master/bootstrap.pp
#
#       This is convenient for including the bootstrap.pp file in any
#       post-os-install processing.
#
#   To run this bootstrap code, use the 'puppet apply' command
#
#       # To verify what changes will be made
#       puppet apply --detailed-exitcodes --verbose --noop ./bootstrap.pp
#
#       # To apply the changes to the system
#       puppet apply --detailed-exitcodes --verbose ./bootstrap.pp
#
# === Supported Operating Systems
#
#   * CentOS
#   * Debian
#   * Fedora
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
class puppet::master::bootstrap {

    # Make sure we understand this operating system
    case $::operatingsystem {
        'centos','fedora','redhat': {
            $puppetmaster_packages = [ 'puppet-server' ]
        }
        'debian','ubuntu': {
            $puppetmaster_packages = [ 'puppetmaster', 'puppetmaster-common' ]
        }
        default: {
            fail("${title} not configured for ${::operatingsystem}, exiting")
        }
    }

    # Content for the bootstrapped puppet.conf file
    $puppet_conf = "
[main]
    logdir=/var/log/puppet
    vardir=/var/lib/puppet
    rundir=/var/run/puppet
    ssldir=\$vardir/ssl
    factpath=\$vardir/lib/facter

[agent]
    environment = production
    server      = $::fqdn
    show_diff   = true
    summarize   = true
    pluginsync  = true
    runinterval = 315360000

[master]
    autosign    = false
    modulepath  = \$vardir/sites/default/production/modules
    manifestdir = \$vardir/sites/default/production/manifests
    manifest    = \$vardir/sites/default/production/manifests/site.pp

[development]
    modulepath  = \$vardir/sites/default/development/modules
    manifestdir = \$vardir/sites/default/development/manifests
    manifest    = \$vardir/sites/default/development/manifests/site.pp
"

    # Content for the bootstrapped site.pp file
    $site_pp = "
node '$::fqdn' {
    class { 'puppet':
        mode  => 'master',
        sites => {
            'default' => {
                'clients'    => [],
                'developers' => [],
            },
        },
    }
}
"

    # Ensure that required packages are installed
    package { 'git':
        ensure => 'installed',
    }
    package { $puppetmaster_packages:
        ensure => 'installed',
    }

    # Create the top-level sites directory
    file { "${settings::vardir}/sites":
        ensure => 'directory',
        owner  => 'root',
        group  => 'puppet',
        mode   => '0750',
    }

    # Create the default site top-level directory
    file { "${settings::vardir}/sites/default":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites"],
    }

    # Create the default site's development directory
    file { "${settings::vardir}/sites/default/development":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default"],
    }

    # Create the default site's development manifests directory
    file { "${settings::vardir}/sites/default/development/manifests":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default/development"],
    }

    # Create the default site's development modules directory
    file { "${settings::vardir}/sites/default/development/modules":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default/development"],
    }

    # Create the default site's development private directory
    file { "${settings::vardir}/sites/default/development/private":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default/development"],
    }

    # Create the default site's production directory
    file { "${settings::vardir}/sites/default/production":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default"],
    }

    # Create the default site's production manfests directory
    file { "${settings::vardir}/sites/default/production/manifests":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default/production"],
    }

    # Create the default site's production modules directory
    file { "${settings::vardir}/sites/default/production/modules":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default/production"],
    }

    # Create the default site's production private directory
    file { "${settings::vardir}/sites/default/production/private":
        ensure  => 'directory',
        owner   => 'root',
        group   => 'puppet',
        mode    => '0750',
        require => File["${settings::vardir}/sites/default/production"],
    }

    # Bootstrap the puppet.conf file
    file { '/etc/puppet/puppet.conf':
        owner   => 'root',
        group   => 'puppet',
        mode    => '0640',
        content => inline_template($puppet_conf),
        require => Package[$puppetmaster_packages],
        notify  => Service['puppetmaster'],
    }

    # Bootstrap the production site.pp file
    file { "${settings::vardir}/sites/default/production/manifests/site.pp":
        owner   => 'root',
        group   => 'puppet',
        mode    => '0640',
        content => inline_template($site_pp),
        require => [
            File["${settings::vardir}/sites/default/production/manifests"],
        ],
    }

    # Bootstrap the development site.pp file
    file { "${settings::vardir}/sites/default/development/manifests/site.pp":
        owner   => 'root',
        group   => 'puppet',
        mode    => '0640',
        content => inline_template($site_pp),
        require => [
            File["${settings::vardir}/sites/default/development/manifests"],
        ],
    }

    # Clone the foolean/puppet-puppet class from github
    # into the default site's development area
    exec { 'get-development-puppet-class':
        path    => [ '/usr/bin' ],
        cwd     => "${settings::vardir}/sites/default/development/modules",
        command => 'git clone https://github.com/foolean/puppet-puppet.git puppet',
        creates => "${settings::vardir}/sites/default/development/modules/puppet",
        require => [
            File["${settings::vardir}/sites/default/development/modules"],
            Package['git'],
        ],
    }

    # Import the foolean-puppet module into
    # the default site's production area
    exec { 'get-production-puppet-module':
        path    => [ '/usr/bin', '/bin' ],
        command => "puppet module install foolean-puppet --modulepath ${settings::vardir}/sites/default/production/modules",
        creates => "${settings::vardir}/sites/default/production/modules/puppet",
        require => [
            File["${settings::vardir}/sites/default/production/modules"],
        ],
    }

    # Make sure we have a defaults.pp for the production module
    exec { 'copy-production-master-defaults':
        path    => [ '/bin' ],
        command => "cp ${settings::vardir}/sites/default/production/modules/puppet/manifests/master/defaults.pp.example ${settings::vardir}/sites/default/production/modules/puppet/manifests/master/defaults.pp",
        creates => "${settings::vardir}/sites/default/production/modules/puppet/manifests/master/defaults.pp",
        require => Exec['get-production-puppet-module'],
    }

    # Make sure we have a defaults.pp for the development module
    exec { 'copy-development-master-defaults':
        path    => [ '/bin' ],
        command => "cp ${settings::vardir}/sites/default/development/modules/puppet/manifests/master/defaults.pp.example ${settings::vardir}/sites/default/development/modules/puppet/manifests/master/defaults.pp",
        creates => "${settings::vardir}/sites/default/development/modules/puppet/manifests/master/defaults.pp",
        require => Exec['get-development-puppet-class'],
    }

    # Make sure we restart the service after updating the configuration files
    service { 'puppetmaster':
        ensure     => 'running',
        hasrestart => true,
        hasstatus  => true,
        require    => [
            Package[$puppetmaster_packages],
            File['/etc/puppet/puppet.conf'],
        ],
    }
}

# This simple node definition will allow
# the puppet::master::bootstrap class to
# be invoked on any host.
node default {
	class { 'puppet::master::bootstrap': }
}
