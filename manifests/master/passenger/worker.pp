# == Define: puppet::master::passenger::worker
#
#   This define handles the creation and configuration of
#   Puppet Passenger Workers.  This define is typically
#   called from within the main puppet class so there
#   should not be a need to call it directly
#
# === Parameters
#
# [*listen*]
#   Specifies the IP address the worker should listen on.
#   Default: 127.0.0.1
#
# [*log_level*]
#   Specifies the logging level for the worker.
#   Default: warn
#
# [*worker*]
#   The current worker number.  This parameter is used to
#   facilitate the iteration over the entire number of
#   workers and should not need to be set directly.
#
# [*workers*]
#   The number of workers to create.  The default is 1
#
# === Variables
#
# [*next_worker*]
#   The number of the next worker to create.  This variable is used
#   as part of the incrementing loop that iterates through the number
#   of requested workers.
#
# [*puppet::sites_available*]
#   The path to the Apache2 sites-available directory.  Essentially
#   this is the path to where the worker configuration files should
#   be written.
#   Default: /etc/apache2/sites-available.
#
# === Supported Operating Systems
#
#   * Debian
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
define puppet::master::passenger::worker (
    $workers       = 1,
    $starting_port = 18140,
    $listen        = '127.0.0.1',
    $log_level     = 'warn',
    $worker        = 0,
) {
    # Iterate over the number of workers that have been requested.
    if ( $worker < $workers ) {
        # Set the port number for this worker
        $port = $starting_port + $worker

        # This logic enables us to have puppet create the worker
        # configurations in incremental order by their port numbers.  
        if ( $worker > 0 ) {
            $prev = $starting_port + $worker - 1
            $worker_require = [ File["${puppet::sites_available}/40_puppetmaster_worker_${prev}.conf"] ]
        } else {
            $worker_require = [ File["${puppet::sites_available}/30_puppetmaster_balancer_8140.conf"] ]
        }

        # Copy the worker configuration for this port
        file { "${puppet::sites_available}/40_puppetmaster_worker_${port}.conf":
            owner   => $puppet::sys_user,
            group   => $puppet::sys_group,
            mode    => '0440',
            content => template( "${module_name}/${puppet::sites_available}/40_puppetmaster_worker.conf" ),
            require => $worker_require,
            notify  => Exec['puppet-passenger-apache2ctl-graceful'],
        }

        # Enable the worker
        puppet::master::passenger::a2ensite { "40_puppetmaster_worker_${port}.conf":
            require => [
                $worker_require,
                File["${puppet::sites_available}/40_puppetmaster_worker_${port}.conf"],
            ],
            notify  => Exec['puppet-passenger-apache2ctl-graceful'],
        }

        # Create the "rack" directory structure for this worker
        file { "/usr/share/puppet/rack/puppetmasterd_${port}":
            ensure => 'directory',
            owner  => $puppet::puppet_user,
            group  => $puppet::apache2_group,
            mode   => '0750',
        }

        $config_ru = $::operatingsystem ? {
            'debian' => '/usr/share/puppet/rack/puppetmasterd/config.ru',
            'ubuntu' => '/usr/share/puppet/rack/puppetmasterd/config.ru',
            default  => false,
        }

        if ( $config_ru ) {
            file { "/usr/share/puppet/rack/puppetmasterd_${port}/config.ru":
                owner   => $puppet::puppet_user,
                group   => $puppet::apache2_group,
                mode    => '0440',
                ensure  => $config_ru,
                require => File["/usr/share/puppet/rack/puppetmasterd_${port}"],
            }
        }

        file { "/usr/share/puppet/rack/puppetmasterd_${port}/public":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $puppet::apache2_group,
            mode    => '0750',
            require => File["/usr/share/puppet/rack/puppetmasterd_${port}"],
        }

        file { "/usr/share/puppet/rack/puppetmasterd_${port}/tmp":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $puppet::apache2_group,
            mode    => '0750',
            require => File["/usr/share/puppet/rack/puppetmasterd_${port}"],
        }

        # Increment the counter and call puppet::passenger::worker again
        $next_worker = $worker + 1
        puppet::master::passenger::worker { "worker_${port}":
            worker        => $next_worker,
            workers       => $workers,
            log_level     => $log_level,
            starting_port => $starting_port,
        }
    }
}
