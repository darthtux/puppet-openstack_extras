# == Class: openstack_extras::repo::redhat::redhat
#
# This repo sets up yum repos for use with the redhat
# osfamily and redhat operatingsystem.
#
# === Parameters:
#
# [*release*]
#   (optional) The openstack release to use if managing rdo
#   Defaults to $::openstack_extras::repo::redhat::params::release
#
# [*manage_rdo*]
#   (optional) Whether to create a predefined yumrepo resource
#   for the RDO OpenStack repository provided by RedHat
#   Defaults to true
#
# [*manage_virt*]
#   (optional) Whether to create a predefined yumrepo resource
#   for the RDO CentOS QEMU EV epository provided by RedHat.
#   This repository has been required starting from Newton.
#   Defaults to true
#
# [*manage_epel*]
#   (optional) Whether to create a predefined yumrepo resource
#   for the EPEL repository provided by RedHat
#   Note: EPEL is not required when deploying OpenStack with RDO.
#   Defaults to false
#
# [*repo_hash*]
#   (optional) A hash of yumrepo resources that will be passed to
#   create_resource. See examples folder for some useful examples.
#   Defaults to {}
#
# [*repo_defaults*]
#   (optional) The defaults for the yumrepo resources that will be
#   created using create_resource.
#   Defaults to $::openstack_extras::repo::redhat::params::repo_defaults
#
# [*gpgkey_hash*]
#   (optional) A hash of file resources that will be passed to
#   create_resource. See examples folder for some useful examples.
#   Defaults to {}
#
# [*gpgkey_defaults*]
#   (optional) The default resource attributes to
#   create gpgkeys with.
#   Defaults to $::openstack_extras::repo::redhat::params::gpgkey_defaults
#
# [*purge_unmanaged*]
#   (optional) Purge the yum.repos.d directory of
#   all repositories not managed by Puppet
#   Defaults to false
#
# [*package_require*]
#   (optional) Set all packages to require all
#   yumrepos be set.
#   Defaults to false
#
# [*manage_priorities*]
#   (optional) Whether to install yum-plugin-priorities package so
#   'priority' value in yumrepo will be effective.
#   Defaults to true
#
# [*centos_mirror_url*]
#   (optional) URL of CentOS mirror.
#   Defaults to 'http://mirror.centos.org'
#
class openstack_extras::repo::redhat::redhat(
  $release           = $::openstack_extras::repo::redhat::params::release,
  $manage_rdo        = true,
  $manage_virt       = true,
  $manage_epel       = false,
  $repo_hash         = {},
  $repo_defaults     = {},
  $gpgkey_hash       = {},
  $gpgkey_defaults   = {},
  $purge_unmanaged   = false,
  $package_require   = false,
  $manage_priorities = true,
  $centos_mirror_url = 'http://mirror.centos.org',
) inherits openstack_extras::repo::redhat::params {

  validate_legacy(String, 'validate_string', $release)
  validate_legacy(Boolean, 'validate_bool', $manage_rdo)
  validate_legacy(Boolean, 'validate_bool', $manage_epel)
  validate_legacy(Hash, 'validate_hash', $repo_hash)
  validate_legacy(Hash, 'validate_hash', $repo_defaults)
  validate_legacy(Hash, 'validate_hash', $gpgkey_hash)
  validate_legacy(Hash, 'validate_hash', $gpgkey_defaults)
  validate_legacy(Boolean, 'validate_bool', $purge_unmanaged)
  validate_legacy(Boolean, 'validate_bool', $package_require)

  $_repo_defaults = merge($::openstack_extras::repo::redhat::params::repo_defaults, $repo_defaults)
  $_gpgkey_defaults = merge($::openstack_extras::repo::redhat::params::gpgkey_defaults, $gpgkey_defaults)

  anchor { 'openstack_extras_redhat': }

  if $manage_rdo {
    $release_cap = capitalize($release)

    $rdo_hash = {
      'rdo-release' => {
        'baseurl'  => "${centos_mirror_url}/centos/7/cloud/\$basearch/openstack-${release}/",
        'descr'    => "OpenStack ${release_cap} Repository",
        'gpgkey'   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud',
      }
    }

    $rdokey_hash = { '/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud' => {
        'source' => 'puppet:///modules/openstack_extras/RPM-GPG-KEY-CentOS-SIG-Cloud'
      }
    }

    create_resources('file', $rdokey_hash, $_gpgkey_defaults)
    create_resources('yumrepo', $rdo_hash, $_repo_defaults)
  }

  if $manage_virt and ($::operatingsystem != 'Fedora') {
    $virt_hash = {
      'rdo-qemu-ev' => {
        'baseurl'  => "${centos_mirror_url}/centos/7/virt/\$basearch/kvm-common/",
        'descr'    => 'RDO CentOS-7 - QEMU EV',
        'gpgkey'   => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization',
      }
    }

    $virtkey_hash = { '/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization' => {
        'source' => 'puppet:///modules/openstack_extras/RPM-GPG-KEY-CentOS-SIG-Virtualization'
      }
    }

    create_resources('file', $virtkey_hash, $_gpgkey_defaults)
    create_resources('yumrepo', $virt_hash, $_repo_defaults)
  }

  if $manage_epel {
    if ($::osfamily == 'RedHat' and
        $::operatingsystem != 'Fedora')
    {
      # 'metalink' property is supported from Puppet 3.5
      if (versioncmp($::puppetversion, '3.5') >= 0) {
        $epel_hash = { 'epel' => {
            'metalink'        => "https://mirrors.fedoraproject.org/metalink?repo=epel-${::operatingsystemmajrelease}&arch=\$basearch",
            'descr'           => "Extra Packages for Enterprise Linux ${::operatingsystemmajrelease} - \$basearch",
            'gpgkey'          => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${::operatingsystemmajrelease}",
            'failovermethod'  => 'priority'
          }
        }
      } else {
        $epel_hash = { 'epel' => {
            'baseurl'         => "https://download.fedoraproject.org/pub/epel/${::operatingsystemmajrelease}/\$basearch",
            'descr'           => "Extra Packages for Enterprise Linux ${::operatingsystemmajrelease} - \$basearch",
            'gpgkey'          => "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${::operatingsystemmajrelease}",
            'failovermethod'  => 'priority'
          }
        }
      }

      $epelkey_hash = { "/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-${::operatingsystemmajrelease}" => {
          'source' => "puppet:///modules/openstack_extras/RPM-GPG-KEY-EPEL-${::operatingsystemmajrelease}"
        }
      }

      create_resources('file', $epelkey_hash, $_gpgkey_defaults)
      create_resources('yumrepo', $epel_hash, $_repo_defaults)
    }
  }

  validate_yum_hash($repo_hash)
  create_resources('yumrepo', $repo_hash, $_repo_defaults)
  create_resources('file', $gpgkey_hash, $_gpgkey_defaults)

  if ((versioncmp($::puppetversion, '3.5') > 0) and $purge_unmanaged) {
      resources { 'yumrepo': purge => true }
  }

  if $manage_priorities and ($::operatingsystem != 'Fedora') {
    exec { 'installing_yum-plugin-priorities':
      command   => '/usr/bin/yum install -y yum-plugin-priorities',
      logoutput => 'on_failure',
      tries     => 3,
      try_sleep => 1,
      unless    => '/usr/bin/rpm -qa | /usr/bin/grep -q yum-plugin-priorities',
    }
    Exec['installing_yum-plugin-priorities'] -> Yumrepo<||>
  }

  if $package_require {
      Yumrepo<||> -> Package<||>
  }

  if ($::operatingsystem == 'Fedora') {
    exec { 'yum_refresh':
      command     => '/usr/bin/dnf clean all',
      refreshonly => true,
    } -> Package <||>
    } else {
    exec { 'yum_refresh':
      command     => '/usr/bin/yum clean all',
      refreshonly => true,
    } -> Package <||>
  }
}
