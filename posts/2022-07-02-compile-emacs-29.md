```
$ git clone -b master git://git.sv.gnu.org/emacs.git emacs.git
$ cd emacs.git/
$ sudo apt install autoconf libjansson-dev libxpm-dev libgif-dev gnutls-dev libgccjit-11-dev libgtk-3-dev texinfo
$ ./autogen.sh
$ ./configure CFLAGS=-no-pie --prefix=/usr/local/xstow/emacs-29.0.50 --with-modules --with-native-compilation
$ make
$ sudo make install
$ sudo apt install xstow
$ cd /usr/local/xstow
$ sudo xstow emacs-29.0.50
```
