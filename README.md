# Mullvad Split Tunneling

*A better split tunneling for Mullvad VPN on Linux, using Mullvad CLI and Bash*

**⚠️ you will need Mullvad installed ⚠️**

did this because i dont wanna use the other methods that are very shitty

is the excluded-apps file is empty, it will open for you in code
add the apps to the excluded-apps file (1 app, 1 line)

## Installation:

- Clone the repository:
  
```sh
git clone https://github.com/Soyoudv/mullvad-st.git && cd mullvad-st
```

- Install with the makefile:
  
```sh
make install
```

- Run with
  
```sh
mst
```

## Options:

`-h`

*help*

`-s`

*silenced mode*

`-a` + `(app name)`

*adds a given entry to the excluded-apps file*

*(can be added without closing the program with another terminal instance)*

*you will need brackets to add a program with spaces, and specify args:*

```sh
# for the program "Isolated Web Content"
mst -a pgr Isolated Web Content # this wont work
mst -a "pgr Isolated Web Content" # but this will
```

*Line must start with 'cmd' or 'prg' followed by the app name. see [excluded apps modes](#modes-for-excluded-apps)*

```sh
mst -a "cmd xonotic"
```

`-r` + `(app name)`

*removes a given entry to the excluded-apps file*

*(can be removed without closing the program with another terminal instance)**


`-l`

*show the excluded apps list*

`-e`

*open the excluded apps file*

*(can be modified without closing the program with another terminal instance)*

## Modes for excluded apps:

### prg

Stands for program, basically just excludes a program with matching name. (not case sensitive)

### cmd

Stands for Command, uses the full command line to exclude a process. Currently works like a grep, meaning that it will find all occurences, even if the command line is longer.
