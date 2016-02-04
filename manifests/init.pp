# All the fun happens here :-)
class howalarming (
  $beanstalk_package = $howalarming::params::beanstalk_package,
  $beanstalk_port    = $howalarming::params::beanstalk_port,
  $init_system       = $howalarming::params::init_system,
) inherits howalarming::params {

  # TODO: Currently we only support systemd - Use a recent distribution or
  # contribute a PR for supporting legacy systems.

  if ($init_system != 'systemd') {
    fail('howalarming module only support systemd')
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

  package { 'beanstalk_server':
    ensure => installed,
    name   => $beanstalk_package
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
     File['init_howalarming_beanstalk']
    ]
  }


}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
