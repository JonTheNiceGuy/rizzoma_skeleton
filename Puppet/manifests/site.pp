Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }

exec { 'apt-get update':
  command => 'apt-get update',
  timeout => 60,
  tries   => 3
}

class { 'apt':
  always_apt_update => true,
}

$requiredPackages = [
  'couchdb',
  'rabbitmq-server',
  'sphinxsearch',
  'redis-server',
  'imagemagick',
  'libicu-dev'
]

package { $requiredPackages :
  ensure  => "installed",
  require => Exec['apt-get update']
}

include nodejs

file { '/usr/bin/node' :
  ensure => link,
  target => '/usr/bin/nodejs',
  require => Package['nodejs']
}

file { "/srv/src/server/settings_local.coffee":
    replace => "no",
    ensure  => "present",
    source  => "/srv/src/server/settings_local.coffee.template",
    mode    => 644,
}

# firet run only? also cwd not working :(
exec { "/srv/node_modules/.bin/cake build-server build-client" :
    cwd => "/srv",
    require => File['/usr/bin/node']
}

# This next batch relies on Upstart - this will need to be changed to
# SystemD when 14.10 drops.
file { '/etc/init/rizzoma.conf':
  ensure => present,
  source => '/srv/initscripts/upstart',
  require => Package['nodejs'],
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

file_line { "set rizzoma port" :
  path => "/srv/src/server/settings.coffee",
  line => "        listenPort: 80",
  match => "^        listenPort:"
}

file_line { "set owner email address" :
  path => "/srv/src/server/settings.coffee",
  line => "            ownerUserEmail: 'owner@${fqdn}'",
  match => "^            ownerUserEmail:",
  require => File_line['set rizzoma port'],
  notify => Service['rizzoma']
}

file_line { "set support email address" :
  path => "/srv/src/server/settings.coffee",
  line => "    supportEmail: 'support@${fqdn}'",
  match => "^    supportEmail:",
  require => File_line['set rizzoma port'],
  notify => Service['rizzoma']
}

file_line { "set rizzoma hostname" :
  path => "/srv/src/server/settings.coffee",
  line => "    baseUrl: 'http://${fqdn}'",
  match => "^    baseUrl:",
  require => File_line['set rizzoma port'],
  notify => Service['rizzoma']
}

service { 'rizzoma':
  ensure => running,
  provider => 'upstart',
  require => File['/etc/init.d/rizzoma', '/etc/init/rizzoma.conf'],
}

service { 'sphinxsearch':
  ensure => running,
  require => File_line['start sphinx'],
  notify => Service['rizzoma']
}
