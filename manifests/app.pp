# This defined resource type sets up a specifc application. It is invoked by
# the parent class.

define howalarming::app (
  $howalarming_dir    = $howalarming::howalarming_dir,
  $howalarming_user   = $howalarming::howalarming_user,
  $howalarming_group  = $howalarming::howalarming_group
  ) {

  file { "init_howalarming_${name}":
    ensure   => file,
    mode     => '0644',
    path     => "/etc/systemd/system/howalarming-${name}.service",
    content  => template('howalarming/systemd-app.service.erb'),
    notify   => [
      Exec['howalarming_reload_systemd'],
      Service["howalarming-${name}"],
    ]
  }

  service { "howalarming-${name}":
    ensure  => running,
    enable  => true,
    require => [
     Exec['howalarming_reload_systemd'],
     File["init_howalarming_${name}"],
     File["howalarming_config"],
     Vcsrepo['howalarming_code'],
    ],

    # We want the service to restart when the code and/or configuration changes
    subscribe => [
     File["howalarming_config"],
     Vcsrepo['howalarming_code'],
    ]
  }

}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
