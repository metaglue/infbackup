INSTALLING infbackup.pl
=======================

Infbackup is an open source Perl based Informatica Backup system released under the GNU GPL.

This document describes:

* System requirements for Informatica Backup
* Installation routine

Server system requirements
--------------------------

Infbackup requires a server with a Perl environment and an Informatica Client or Server. 

* Informatica Client v10.1.1 or
* Informatica Server v10.1.1
* Perl 5.16
 * Perl Module XML::Parser
 * Perl Module POSIX
 * Perl Module File::Basename
* enough space for the backup files

Installation
------------

If you have SSH access to your server,
this is the recommended way of setting up Infbackup:

* Uncompress the zip file on the Bin
  Directory of your server:
```
/opt/informatica/10.1.1/server/bin $ unzip infbackup.zip
```

* Important: If you use GIT to fetch the sources, use the following command:
```
git fetch
git checkout <TAG>
```
where TAG is something like ```10.1.1```

Installation: further steps
---------------------------

* Set environment variable INFA_DEFAULT_DOMAIN_USER
  with the user name which has sufficient rights to read the domain and repository data.
  The user administrator should not be used if possible.
  
* Set environment variable INFA_DEFAULT_DOMAIN_PASSWORD
  The password is stored encrypted in the environment.
  Use the Informatica program pmpasswd to encrypt the password.
    
* Set environment variable INFA_DEFAULT_DATABASE_PASSWORD
  The password is stored encrypted in the environment.
  Use the Informatica program pmpasswd to encrypt the password.

```
/opt/informatica/10.1.1/server/bin/pmpasswd 'password in clear text'
```

Program options
---------------

```
infbackup.pl   
   [-h  ] Display this help message and stop   
   [-v  ] Display version of this script.   
   [-un ] Domain / Repository User | or overwrite environment variable INFA_DEFAULT_DOMAIN_USER   
   [-rp ] Domain / Repository Password | or overwrite environment variable INFA_DEFAULT_DOMAIN_PASSWORD   
   [-dp ] Domain Database Password | or overwrite environment variable INFA_DEFAULT_DATABASE_PASSWORD   
```
