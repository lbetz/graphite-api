#! /usr/bin/env bash
set -xe

export VERSION=1.1.3

apt-get -y install build-essential python3-dev python3-pip python3-virtualenv virtualenvwrapper libffi-dev

rm -rf build

mkdir -p build/usr/share/python
virtualenv --python=/usr/bin/python3 build/usr/share/python/graphite
#build/usr/share/python/graphite/bin/pip install -U pip distribute
#build/usr/share/python/graphite/bin/pip uninstall -y distribute

build/usr/share/python/graphite/bin/pip install graphite-api[sentry,cyanite] gunicorn virtualenv-tools3

find build ! -perm -a+r -exec chmod a+r {} \;

cd build/usr/share/python/graphite
sed -i "s/'\/bin\/python'/\('\/bin\/python','\/bin\/python3'\)/g" lib/python3.7/site-packages/virtualenv_tools.py
./bin/virtualenv-tools --update-path /usr/share/python/graphite
cd -

find build -iname *.pyc -exec rm {} \;
find build -iname *.pyo -exec rm {} \;

cp -a conf/etc build

fpm \
	-t deb -s dir -C build -n graphite-api -v $VERSION \
	--iteration `date +%s` \
	--deb-default conf/etc/default/graphite-api \
	--deb-init conf/etc/init.d/graphite-api \
	--deb-user root \
	--deb-group root \
	--config-files /etc/graphite-api.yaml \
	--config-files /etc/init.d/graphite-api \
	--config-files /etc/default/graphite-api \
	-d libcairo2 \
	-d "libffi5 | libffi6" \
	-d adduser \
	-d python \
	--after-install conf/post-install \
	--before-remove conf/pre-remove \
	--after-remove conf/post-remove \
	--url https://github.com/brutasse/graphite-api \
	--description 'Graphite-web, without the interface. Just the rendering HTTP API.' \
	--license 'Apache 2.0' \
	.
