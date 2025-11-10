#
# Cookbook:: vpn
# Recipe:: headscale
#

version = node.fetch('vpn').fetch('headscale').fetch('version')
checksums = node.fetch('vpn').fetch('headscale').fetch('checksums')

GITHUB_HEADSCALE_RELEASES_URL = Proc.new { |version, package| "https://github.com/juanfont/headscale/releases/download/v#{version}/#{package}" }
PACKAGE_FILENAME = Proc.new { |version| "headscale_#{version}_linux_amd64.deb" }

directory '/var/headscale' do
  mode '0755'
end

remote_file File.join('/var/headscale', PACKAGE_FILENAME.call(version)) do
  source GITHUB_HEADSCALE_RELEASES_URL.call(version, PACKAGE_FILENAME.call(version))

  mode '0644'

  checksum checksums.fetch('deb_package')
end

dpkg_package 'headscale' do
  source File.join('/var/headscale', PACKAGE_FILENAME.call(version))

  action :install
end

ruby_block 'ensure configuration files exist' do
  block do
    unless File.exist?('/etc/headscale/hostname.txt') && !File.zero?('/etc/headscale/hostname.txt')
      raise 'Expected a URL (e.g.; "foo.duckdns.org") within /etc/headscale/hostname.txt'
    end

    unless File.exist?('/etc/headscale/magicdns-base-domain.txt') && !File.zero?('/etc/headscale/magicdns-base-domain.txt')
      raise 'Expected a URL (e.g.; "tailnet.foo.duckdns.org") within /etc/headscale/magicdns-base-domain.txt'
    end
  end
end

template '/etc/headscale/config.yaml' do
  source 'headscale-config.yaml.erb'

  group lazy { Etc.getpwnam('headscale').gid }

  variables lazy {
    hostname = File.read('/etc/headscale/hostname.txt').strip
    base_domain = File.read('/etc/headscale/magicdns-base-domain.txt').strip

    acl_policy_path = '/etc/headscale/acl.hujson'
    acl_policy_path = '""' unless File.exist?(acl_policy_path) && File.file?(acl_policy_path)

    { hostname: hostname, base_domain: base_domain, acl_policy_path: acl_policy_path }
  }

  mode '0640'
end

systemd_unit 'headscale.service' do
  action :enable
end

execute 'ufw allow headscale http connection' do
  command [*%w[ufw allow 80/tcp comment], 'Allow Headscale (http)']

  not_if do
    `ufw status verbose | grep -q '80/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw allow headscale https connection' do
  command [*%w[ufw allow 443/tcp comment], 'Allow Headscale (https)']

  not_if do
    `ufw status verbose | grep -q '443/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw allow headscale 8080/tcp connection' do
  command [*%w[ufw allow 8080/tcp comment], 'Allow Headscale (8080/tcp)']

  not_if do
    `ufw status verbose | grep -q '8080/tcp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw allow wireguard 41641/udp connection' do
  command [*%w[ufw allow 41641/udp comment], 'Allow WireGuard tunnel (41641/udp)']

  not_if do
    `ufw status verbose | grep -q '41641/udp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end

execute 'ufw allow wireguard 3478/udp connection' do
  command [*%w[ufw allow 3478/udp comment], 'Allow STUN (3478/udp)']

  not_if do
    `ufw status verbose | grep -q '3478/udp.*ALLOW IN'`
    $?.success?
  end

  notifies :run, 'execute[ufw reload]', :delayed
end
