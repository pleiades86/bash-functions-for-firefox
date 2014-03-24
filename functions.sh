#!/bin/bash
function wait_a_while {
    sleep 3
}

function get_current_user_name {
    id -u -n
}

function get_home_dir {
    (
        name=$(get_current_user_name)
        perl -E "\$s=(getpwnam(q{${name}}))[7];say \$s"
    )
}

function get_path_to_mozilla_xremote_client {
    (
        prog=''
        for dir in {/usr/lib,/usr/lib64}/firefox{,/xulrunner} {/usr/lib,/usr/lib64}/xulrunner-*;do
            if [ -d ${dir} ];then
                prog=${dir}/mozilla-xremote-client
                [ -x ${prog} ] && { echo ${prog};return 0; }
            fi
        done
        os=$(lsb_release --id | cut -d ':' -f 2)
        echo "Now do not support ${os}."
        echo "If you know the path of mozilla-xremote-client, pls send email to the maintainer."
        echo "Perhaps you can submit a patch."
        exit 1
    )
}

function get_firefox_db_dir {
    (
        section="$1"
        ret=0
        home=$(get_home_dir)
        if [ -e ${home}/.mozilla/firefox/profiles.ini ];then
            dir=$(perl -E "use Config::IniFiles;say Config::IniFiles->new(-file => q{${home}/.mozilla/firefox/profiles.ini})->val(q{${section:-Profile0}}, q{Path});")
            dir=${home}/.mozilla/firefox/${dir}
        else
            dir=''
            ret=1
        fi
        echo $dir
        return ${ret}
    )
}


function is_firefox_open {
    (
        dir=$(get_firefox_db_dir)
        fuser -s ${dir}/.parentlock
    )
}

function close_firefox_win {
    (
        dir=$(get_firefox_db_dir)
        fuser -s -k ${dir}/.parentlock && wait_a_while
    )
}

function set_firefox_no_session_restore {
    (
        tempfile=$(mktemp)
        dir=$(get_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"browser.sessionstore.enabled\"," ${file} | grep -v "user_pref(\"browser.sessionstore.resume_from_crash\"," > ${tempfile}
        cat ${tempfile} > ${file}
        for str in enabled resume_from_crash;do
            echo "user_pref(\"browser.sessionstore.${str}\", false);" >> ${file}
        done
        rm -f ${tempfile}
        wait_a_while
    )
}

function set_firefox_support_krb5_auth {
    (
        site=$1
        tempfile=$(mktemp)
        dir=$(get_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"network.negotiate-auth.trusted-uris\"," ${file} | grep -v "user_pref(\"network.negotiate-auth.delegation-uris\"," > ${tempfile}
        cat ${tempfile} > ${file}
        for str in trusted-uris delegation-uris;do
            echo "user_pref(\"network.negotiate-auth.${str}\", \"${site:-https://}\");" >> ${file}
        done
        rm -f ${tempfile}
        wait_a_while
    )
}

function set_firefox_no_password_remember {
    (
        tempfile=$(mktemp)
        dir=$(get_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"signon.rememberSignons\"," ${file} > ${tempfile}
        cat ${tempfile} > ${file}
        echo "user_pref(\"signon.rememberSignons\", false);" >> ${file}
        rm -f ${tempfile}
        wait_a_while
    )
}

function open_firefox_win {
    (
        uri=$1
        nohup firefox ${uri:-} &
        wait_a_while
    )
}

function open_firefox_tab {
    (
        uri=$1
        prog_full_path=$(get_path_to_mozilla_xremote_client)
        cd $(dirname ${prog_full_path})
        prog=$(basename ${prog_full_path})
        ./${prog} -a firefox "openURL(http://redhat.com, new-tab)"
        wait_a_while
        
    )
}

function get_ssl_cert_from_remote {
    (
        host=$1
        port=$2
        if [ -z "${host}" ];then
            echo 'Function get_ssl_cert_from_remote need at least one argument'
            echo 'Usage: get_ssl_cert_from_remote host [port]'
            exit 1
        fi
        tempfile=$(mktemp)
        openssl s_client -connect ${host}:${port:-443} </dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' >  ${tempfile} && cat ${tempfile}
        rm -f ${tempfile}
    )
}

function get_nickname_from_cert {
    cert=$1
    if [ -z "${cert}" ];then
        echo 'Function get_nickname_from_cert need an argument'
        echo 'Usage: get_nickname_from_cert path_to_certification'
    fi
    openssl x509 -in ${cert} -noout -subject | cut -d '/' -f 7 | cut -d '=' -f 2
}

function is_cert_in_db {
    (
        nickname=$1
        dir=$(get_firefox_db_dir)
        certutil -L -n "$nickname" -d ${dir} > /dev/null 2>&1
    )
}

function add_cert_to_db {
    (
        nickname=$1
        certification=$2
        trust_type=$3
        if [ -z "${nickname}" -o -z "${certification}" ];then
            echo 'Function add_cert_to_db need at least 2 arguments'
            echo 'Usage: add_cert_to_db nickname certification [trust_type]'
            exit 1
        fi
        dir=$(get_firefox_db_dir)
        certutil -A -t ${trust_type:-P} -n "${nickname}" -d ${dir} -i "${certification}"
        wait_a_while
    )
}

function remove_cert_from_db {
    (
        nickname=$1
        if [ -z "${nickname}" ];then
            echo 'Function remove_cert_from_db need 1 arguments'
            exit 1
        fi
        dir=$(get_firefox_db_dir)
        certutil -D -n "${nickname}" -d ${dir}
        wait_a_while
    )
}

function setting_vnc_password {
    (
        passwd=$1
        dir=$(get_home_dir)
        # passwd=$(pwgen -c -n -s 32 1)
        [ -d ${dir}/.vnc ] || mkdir ${dir}/.vnc
        [ -e ${dir}/.vnc/passwd ] || touch  ${dir}/.vnc/passwd && chmod 600 ${dir}/.vnc/passwd
        echo ${passwd:-redhat} | vncpasswd -f > ${dir}/.vnc/passwd
    )
}
