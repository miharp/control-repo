# The base profile should include component modules that will be on all nodes
#
# @param release
#   The OS release version.
# @param use_test_repo
#   When true, point to the pre-release testing repository instead of production.
class profile::base (
  Integer $release,
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
      command => "/usr/bin/curl -fsSL ${apt_base}/openvox-keyring.gpg -o /etc/apt/trusted.gpg.d/openvox-keyring.gpg",
      creates => '/etc/apt/trusted.gpg.d/openvox-keyring.gpg',
    }

    apt::source { "openvox${release}":
      location => "${apt_base}/",
      release  => $apt_dist,
      repos    => "openvox${release}",
      require  => Exec["openvox${release}-apt-key"],
    }
  }
}
