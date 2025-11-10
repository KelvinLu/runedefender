#
# Cookbook:: dns
# Recipe:: ddclient
#

version = node.fetch('dns').fetch('ddclient').fetch('version')
checksums = node.fetch('dns').fetch('ddclient').fetch('checksums')

GITHUB_DDCLIENT_RELEASES_URL = Proc.new { |version, package| "https://github.com/ddclient/ddclient/releases/download/v#{version}/#{package}" }
PACKAGE_FILENAME = Proc.new { |version| "ddclient-#{version}.tar.gz" }

EXTRACT_DIRECTORY = File.join('/var/ddclient', PACKAGE_FILENAME.call(version).delete_suffix('.tar.gz'))

apt_package 'build-essential' do
  action :install
end

directory '/var/ddclient' do
  mode '0755'
end

remote_file File.join('/var/ddclient', PACKAGE_FILENAME.call(version)) do
  source GITHUB_DDCLIENT_RELEASES_URL.call(version, PACKAGE_FILENAME.call(version))

  mode '0644'

  checksum checksums.fetch('tar_gz')
end

execute 'extract ddclient archive' do
  command [
    'tar',
    '-xvf', File.join('/var/ddclient', PACKAGE_FILENAME.call(version)),
    '-C', '/var/ddclient'
  ]

  only_if {
    !File.exist?(EXTRACT_DIRECTORY) || Dir.empty?(EXTRACT_DIRECTORY)
  }

  action :nothing
end


execute 'configure ddclient' do
  command [
    './configure',
    '--prefix=/usr',
    '--sysconfdir=/etc',
    '--localstatedir=/var'
  ]

  cwd EXTRACT_DIRECTORY

  action :nothing
end


execute 'make ddclient' do
  command [
    'make'
  ]

  cwd EXTRACT_DIRECTORY

  action :nothing
end

execute 'install ddclient' do
  command [
    'make', 'install'
  ]

  cwd EXTRACT_DIRECTORY

  only_if { `which ddclient`.empty? }

  notifies :run, 'execute[extract ddclient archive]', :before
  notifies :run, 'execute[configure ddclient]', :before
  notifies :run, 'execute[make ddclient]', :before
end

file '/etc/systemd/system/ddclient.service' do
  owner 'root'
  group 'root'
  mode 0755

  content lazy {
    File.open(File.join(EXTRACT_DIRECTORY, 'sample-etc_systemd.service')).read
  }

  action :create_if_missing
end

systemd_unit 'ddclient.service' do
  action :enable
end
