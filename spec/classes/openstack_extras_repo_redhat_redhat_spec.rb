require 'spec_helper'

describe 'openstack_extras::repo::redhat::redhat' do
  shared_examples 'openstack_extras::repo::redhat::redhat' do
    let :class_params do
      {
        :manage_rdo      => true,
        :manage_epel     => true,
        :repo_hash       => {},
        :gpgkey_hash     => {},
        :purge_unmanaged => false,
        :package_require => false
      }
    end

    let :paramclass_defaults do
      {
        :release        => 'train',
        :repo_defaults  => { 'enabled' => '1',
                             'gpgcheck' => '1',
                             'notify' => 'Exec[yum_refresh]',
                             'mirrorlist' => 'absent',
                             'require' => 'Anchor[openstack_extras_redhat]'
                           },
        :gpgkey_defaults => { 'owner' => 'root',
                              'group' => 'root',
                              'mode' => '0644',
                              'before' => 'Anchor[openstack_extras_redhat]'
                            }
      }
    end

    let :default_params do
      class_params.merge!(paramclass_defaults)
    end

    context 'with default parameters' do
      let :params do
        {}
      end

      it { should contain_yumrepo('rdo-release').with(
        :baseurl    => "http://mirror.centos.org/centos/7/cloud/$basearch/openstack-ussuri/",
        :descr      => 'OpenStack Ussuri Repository',
        :gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud',
        :enabled    => '1',
        :gpgcheck   => '1',
        :mirrorlist => 'absent',
        :require    => 'Anchor[openstack_extras_redhat]',
        :notify     => 'Exec[yum_refresh]'
      )}

      it { should contain_yumrepo('rdo-qemu-ev').with(
        :baseurl    => "http://mirror.centos.org/centos/7/virt/$basearch/kvm-common/",
        :descr      => 'RDO CentOS-7 - QEMU EV',
        :gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization',
        :enabled    => '1',
        :gpgcheck   => '1',
        :mirrorlist => 'absent',
        :require    => 'Anchor[openstack_extras_redhat]',
        :notify     => 'Exec[yum_refresh]'
      )}

      it { should contain_exec('installing_yum-plugin-priorities').with(
        :command   => '/usr/bin/yum install -y yum-plugin-priorities',
        :logoutput => 'on_failure',
        :tries     => 3,
        :try_sleep => 1,
        :unless    => '/usr/bin/rpm -qa | /usr/bin/grep -q yum-plugin-priorities',
      ) }

      it { should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud').with(
        :source => 'puppet:///modules/openstack_extras/RPM-GPG-KEY-CentOS-SIG-Cloud',
        :owner  => 'root',
        :group  => 'root',
        :mode   => '0644',
        :before => 'Anchor[openstack_extras_redhat]'
      )}

      it { should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Virtualization').with(
        :source => 'puppet:///modules/openstack_extras/RPM-GPG-KEY-CentOS-SIG-Virtualization',
        :owner  => 'root',
        :group  => 'root',
        :mode   => '0644',
        :before => 'Anchor[openstack_extras_redhat]'
      )}

      it { should_not contain_yumrepo('epel') }
    end

    context 'with overridden release' do
      let :params do
        default_params.merge!({ :release => 'juno' })
      end

      it { should contain_yumrepo('rdo-release').with(
        :baseurl => "http://mirror.centos.org/centos/7/cloud/\$basearch/openstack-juno/",
        :descr   => 'OpenStack Juno Repository',
        :gpgkey  => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud'
      )}

      it { should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud').with(
        :source => 'puppet:///modules/openstack_extras/RPM-GPG-KEY-CentOS-SIG-Cloud'
      )}
    end

    context 'with overridden repo hash' do
      let :params do
        default_params.merge!({ :repo_hash => {
                                   'CentOS-Base' => {
                                       'baseurl' => 'http://mymirror/$releasever/os/$basearch/',
                                       'descr'   => 'CentOS-$releasever - Base',
                                       'gpgkey'  => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6'
                                   },
                                   'CentOS-Updates' => {
                                       'baseurl' => 'http://mymirror/$releasever/updates/$basearch/',
                                       'descr'   => 'CentOS-$releasever - Updates',
                                       'gpgkey'  => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
                                   }
                                }
                              })
      end

      it { should contain_yumrepo('CentOS-Base').with(
        :baseurl    => "http://mymirror/$releasever/os/$basearch/",
        :descr      => "CentOS-$releasever - Base",
        :enabled    => '1',
        :gpgcheck   => '1',
        :gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
        :mirrorlist => 'absent',
        :require    => 'Anchor[openstack_extras_redhat]',
        :notify     => 'Exec[yum_refresh]'
      )}

      it { should contain_yumrepo('CentOS-Updates').with(
        :baseurl    => "http://mymirror/$releasever/updates/$basearch/",
        :descr      => "CentOS-$releasever - Updates",
        :enabled    => '1',
        :gpgcheck   => '1',
        :gpgkey     => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6',
        :mirrorlist => 'absent',
        :require    => 'Anchor[openstack_extras_redhat]',
        :notify     => 'Exec[yum_refresh]'
      )}
    end

    context 'with overridden repo default' do
      let :params do
        default_params.merge!({ :repo_defaults => {
                                   'proxy' => 'http://my.proxy.com:8000'
                                },
                                :centos_mirror_url => 'http://mirror.dfw.rax.openstack.org',
                              })
      end

      it { should contain_yumrepo('rdo-release').with(
        :baseurl => "http://mirror.dfw.rax.openstack.org/centos/7/cloud/\$basearch/openstack-train/",
        :descr   => 'OpenStack Train Repository',
        :gpgkey  => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud',
        :proxy   => 'http://my.proxy.com:8000'
      )}
    end

    context 'with overridden gpgkey default' do
      let :params do
        default_params.merge!({ :gpgkey_defaults => {
                                   'owner' => 'steve'
                                }
                              })
      end

      it { should contain_file('/etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Cloud').with(
        :owner => 'steve'
      )}
    end

    context 'with epel management enabled' do
      let :params do
        default_params.merge!({ :manage_epel => true })
      end

      # 'metalink' property is supported from Puppet 3.5
      if Puppet.version.to_f >= 3.5
        it { should contain_yumrepo('epel').with(
          :metalink       => "https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=\$basearch",
          :descr          => 'Extra Packages for Enterprise Linux 7 - $basearch',
          :gpgkey         => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7',
          :failovermethod => 'priority',
          :enabled        => '1',
          :gpgcheck       => '1',
          :mirrorlist     => 'absent',
          :require        => 'Anchor[openstack_extras_redhat]',
          :notify         => 'Exec[yum_refresh]'
        )}
      else
        it { should contain_yumrepo('epel').with(
          :baseurl        => "https://download.fedoraproject.org/pub/epel/7/\$basearch",
          :descr          => 'Extra Packages for Enterprise Linux 7 - $basearch',
          :gpgkey         => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7',
          :failovermethod => 'priority',
          :enabled        => '1',
          :gpgcheck       => '1',
          :mirrorlist     => 'absent',
          :require        => 'Anchor[openstack_extras_redhat]',
          :notify         => 'Exec[yum_refresh]'
        )}
      end
    end

    context 'with epel management disabled' do
      let :params do
        default_params.merge!({ :manage_epel => false })
      end

      it { should_not contain_yumrepo('epel') }
    end

    context 'with rdo management disabled' do
      let :params do
        default_params.merge!({ :manage_rdo => false })
      end

      it { should_not contain_yumrepo('rdo-release') }
    end

    context 'with rdo-virt management disabled' do
      let :params do
        default_params.merge!({ :manage_virt => false })
      end

      it { should_not contain_yumrepo('rdo-qemu-ev') }
    end

    context 'with manage_priorities disabled' do
      let :params do
        default_params.merge!({ :manage_priorities => false })
      end

      it { should_not contain_exec('installing_yum-plugin-priorities') }
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge!(OSDefaults.get_facts({ :operatingsystem           => 'RedHat',
                                            :operatingsystemrelease    => '7.1',
                                            :operatingsystemmajrelease => '7',
                                            :puppetversion             => Puppet.version }))
      end

      if facts[:osfamily] == 'RedHat'
        it_behaves_like 'openstack_extras::repo::redhat::redhat'
      end
    end
  end
end
