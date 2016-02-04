# Define all default parameters here. Note that this doens't include
# the per-app configs, more the core bits relating to the overall
# howalarming system.
#
# You can override these in Hiera, but do so via the inheriting class.
#
# Don't use:
# howalarming::params::beanstalk_port = '6666'
# Use:
# howalarming::beanstalk_port = '6666'
#

class howalarming::params {

  # TODO: Currently hardcoded, set as a param here for future proofing
  # as it could vary across platforms.
  $beanstalk_package = 'beanstalkd'

  # Port to run beanstalk on.
  $beanstalk_port = '11300'

  # We use the jethrocarr/initfact module to identify the init system for us
  $init_system = $::initsystem

  if (!$init_system) {
    fail('Install the jethrocarr/initfact module to provide identification of the init system being used. Required to make this module work.')
  }
    
}

# vi:smartindent:tabstop=2:shiftwidth=2:expandtab:
