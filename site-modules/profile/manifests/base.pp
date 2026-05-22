# The base profile should include component modules that will be on all nodes
#
# @param release
#   The OS release version.
# @param use_test_repo
#   When true, point to the pre-release testing repository instead of production.
# @param eyaml_secret
#   Eyaml canary value. Encrypted in hiera to validate eyaml is functional on
#   every puppet run. If eyaml breaks (e.g. agent upgrade ships incompatible
#   hiera-eyaml), catalog compilation will fail here rather than silently.
class profile::base (
  Integer $release,
  String  $eyaml_secret,
  Boolean $use_test_repo = false,
) {
  include chrony
  include firewall
  include profile::openvox_agent

  firewall { '100 allow puppet':
    dport => 8140,
    proto => 'tcp',
    jump  => 'ACCEPT',
  }

  class { 'sudo': }
  sudo::conf { 'mharp':
    content => 'mharp ALL=(ALL) NOPASSWD: ALL',
  }
  sudo::conf { 'vagrant':
    content => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }

  if $facts['os']['family'] == 'RedHat' {
    $os_name = $facts['os']['name'] ? {
      'Fedora' => 'fedora',
      default  => 'el',
    }
    if $use_test_repo {
      $yum_base = 'https://s3.osuosl.org/openvox-artifacts/repo_test/yum'
    } else {
      $yum_base = 'https://yum.voxpupuli.org'
    }
    $pkg_source = "${yum_base}/openvox${release}-release-${os_name}-${facts['os']['release']['major']}.noarch.rpm"
    $yum_baseurl = "${yum_base}/openvox${release}/${os_name}/${facts['os']['release']['major']}/\$basearch/"

    package { "openvox${release}-release":
      ensure   => present,
      provider => 'rpm',
      source   => $pkg_source,
    }

    yumrepo { "openvox${release}":
      ensure          => present,
      baseurl         => $yum_baseurl,
      metadata_expire => '300',
      require         => Package["openvox${release}-release"],
      before          => Package['openvox-agent'],
    }
  } elsif $facts['os']['name'] == 'Ubuntu' {
    if $use_test_repo {
      $apt_base = 'https://s3.osuosl.org/openvox-artifacts/repo_test/apt'
    } else {
      $apt_base = 'https://apt.voxpupuli.org'
    }

    $apt_dist = "ubuntu${facts['os']['release']['full']}"

    include apt

    exec { "openvox${release}-apt-key":
      command => "/usr/bin/install -d -m 0755 /etc/apt/keyrings && \
                  /usr/bin/curl -fsSL ${apt_base}/openvox-keyring.gpg \
                  -o /etc/apt/keyrings/openvox-keyring.gpg",
      creates => '/etc/apt/keyrings/openvox-keyring.gpg',
    }

    # Remove the source file dropped by the openvox-release deb to avoid
    # conflicting signed-by values for the same repo URL.
    file { "/etc/apt/sources.list.d/openvox${release}-release.list":
      ensure  => absent,
      require => Exec["openvox${release}-apt-key"],
      notify  => Class['apt::update'],
    }

    apt::source { "openvox${release}":
      location => "${apt_base}/",
      release  => $apt_dist,
      repos    => "openvox${release}",
      keyring  => '/etc/apt/keyrings/openvox-keyring.gpg',
      require  => File["/etc/apt/sources.list.d/openvox${release}-release.list"],
    }
  }
}
