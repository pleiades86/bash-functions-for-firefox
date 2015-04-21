# Firefox-as-Daemon

## Why we need run firefox as daemon?

Is [phantomjs](http://phantomjs.org/) not enough? No, it isn't.

-  phantomjs not support kerberos authentication.
-  other features that firefox support

## How to run firefox as daemon?

### Platform requires

This solution to run firefox as daemon, requires bash and an GUI system,  
so firefox could display and run. Hence it's better to try it on gnu/linux  
systems.  

We could try [KVM](http://www.linux-kvm.org) and [tigervnc](http://tigervnc.org/). Other vnc servers also works if they  
implement X that firefox need when it running.

### While, how can I inject my JavaScript codes into the HTTP responses?

Pls access [mod_triger](https://github.com/xning/mod_triger).

### How to deploy?

#### Install softwares

We use RHEL6/CentOS as examples.    

#####  Install vnc server

If need, pls run command as follows

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

    # run firefox, then kill it
    firefox
    . bash-functions-for-firefox/functions.sh
    setting_vnc_password 123456
    
##### Setting firefox

    set_firefox_no_session_restore
    set_firefox_no_password_remember
    # if need, setting kerberos authentication
    set_firefox_support_krb5_auth
    # For self-signed certification site, we need manully import certification file
    cf=$(mktemp)
    get_ssl_cert_from_remote server_dns_name server_port > $cf
    nickname=$(get_nickname_from_cert $cf)
    # Add the cert if it not in the db
    is_cert_in_db ${nickname} || add_cert_to_db ${nickname} ${cf}
    rm -f $cf
    
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
    
Setting kerberos authentication for a 'site'. If no site given, setting  
to 'https://'

    set_firefox_no_password_remember

    open_firefox_tab


### Control SSL certification files

    get_ssl_cert_from_remote server_dns_name port
    
Get certification files from remote server and output the certification  
file on the stdout 

    get_nickname_from_cert cert_file

Extract nickname from a certification file and output it on the stdout.

    is_cert_in_db nickname

Get a nickname as input and check whether certification file related  
with the nickname exists in the db

    add_cert_to_db nickname certfile [trust_type]

Add certification to the db

    remove_cert_from_db nickname

Remove certification file from db

### Functions to read/write [localStorage/sessionStorage](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage)

For the [localStorage/sessionStorage](https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage),
{scope, key} must be unique.  
And the value should be result of
[JavaScript](http://en.wikipedia.org/wiki/JavaScript)
[JSON](http://en.wikipedia.org/wiki/JSON)
[stringify](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify)
function.  
You can try the command [jq(1)]() to produce/parse such result.  

Pls take care that some sites don't use their DNS names as the scope.  
For example,
[github](https://github.com)'s scope is "moc.buhtig.:https:443".  
Hence to get the right scope,
we need some hack way.  
Just let your [JavaScript](http://en.wikipedia.org/wiki/JavaScript) codes write to the localStorage, then we read it.

#### 1. read\_*\_from\_localstorage key \[scope\]

     read_value_from_localstorage 'key' 'github.com.:https:443'

#### 2. write\_to\_localstorage scope key value \[secure\] \[owner\]

        jq -M -n -c '{key: {value: 1}}'
        write_to_localstorage 'github.com.:https:443' 'key' $(jq -M -n -c '{key: {value: 1}}')

#### 3. delete\_from\_localstorage key [scope]

    delete_from_localstorage 'key' 'github.com.:https:443'

### Control vncserver

    setting_vnc_password [passwd]


## Configuring Firefox

Usually to run Firefox from command-lines, we need setup the following  
configuations as need

For what the follow settings do, pls reference
[About:config entries](http://kb.mozillazine.org/About:config_entries)

### 1. Boolean settings

    security.csp.enable
    dom.disable_open_during_load
    browser.sessionstore.restore_on_demand
    browser.tabs.warnOnClose
    browser.tabs.warnOnOpen
    browser.sessionstore.enabled
    signon.rememberSignons
    browser.tabs.loadDivertedInBackground

### 2. Number/String settings

    network.negotiate-auth.trusted-uris
    network.negotiate-auth
    browser.link.open_newwindow
