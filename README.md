# Firefox-as-Daemon

## Why we need run firefox as daemon?

Is [phantomjs](http://phantomjs.org/) not enough? No, it isn't.

-  phantomjs not support kerberos authentication.
-  other features that firefox support

## How to run firefox as daemon?

### Platform requires

This solution to run firefox as daemon, requires bash and tigervnc    
so it's better to try it on gnu/linux systems.    

Other vnc servers also works if they implement X that firefox    
need when it running.

### While, how can I inject my JavaScript codes into the HTTP responses?

Pls access [mod_triger](https://github.com/xning/mod_triger).

### How to deploy?

#### Install softwares

We use RHEL6/CentOS as examples.    

#####  Install vnc server

    yum -y install tigervnc-server

##### Install firefox and tools to control it

    yum -y install firefox nss-tools perl-Config-IniFiles
    
##### Create a common user

    useradd pkger
    passwd pkger
    
##### Download bash functions, and now we run commands as a common user

    su - pkger
    mkdir bin && cd bin
    git clone https://github.com/xning/bash-functions-for-firefox.git
    
#### Configuring

##### Setting vnc server

    . bash-functions-for-firefox/functions.sh
    setting_vnc_password 123456
    
##### Setting firefox

    set_firefox_no_session_restore
    set_firefox_no_password_remember
    # if need, setting kerberos authentication
    set_firefox_support_krb5_auth
    # For self-signed certification site, we need manully import certification file
    cf=$(get_ssl_cert_from_remote server_dns_name server_port)
    nickname=$(get_nickname_from_cert)
    # Add the cert if it not in the db
    is_cert_in_db ${nickname} || add_cert_to_db ${nickname} ${tf}
    rm -f $tf
    
#### Script to start vncserver when machine boot and start firefox

##### Create firefox-as-daemon as follows

    #!/bin/bash
    cd $(dirname $0)
    . bash-functions-for-firefox/functions.sh
    # Here we assume we run on display :1
    vncserver -kill :1
    nohup vncserver -localhost -geometry 1024x768 -depth 24 & 
    wait_a_while
    export DISPLAY=:1
    open_firefox_win www.firefox.com

And add execution permission for this file

    chmod u+x firefox-as-daemon
    

##### Create a cron job as follows (we run as common user pkger now)

I tried the following setting on RHEL6/CentOS6. Pls make sure that    
firefox-as-daemon could be found in PATH or use its absolute path.

    @reboot firefox-as-daemon
    
## Functions in functions.sh

### Control firefox

    is_firefox_open

    close_firefox_win

    set_firefox_no_session_restore

    set_firefox_support_krb5_auth [site]
    
Setting kerberos authentication for a 'site'. If no site given, setting to 'https://'

    set_firefox_no_password_remember

    open_firefox_tab


### Control SSL certification files

    get_ssl_cert_from_remote server_dns_name port
    
Get certification files from remote server and output the certification file on the stdout 

    get_nickname_from_cert cert_file

Extract nickname from a certification file and output it on the stdout.

    is_cert_in_db nickname

Get a nickname as input and check whether certification file related with the nickname exists in the db

    add_cert_to_db nickname certfile [trust_type]

Add certification to the db

    remove_cert_from_db nickname

Remove certification file from db

### Control vncserver

    setting_vnc_password [passwd]

