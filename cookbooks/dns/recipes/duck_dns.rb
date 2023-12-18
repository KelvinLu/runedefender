#
# Cookbook:: dns
# Recipe:: duck_dns
#

directory '/var/duck-dns' do
  mode '0755'
end

directory '/etc/duck-dns' do
  mode '0755'
end

file '/etc/duck-dns/domain' do
  mode '0600'

  action :create_if_missing
end

file '/etc/duck-dns/token' do
  mode '0600'

  action :create_if_missing
end

cookbook_file '/var/duck-dns/duck.sh' do
  source 'duck.sh'

  mode '0755'
end

cookbook_file '/etc/systemd/system/duck-dns.service' do
  source 'duck-dns.service'

  mode '0640'
end

cookbook_file '/etc/systemd/system/duck-dns.timer' do
  source 'duck-dns.timer'

  mode '0640'
end

systemd_unit 'duck-dns.service' do
  action :enable
end

systemd_unit 'duck-dns.timer' do
  action :enable
end
