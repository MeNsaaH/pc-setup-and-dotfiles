# MeNsaaH's dotfiles
A collection of my dotfiles on Ubuntu bootstrapped using [YADM](https://yadm.io)

prerequisites
-------------

- YADM
 ```
 sudo apt install yadm
 ```

install
-------
- Create .yadm.conf file at $HOME containing the following variables
```conf
GIT_USER_EMAIL=XXXX
GIT_USER_NAME=XXXXX
GIT_SIGNING_KEY=XXXX
```

- Clone repo

```bash
# Replace git url with your fork
# NOTE: It is important that you clone to ~/dotfiles
yadm clone --bootstrap https://github.com/mensaah/dotfiles.git
```


Todo
----
- [ ] Auto Setup Theme (Gnome-tweaks, dash to panel extensions)
- [ ] nvm/node
- [ ] go
- [ ] Python and python dev tools (install Poetry, pipenv, virtualenvwrapper)
- [ ] Fonts
- [ ] Add conditional installation from conf variable (INSTALL_VIM=1, INSTALL_TMUX=0)

