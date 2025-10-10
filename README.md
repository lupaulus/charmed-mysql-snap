# MySQL Snap
[![Release to Snap Store](https://github.com/canonical/charmed-mysql-snap/actions/workflows/release.yaml/badge.svg)](https://github.com/canonical/charmed-mysql-snap/actions/workflows/release.yaml)

This repository contains the packaging metadata for creating a snap of MySQL built from the official Ubuntu repositories.  For more information on snaps, visit [snapcraft.io](https://snapcraft.io/). 

## Architecture Support
This snap supports multiple architectures:
- **amd64** (x86_64)
- **arm64** (aarch64)
- **s390x**

The snap will automatically build and install for your system architecture.

## Installing the Snap
The snap can be installed directly from the Snap Store.  Follow the link below for more information.
<br>

[![Get it from the Snap Store](https://snapcraft.io/static/images/badges/en/snap-store-black.svg)](https://snapcraft.io/mysql-server)


## Building the Snap
The steps outlined below are based on the assumption that you are building the snap with the latest LTS of Ubuntu.  If you are using another version of Ubuntu or another operating system, the process may be different.

### Clone Repository
```bash
git clone git@github.com:canonical/mysql-server-snap.git
cd mysql-server-snap
```

### Installing and Configuring Prerequisites
```bash
sudo snap install snapcraft
sudo snap install lxd
sudo lxd init --auto
```

### Packing and Installing the Snap
In order to properly test the confinement of the snap, we must install it using the `--dangerous` flag,
instead of the `--devmode` one. See snap [installation modes](https://snapcraft.io/docs/install-modes).

```bash
snapcraft pack
sudo snap install ./charmed-mysql*.snap --dangerous
```

## Using PHPMyAdmin
This snap includes PHPMyAdmin for easy database administration through a web interface.

### Starting PHPMyAdmin
```bash
# Start the MySQL daemon first
sudo snap start charmed-mysql.mysqld

# Then start PHPMyAdmin
sudo snap start charmed-mysql.phpmyadmin
```

### Accessing PHPMyAdmin
By default, PHPMyAdmin is accessible at:
```
http://localhost:8080
```

You can customize the port by setting the `PHPMYADMIN_PORT` environment variable in the snap service.

### Logging In
Use your MySQL credentials to log in. The snap is configured to connect to the local MySQL instance via Unix socket at `/var/snap/charmed-mysql/common/var/run/mysqld/mysqld.sock`.

### Stopping PHPMyAdmin
```bash
sudo snap stop charmed-mysql.phpmyadmin
```

## License
The MySQL Server Snap is free software, distributed under the Apache
Software License, version 2.0. See
[LICENSE](https://github.com/canonical/mysql-server-snap/blob/8.0/edge/licenses)
for more information.
