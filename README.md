# puppet-howalarming

Installs and configures the daemons behind HowAlarming including the init
configuration to ensure daemons launch & recover as required.

To learn more about HowAlarming, refer to:
https://github.com/jethrocarr/howalarming


## What it does

* Installs the HowAlarming programs from the upstream git repository.
* Installs init configuration (TODO: which ones?)
* Configures howalarming and reloads services as required.


## Configuration

As HowAlarming is made up of multiple individual programs (mmm unix style) the
exact set that you want to run will depend on your environment. Hence, you
need to define the list when you invoke the class.

    class { '::howalarming':
        apps => ['envisalinkd', 'alert_email']
    }

The class will setup the beanstalk queue and each of the specified applications
will be configured in the init system.

To generate config.yaml, self-generate data is merged with data in Hiera to
generate a complete configuration. This works by defining values in Hiera based
on the class name (`howalarming`) and the application name, as per the following:

    howalarming::app_config:
      APPLICATION:
        key: value

Here's how the config.example.yaml would look, expressed in Hiera with this
Puppet module:

    howalarming::app_config:
      envisalinkd:
        host: 192.168.1.1
        port: 4025
        password: durp12
        code_master: 1234
        code_installer: 5555
        zones:
          '001': Study PIR
          '002': Dungeon PIR
          '003': Bedroom PIR
          '004': Bomb Shelter PIR
          '005': Fire Alarm
          '006': Tamper Switches
      
      alert_email:
        smtp_host: localhost
        smtp_port: 25
        addr_from: alarm@example.com
        addr_to: heythatsmytv@example.com
        # You will want to be selective with triggers, recommend leaving these defaults alone.
        triggers:
         - alarm
         - recovery
         - fault
         - armed
         - disarmed

This differs from some modules like Puppetlab's Apache module which define
every possible option as a parameter, but make for massive amounts of
boilerplate. This module assumes you're smart enough to be able to structure
some YAML data. :-)

You don't need to define the beanstlakd configuration or the tubes that should
be present, that is handled by the Puppet module for you. Almost all the other
defaults like app installation location, ports, git repo, etc should be left
as-is, but if needed refer to `manifests/params.pp` for information on how to
override the defaults.



## Requirements

This module requires the following dependencies:

* [puppetlabs/vcsrepo](https://forge.puppetlabs.com/puppetlabs/vcsrepo)
* [jethrocarr/initfact](https://forge.puppetlabs.com/jethrocarr/initfact)

It is tested/supported on the following platforms:

* CentOS 7


Note that this module only supports the following initsystems currently:

* systemd


## Debugging

If any of the HowAlarming apps are failing, have a look at their log output with:

    journalctl -f -u howalarming-APPNAME

Where `APPNAME` is either "beanstalk" (for the queue status) or any of the apps
defined when you invoked the Puppet class.


## Contributions

All contributions are welcome via Pull Requests including documentation fixes or
compatibility fixes for supporting other distributions (or other operating
systems).


## License

This module is licensed under the Apache License, Version 2.0 (the "License").
See the LICENSE.txt or http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

