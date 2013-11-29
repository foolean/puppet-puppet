define puppet::master::site::developer (
    $site = false,
)
{
    if ( ! $site ) {
        fail('must specify a site name')
    }

    # Create or remove the site's directory structure
    if ( $ensure == 'absent' ) {
        file { "${puppet::vardir}/sites/${site}/developers/${title}":
            ensure  => 'absent',
            force   => true,
            recurse => true,
        }
    } else {
        # Create the default development directory for this site
        file { "${puppet::vardir}/sites/${site}/developers/${title}":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $puppet::puppet_group,
            mode    => '0660',
            require => [
                File["${puppet::vardir}/sites/${site}"],
                File["${puppet::vardir}/sites/${site}/developers"],
            ],
        }

        # Create the default development manifests directory for this site
        file { "${puppet::vardir}/sites/${site}/developers/${title}/manifests":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '0660',
            force   => true,
            recurse => true,
            require => [
                File["${puppet::vardir}/sites/${site}"],
                File["${puppet::vardir}/sites/${site}/developers"],
                File["${puppet::vardir}/sites/${site}/developers/${title}"],
            ],
        }

        # Create the default development modules directory for this site
        file { "${puppet::vardir}/sites/${site}/developers/${title}/modules":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '0660',
            force   => true,
            recurse => true,
            require => [
                File["${puppet::vardir}/sites/${site}"],
                File["${puppet::vardir}/sites/${site}/developers"],
                File["${puppet::vardir}/sites/${site}/developers/${title}"],
            ],
        }

        # Create the default development private directory for this site
        file { "${puppet::vardir}/sites/${site}/developers/${title}/private":
            ensure  => 'directory',
            owner   => $puppet::puppet_user,
            group   => $group,
            mode    => '0660',
            force   => true,
            recurse => true,
            require => [
                File["${puppet::vardir}/sites/${site}"],
                File["${puppet::vardir}/sites/${site}/developers"],
                File["${puppet::vardir}/sites/${site}/developers/${title}"],
            ],
        }
    }
}
