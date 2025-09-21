# MeNsaaH's dotfiles

A collection of my dotfiles and system setups on Ubuntu and MacOS as Ansible Roles

prerequisites
-------------

- Ensure Python 3 is installed

- ansible
```
 pip3 install ansible
```

- Install ansible requirements 
```
ansible-galaxy install -r requirements.yml
```

- Generate SSH Key and GPG Key and add to Github account

- Run playbook
```
ansible-playbook main.yml -i inventory --ask-become-pass
```

Todo
----
- [ ] Ubuntu: Auto Setup Theme (Gnome-tweaks, dash to panel extensions)
- [ ] Ubuntu: Gogh for theme selection

