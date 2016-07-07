# This class installs HowAlarming and sets up the various services. Please
# refer to the `README.md` for general configuration advice or to `params.pp`
# if you wish to override any of the following parameters with Hiera.

class howalarming (
  $apps               = undef,
  $app_config         = undef,
  $python_pip_package = $howalarming::params::python_pip_package,
  $beanstalk_package  = $howalarming::params::beanstalk_package,
  $beanstalk_port     = $howalarming::params::beanstalk_port,
  $beanstalk_binary   = $howalarming::params::beanstalk_binary,
  $init_system        = $howalarming::params::init_system,
  $howalarming_dir    = $howalarming::params::howalarming_dir,
  $howalarming_git    = $howalarming::params::howalarming_git,
  $howalarming_user   = $howalarming::params::howalarming_user,
  $howalarming_group  = $howalarming::params::howalarming_group,
) inherits ::howalarming::params {

  # TODO: Currently we only support systemd - Use a recent distribution or
  # contribute a PR for supporting legacy systems.

  if ($init_system != 'systemd') {
    fail('howalarming module only support systemd')
  }

  if ! is_array($apps) {
    fail('You must specify which HowAlarming apps you want to run with howalarming::apps as an array without file extensions')
  }

  if ! is_hash($app_config) {
    fail('You must set the application configuration in Hiera')
  }


  # Create a system user/group if it's set to "howalarming". This allows a user
  # to override to use an existing account if desired.
  if ($howalarming_group == "howalarming") {
    group { 'howalarming':
      ensure => present,
      system => true,
    }
  }

  if ($howalarming_user == "howalarming") {
    user { 'howalarming':
      ensure  => present,
      gid     => $howalarming_group,
      home    => $howalarming_dir,
      system  => true,
      shell   => '/sbin/nologin',
      require => Group[$howalarming_group],
    }
  }

  # Install all the python dependencies. Note that we use "ensure_resource"
  # rather than a standard package resource, since it ensures no clashes if
  # defined multiple times.

  ensure_resource('package', [$python_pip_package], {'ensure' => 'installed'})

  ensure_resource('package', ['pyyaml', 'beanstalkc', 'plivo'], {
    'ensure'   => 'installed',
    'provider' => 'pip',                        # Ensure we always use upstream python packages (vs os packages)
    'before'   => Vcsrepo['howalarming_code'],  # Make sure we have all deps before the apps can install/run
    'require'  => Package[$python_pip_package],
  })


  # The GCM service requires Java 7+
  ensure_resource('package', ['java'], {'ensure' => 'installed'})


  # Download the source code for HowAlarming from Github and checkout into the
  # installation directory

  ensure_resource('package', ['git'], {'ensure' => 'installed'})

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
    require  => [
      Package['git'],
      Package['java'],
      File['howalarming_home'],
    ]
  }

  # Configuration File. This is populated with data from $app_config and is
  # subscribed to by each app, so that a change to the config will result in
  # a restart of all the dependent services.

  file { 'howalarming_config':
    ensure  => file,
    mode    => '0600',
    owner   => $howalarming_user,
    group   => $howalarming_group,   
    path    => "${howalarming_dir}/config.yaml",
    content => template('howalarming/config.yaml.erb'),
    require => Vcsrepo['howalarming_code'],
  }


  # systemd needs a reload after any unit files are changed, we setup a handy
  # exec here.
  exec { 'howalarming_reload_systemd':
    command     => 'systemctl daemon-reload',
    path        => ["/bin", "/sbin", "/usr/bin", "/usr/sbin"],
    refreshonly => true,
  }


  # Beanstalk Messaging Queue. We need to setup a service for howalarming's
  # instance of it. It's very simular to the apps, but not 100% identical
  # since it doesn't require the repo to be ready nor for there to be the config
  # file in place.

  ensure_resource('package', [$beanstalk_package], {'ensure' => 'installed'})

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

  # Finally we need to define each app that has been specified. We use a clever
  # hack here where we pass the array to a Puppet defined resource type causing
  # a form of iteration that works on both Puppet 3 and Puppet 4. In the future
  # when everything is Puppet 4 and beautiful, we could move to an each iterator
  # instead.
  # 
  # Refer to:
  # https://docs.puppetlabs.com/puppet/latest/reference/lang_iteration.html

  ::howalarming::app { $apps: }


}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
