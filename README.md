# termux-ubuntu

To install, just curl the link and execute with bash: (installs 20.04 by default)
```
curl -sLO htts://raw.githubusercontent.com/mikl-ls/termux-ubuntu/master/ubuntu.sh
bash ubuntu.sh 
```
There are two flags in this script:

`-v` to specify the version, just like my Termux-Debian script

Supported versions are based on what the majority of users use:

  `16.04`,`18.04`, `19.10` and `20.04`
  
 `-u` to uninstall

To remove the errors at start: (this is a workaround, not a fix)

`touch ubuntu-fs/root/.hushlogin`

Made this script when I heard that Ubuntu 20.04 was released to the public
