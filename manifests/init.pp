# This class installs HowAlarming and sets up the various services. Please
# refer to the `README.md` for general configuration advice or to `params.pp`
# if you wish to override any of the following parameters with Hiera.

class howalarming (
  $beanstalk_package = $howalarming::params::beanstalk_package,
  $beanstalk_port    = $howalarming::params::beanstalk_port,
  $beanstalk_binary  = $howalarming::params::beanstalk_binary,
  $init_system       = $howalarming::params::init_system,
  $howalarming_dir   = $howalarming::params::howalarming_dir,
  $howalarming_git   = $howalarming::params::howalarming_git,
  $howalarming_user  = $howalarming::params::howalarming_user,
  $howalarming_group = $howalarming::params::howalarming_group,
) inherits howalarming::params {

  # TODO: Currently we only support systemd - Use a recent distribution or
  # contribute a PR for supporting legacy systems.

  if ($init_system != 'systemd') {
    fail('howalarming module only support systemd')
  }


  # Download the source code for HowAlarming from Github and checkout into the
  # installation directory

  if ! defined(Package['git']) {
    package { 'git':
      ensure => installed,
    }
  }

  file { 'howalarming_home':
    ensure => directory,
    name   => $howalarming_dir,
    owner  => $howalarming_user,
    group  => $howalarming_group,
    mode   => '0700',
  }

  vcsrepo { 'howalarming_code':
    ensure   => latest,
    provider => 'git',
    path     => $howalarming_dir,
    source   => $howalarming_git,
    revision => 'master',
    require  => File['howalarming_home'],
  }


  # systemd needs a reload after any unit files are changed, we setup a handy
  # exec here.
  exec { 'howalarming_reload_systemd':
    command     => 'systemctl daemon-reload',
    path        => ["/bin", "/sbin", "/usr/bin", "/usr/sbin"],
    refreshonly => true,
  }


  # Beanstalk Messaging Queue. We need to setup a service for howalarming's
  # instance of it.

  if ! defined(Package['beanstalk']) {
    package { $beanstalk_package:
      ensure => installed,
    }
  }

  file { 'init_howalarming_beanstalk':
    ensure   => file,
    mode     => '0644',
    path     => '/etc/systemd/system/howalarming-beanstalk.service',
    content  => template('howalarming/systemd-beanstalk.service.erb'),
    notify   => [
      Exec['howalarming_reload_systemd'],
      Service['howalarming-beanstalk'],
    ]
  }

  service { 'howalarming-beanstalk':
    ensure  => running,
    enable  => true,
    require => [
     Exec['howalarming_reload_systemd'],
     File['init_howalarming_beanstalk'],
     Package[$beanstalk_package],
    ]
  }


}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
