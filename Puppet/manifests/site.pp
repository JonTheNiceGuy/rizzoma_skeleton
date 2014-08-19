Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

class { 'apt':
  always_apt_update => true,
}

exec { 'apt-get update':
  command => 'apt-get update',
  timeout => 60,
  tries   => 3
}

$requiredpackages = [
  'couchdb',
  'rabbitmq-server',
  'sphinxsearch',
  'redis-server',
  'imagemagick',
  'libicu-dev',
  'git'
]


package { $requiredpackages :
  ensure  => "installed",
  require => Exec['apt-get update']
}

$rubyrequiredpackages = [
  'build-essential',
  'g++',
  'libsqlite3-dev',
  'ruby-dev'
]

package { $rubyrequiredpackages :
  ensure  => "installed",
  require => Exec['apt-get update']
}

package { "mailcatcher" :
  ensure  => "installed",
  provider => "gem",
  require => Package['build-essential','g++','libsqlite3-dev','ruby-dev']
}

include nodejs

file { '/usr/bin/node' :
  ensure => link,
  target => '/usr/bin/nodejs',
  require => Package['nodejs']
}

# This next batch relies on Upstart - this will need to be changed to
# SystemD when 14.10 drops.
file { '/etc/init/rizzoma.conf':
  ensure => present,
  source => '/srv/initscripts/rizzoma.upstart',
  require => Package['nodejs'],
  owner  => 'root',
  group  => 'root'
}

file { '/etc/init.d/mailcatcher':
  ensure => link,
  target => '/lib/init/upstart-job',
}

file { '/etc/init/mailcatcher.conf':
  ensure => present,
  source => '/srv/initscripts/mailcatcher.upstart',
  require => Package['mailcatcher'],
  owner  => 'root',
  group  => 'root'
}

file { '/etc/init.d/rizzoma':
  ensure => link,
  target => '/lib/init/upstart-job',
}

file { "/etc/sphinxsearch/sphinx.conf":
  ensure  => "present",
  source  => "/srv/etc/sphinxsearch/sphinx.conf",
  mode    => 644,
  require => Package['sphinxsearch']
}

file_line { "sphinx project dir" :
  path => '/etc/sphinxsearch/sphinx.conf',
  line => "    xmlpipe_command = /srv/bin/generate_search_index.sh",
  match => "^\s*xmlpipe_command = (.*)generate_search_index.sh$",
  require => File['/etc/sphinxsearch/sphinx.conf']
}

file_line { "start sphinx" :
  path => "/etc/default/sphinxsearch",
  line => "START=yes",
  match => "^START=",
  require => Package['sphinxsearch']
}

file { "/srv/src/server/settings_local.coffee":
  replace => "no",
  ensure  => "present",
  source  => "/srv/src/server/settings_local.coffee.template",
  mode    => 644,
  require => Exec['Pull the latest Rizzoma updates']
}

file_line { "set rizzoma port" :
  path => "/srv/src/server/settings_local.coffee",
  line => "\nsettings.dev.app.listenPort = 80",
  ensure => present,
  require => File["/srv/src/server/settings_local.coffee"]
}

file_line { "set support email address" :
  path => "/srv/src/server/settings_local.coffee",
  line => "\nsettings.dev.supportEmail = 'support@${fqdn}'",
  ensure => present,
  require => File["/srv/src/server/settings_local.coffee"]
}

file_line { "set rizzoma hostname" :
  path => "/srv/src/server/settings_local.coffee",
  line => "\nsettings.dev.baseUrl = 'http://${fqdn}'",
  ensure => present,
  require => File["/srv/src/server/settings_local.coffee"]
}

file_line { "Set SMTP services" :
  path => "/srv/src/server/settings_local.coffee",
  line => "\nsettings.dev.notification.transport.smtp = {}\nsettings.dev.notification.transport.smtp.host = 'localhost'\nsettings.dev.notification.transport.smtp.port = 1025\nsettings.dev.notification.transport.smtp.from = 'rizzoma@site.com'\nsettings.dev.notification.transport.smtp.fromName = 'Rizzoma Agent'",
  ensure => present,
  require => File["/srv/src/server/settings_local.coffee"]
}

file_line { "Ensure config is loaded" :
  path => "/srv/src/server/settings_local.coffee",
  line => "\nmodule.exports = settings",
  ensure => present,
  require => [File["/srv/src/server/settings_local.coffee"],File_line['Set SMTP services',"set rizzoma port",'set rizzoma hostname',"set support email address"]]
}

service { 'rizzoma':
  ensure => running,
  provider => 'upstart',
  require => [File['/etc/init.d/rizzoma', '/etc/init/rizzoma.conf'],File_line['Set SMTP services',"set rizzoma port",'set rizzoma hostname',"set support email address", "Ensure config is loaded"]]
}

service { 'sphinxsearch':
  ensure => running,
  require => File_line['start sphinx'],
  notify => Service['rizzoma']
}

service { 'mailcatcher':
  ensure => running,
  provider => 'upstart',
  require => File['/etc/init.d/mailcatcher', '/etc/init/mailcatcher.conf']
}

warning("Please visit http://$fqdn to visit the Rizzoma Service and http://$fqdn:1080 for the mailcatcher service")

exec { 'Checkout the Rizzoma master branch':
  command => 'git checkout master',
  cwd     => '/all_code/Application',
  timeout => 60,
  tries   => 3,
  require => Package['git']
}

exec { 'Pull the latest Rizzoma updates':
  command => 'git pull',
  cwd     => '/all_code/Application',
  timeout => 60,
  tries   => 3,
  require => Exec['Checkout the Rizzoma master branch']
}

