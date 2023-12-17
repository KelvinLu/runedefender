# runedefender

`runedefender` is a node based on a generic VPS (on an AMD64 platform), running
Ubuntu Server 22.04.

## Setup

1. Obtain a VPS running on AMD64 architecture.
2. Install Ubuntu Server onto the server.
3. Perform any necessary, basic setup.
    - e.g.; creating or modifying user accounts, configuring `sshd` setup ...
4. Update packages; `apt update`, `apt upgrade`.
5. Install Git, Ruby (`apt install git ruby`).
6. Install Chef (via the community distribution; "Cinc").
    - See `http://downloads.cinc.sh/files/stable/cinc`.
    - Install via `dpkg --install <.deb package file>`.
7. Run `cinc-solo`.
    - `cinc-solo --config ./solo.rb --json-attributes ./nodes/runedefender.json --node-name runedefender`.
    - `cinc-solo --config ./solo.rb --json-attributes ./nodes/runedefender.json --node-name runedefender --override-runlist "${run_list:?}"`.
