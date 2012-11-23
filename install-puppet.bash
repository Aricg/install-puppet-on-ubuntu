#!/bin/bash
CODENAME="$(cat /etc/lsb-release | grep CODENAME | cut -d'=' -f 2)"
PUPPETMASTER="$1"
ENVIRONMENT="development"
SYSINFO="$(cat /proc/version)"

if [[ "$SYSINFO" =~ "Ubuntu" ]]
	then
	      echo "Ubuntu Detected, Proceeding"
	else
	      echo "Unexpected OS exiting"
	      exit 1
fi

if [ "$1" = "" ]
	then
		echo "usage: "$0" puppet masters fqdn"
		echo
	exit 1
fi


#everything depends on this being downloaded.
GetRepo () {
wget http://apt.puppetlabs.com/puppetlabs-release-"$CODENAME".deb
}

GetRepo "$CODENAME"

#Adds the offical repo and installs preferred version of puppet
InstallPuppet () {
dpkg -i puppetlabs-release-"$CODENAME".deb
apt-get update 
apt-get -y --force-yes install puppet-common=2.7.19-1puppetlabs2 puppet=2.7.19-1puppetlabs2
sed -e s,no,yes,g -i /etc/default/puppet
}

if [ -e "puppetlabs-release-"$CODENAME".deb" ];
    then
        echo "repo sucsessfully downloaded"
    else
        echo "puppet repo was not downloaded, aborting"
        exit 1
fi


if  ! [[ "$(which puppet)" ]]
        then
                echo "Repo downloaded and puppet not yet installed.. installing Puppet"
#This calls the two defined actions above
                InstallPuppet "$CODENAME"
        else
                echo "puppet already installed, aborting"
        exit 1
fi


#Config Section
cat > /etc/puppet/puppet.conf <<DELIM
[main]
server="$PUPPETMASTER"
logdir=/var/log/puppet
vardir=/var/lib/puppet
ssldir=/var/lib/puppet/ssl
rundir=/var/run/puppet
factpath=$vardir/lib/facter
templatedir=$confdir/templates
 
[master]
#reports = store, http
ssl_client_header = SSL_CLIENT_S_DN
ssl_client_verify_header = SSL_CLIENT_VERIFY
 
[agent]
report = true
pluginsync=true
waitforcert = 120
environment="$ENVIRONMENT"
DELIM

cat > /etc/puppet/namespaceauth.conf <<DELIM
[puppetrunner]
allow "$PUPPETMASTER"
DELIM

cat > /etc/puppet/auth.conf <<DELIM
path /run
method save
allow "$PUPPETMASTER"
DELIM

/etc/init.d/puppet start

