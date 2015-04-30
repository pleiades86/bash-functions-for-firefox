## Firefox-as-Daemon ##

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

    yum -y install tigervnc-server pwgen

or install [KVM](http://www.linux-kvm.org), pls reference

[KVM and CentOS-6](http://wiki.centos.org/HowTos/KVM).

##### Install firefox and tools to control it

    yum -y install firefox nss-tools ed

##### Install Perl modules and jq

    yum -y install perl-Config-IniFiles perl-DBI perl-DBD-SQLite jq

##### Install util-linux, gnutls-utils, and openssl

    yum -y install util-linux-ng gnutls-utils openssl

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

If need, set VNC password

    setting_vnc_password 123456
    
##### Setting firefox

    set_firefox
    # if need, setting kerberos authentication
    set_firefox_support_krb5_auth kerberos_auth_domain_in_lowcase
    # For self-signed certification site, we need manully import certification file.
    # You can avoid the port and nickname parts of the arguments
    # in the following line, then we will use their default values.
    # The default value of port is 443.
    # The default value of nickname is the host name.
    add_cert_for_each_host_of hostname1:port1:nickname1 hostname2:port2:nickname2 ...

    
#### Script to start vncserver when machine boot and start firefox

##### Create firefox-as-daemon as follows

    #!/bin/bash
    cd $(dirname $0)
    . bash-functions-for-firefox/functions.sh
    # Here we assume we run on display :1
    vncserver -kill :1
    nohup vncserver -localhost -geometry 1024x768 -depth 24 & 
    wait_a_while
    export DISPLAY=:1.0
    open_firefox_win www.firefox.com

If we use a KVM machine for the daemon, we just do as following

    #!/bin/bash
    cd $(dirname $0)
    . bash-functions-for-firefox/functions.sh
    export DISPLAY=:0.0
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

    set_firefox

    set_firefox_support_krb5_auth [site]

    open_firefox_win
    
Setting kerberos authentication for a 'site'. If no site given, setting  
to 'https://'

    set_firefox_no_password_remember

    open_firefox_tab


### Control SSL certification files

    get_ssl_cert_from_remote server_dns_name port
    
Get certification files from remote server and output the certification  
file on the stdout 

    is_cert_in_db nickname

Get a nickname as input and check whether certification file related  
with the nickname exists in the db

    add_cert_to_db nickname certfile [trust_type]

Add certification to the db

    remove_cert_from_db nickname

Remove certification file from db

     # If the nickname have existed, skip
     add_cert_for_each_host_of hostname1:port1:nickname1 hostname2:port2:nickname2 ...
     # If the nickname have existed, remove it, then add.
     update_cert_for_each_host_of hostname1:port1:nickname1 hostname2:port2:nickname2 ...

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

The * could be 'value', 'secure', or 'owner'.

     read_value_from_localstorage 'key' 'github.com.:https:443'

#### 2. write\_to\_localstorage scope key value \[secure\] \[owner\]

        jq -M -n -c '{key: {value: 1}}'
        write_to_localstorage 'github.com.:https:443' 'key' $(jq -M -n -c '{key: {value: 1}}')

#### 3. delete\_from\_localstorage key [scope]

    delete_from_localstorage 'key' 'github.com.:https:443'

### Control vncserver

It seems that [KVM](http://www.linux-kvm.org) is better.

    setting_vnc_password [passwd]


## Configuring Firefox

Usually to run Firefox from command-lines, we need setup the following  
configuations as need

For what the follow settings do, pls reference
[About:config entries](http://kb.mozillazine.org/About:config_entries)

### 1. Boolean settings

    security.csp.enable
    browser.sessionstore.restore_on_demand
    browser.tabs.warnOnClose
    browser.tabs.warnOnOpen
    browser.tabs.loadDivertedInBackground
    browser.cache.memory.enable
    signon.rememberSignons
    dom.disable_open_during_load
    dom.allow_scripts_to_close_windows
    dom.disable_window_move_resize
    dom.disable_window_status_change
    dom.disable_image_src_set
    dom.disable_window_flip
    update_notifications.enabled
    security.warn_entering_secure
    security.warn_entering_weak
    toolkit.telemetry.rejected
    toolkit.telemetry.enabled
    datareporting.healthreport.service.enabled
    datareporting.healthreport.uploadEnabled
    datareporting.healthreport.service.firstRun
    datareporting.healthreport.service.firstRun
    datareporting.healthreport.logging.consoleEnabled
    datareporting.policy.dataSubmissionEnabled
    datareporting.policy.dataSubmissionPolicyAccepted
            
### 2. Number/String settings

    javascript.enabled
    network.negotiate-auth.trusted-uris
    network.negotiate-auth
    browser.link.open_newwindow
    browser.startup.homepage
    browser.startup.page
    dom.max_script_run_time
    dom.popup_maximum
    toolkit.storage.synchronous
    browser.sessionstore.max_tabs_undo
    browser.sessionstore.max_windows_undo
    set_firefox_user_pref
    datareporting.policy.dataSubmissionPolicyResponseType

## About HTML5 features of Firefox

### 1. About the SorageEvent

Pls visit here
[Using the Web Storage API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Storage_API/Using_the_Web_Storage_API)
and
[Web Storage](http://www.w3.org/TR/webstorage/#event-storage).
