#
# Cookbook:: server
# Recipe:: customization
#

operator_user = Etc.getpwnam(node.fetch('operator_user'))
operator_home = Dir.home(operator_user.name)

cookbook_file File.join(operator_home, '.inputrc') do
  source '.inputrc'

  owner operator_user.uid
  group operator_user.gid
  mode '0644'
end

USER_PS1_STANZA = <<~'BASH'.strip
if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
BASH

Etc.passwd do |user|
  bashrc_file = File.join(user.dir, '.bashrc')

  if (user.shell == '/bin/bash') && File.file?(bashrc_file)
    file "#{bashrc_file}.orig" do
      content lazy { File.open(bashrc_file).read }

      mode    '0644'

      action  :create_if_missing
      only_if { File.open(bashrc_file).read.include?(USER_PS1_STANZA) }
    end

    file bashrc_file do
      content lazy {
        File.open(bashrc_file).read.split(USER_PS1_STANZA).join(
          [
            "# Default, templated PS1 was removed by Chef at #{Time.now}",
            *(USER_PS1_STANZA.lines.map { |line| '# ' + line.strip })
          ].join("\n")
        )
      }

      mode    '0644'

      action  :create
      only_if { File.open(bashrc_file).read.include?(USER_PS1_STANZA) }
    end
  end
end

COMMENT_PS1_PROMPT = '# PS1 prompt'
PATTERN_PS1_PROMPT = /#{COMMENT_PS1_PROMPT}$/

cookbook_file File.join('/etc/ps1') do
  source 'ps1'

  mode '0644'
end

ruby_block 'Add PS1 script to .bashrc' do
  block do
    file = Chef::Util::FileEdit.new('/etc/bash.bashrc')

    config_line = "[[ -s /etc/ps1 ]] && source /etc/ps1 #{COMMENT_PS1_PROMPT}"
    file.search_file_replace_line(PATTERN_PS1_PROMPT, config_line)
    file.insert_line_if_no_match(PATTERN_PS1_PROMPT, config_line)

    file.write_file
  end
end

apt_package 'vim' do
  action :install
end

cookbook_file File.join(operator_home, '.vimrc') do
  source '.vimrc'

  mode '0644'
end

directory File.join(operator_home, '.vim') do
  mode '0755'
end

directory File.join(operator_home, '.vim', 'colors') do
  mode '0755'
end

cookbook_file File.join(operator_home, '.vim', 'colors', 'wombat256mod.vim') do
  source 'wombat256mod.vim'

  mode '0644'
end
