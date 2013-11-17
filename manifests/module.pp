# == Define: puppet::module
#
#   This define handles the installation and uninstallation of puppet modules
#   found on PuppetLab's Puppet Forge.
#
# === Parameters
#
# [*ensure*]
#   Specifies if the module should be installed or removed.  The possible values
#   are 'absent', 'installed', and 'present'.  Default: 'installed'
#
# [*modulepath*]
#   Specifies a custom modulepath.  Defaults to the current modulepath as specified
#   by puppet.conf
#
# [*version*]
#   Specifies a specific version of the module to be installed
#
# === Limitations
#
#   This define does not handle the upgrading of puppet modules.  This is not something
#   that is likely to be added as an automated upgrade of a module could render the
#   the puppet system non-operational.
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
define puppet::module (
    $ensure     = 'installed',
    $modulepath = $settings::modulepath,
    $version    = '',
)
{
    # The puppet class should come first as it will
    # most likely be the one to create $modulepath
    Class['puppet'] -> Puppet::Module[$title]

    case $ensure {
        'installed','present': {
            if ( $version != '' ) {
                $version_arg = "--version ${version}"
            } else {
                $version_arg = ''
            }

            exec { "install-module-${title}":
                path    => [ '/bin', '/usr/bin' ],
                command => "puppet module install --modulepath=${modulepath} ${title} ${version_arg}",
                unless  => "grep \"'${title}'\" \"${modulepath}/\"*\"/Modulefile\" 2>/dev/null"
            }
        }
        'absent': {
            exec { "uninstall-module-${title}":
                path    => [ '/bin', '/usr/bin' ],
                command => "puppet module uninstall --modulepath=${modulepath} ${title}",
                onlyif  => "test `grep \"'${title}'\" \"${modulepath}/\"*\"/Modulefile\" 2>/dev/null | grep -c \"'${title}'\"` -ge 1"
            }
        }
        default: {
            fail("unknown value for ensure ($ensure)")
        }
    }
}
