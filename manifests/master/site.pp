# == Define: puppet::master::site
#
#   This define is used to ensure the directory structure for a site exists,
#   or is removed if ensure => 'absent' is specified.  Typically this define
#   gets called from puppet::master and should not be called directly.
#
# === Parameters
#
# [*ensure*]
#   Specifies if the site should be created/maintained or removed
#   default: present
#
# [*clients*]
#   An array of IP addresses of client systems that are permitted to use
#   the configurations contained within the named site.
#
# [*developers*]
#   An array of developer usernames.  An alpha environment will be created
#   for each developer.
#
# === Variables
#
# [*group*]
#   The POSIX group for the site directories.  This group will be used to
#   ensure that only users of that site can view/modify files within that
#   site.
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
define puppet::master::site (
    $ensure     = 'present',
    $clients    = false,
    $developers = false,
)
{

    # The default site will use the actual puppet group, all
    # others will append the site name to the actual puppet group
    if ( $title == 'default' ) {
        $group = $puppet::puppet_group
    } else {
        $group = "${puppet::puppet_group}-${title}"
    }

    # Create or remove the POSIX group for this site
    group { $group:
        ensure => $ensure
    }

    # Create or remove the site's directory structure
    if ( $ensure == 'absent' ) {
        file { "${puppet::vardir}/sites/${title}":
            ensure  => 'absent',
            recurse => true,
        }
    } else {
        # Create the top-level directory for this site
        file { "${puppet::vardir}/sites/${title}":
            ensure  => 'directory',
            owner   => $puppet::puppet_group,
            group   => $puppet::puppet_group,
            mode    => '2660',
            require => File["${puppet::vardir}/sites"],
        }

        # Create the production directory for this site
        file { "${puppet::vardir}/sites/${title}/production":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $puppet::puppet_group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
            ],
        }

        # Create the production manifests directory for this site
        file { "${puppet::vardir}/sites/${title}/production/manifests":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
                File["${puppet::vardir}/sites/${title}/production"],
            ],
        }

        # Create the production modules directory for this site
        file { "${puppet::vardir}/sites/${title}/production/modules":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
                File["${puppet::vardir}/sites/${title}/production"],
            ],
        }

        # Create the production private directory for this site
        file { "${puppet::vardir}/sites/${title}/production/private":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '0660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
                File["${puppet::vardir}/sites/${title}/production"],
            ],
        }


        # Create the development directory for this site
        file { "${puppet::vardir}/sites/${title}/development":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $puppet::puppet_group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
            ],
        }

        # Create the default development directory for this site
        file { "${puppet::vardir}/sites/${title}/development/default":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $puppet::puppet_group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}/development"],
            ],
        }

        # Create the default development manifests directory for this site
        file { "${puppet::vardir}/sites/${title}/development/default/manifests":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
                File["${puppet::vardir}/sites/${title}/development"],
                File["${puppet::vardir}/sites/${title}/development/default"],
            ],
        }

        # Create the default development modules directory for this site
        file { "${puppet::vardir}/sites/${title}/development/default/modules":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
                File["${puppet::vardir}/sites/${title}/development"],
                File["${puppet::vardir}/sites/${title}/development/default"],
            ],
        }

        # Create the default development private directory for this site
        file { "${puppet::vardir}/sites/${title}/development/default/private":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '2660',
            require => [
                File["${puppet::vardir}/sites/${title}"],
                File["${puppet::vardir}/sites/${title}/development"],
                File["${puppet::vardir}/sites/${title}/development/default"],
            ],
        }

        # Create the individual developer directories
        # Note: There doesn't seem to be a simple way to handle this in 
        #       puppet versions less than 3.2.  There is a foreach function
        #       that was introduced in 3.2 that should make this possible.
    }

}
