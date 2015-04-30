# Requirements (package names on CentOS)
#
# perl perl-Config-IniFiles jq sqlite3 perl(DBI) perl(DBD::SQLite)
# util-linux-ng gnutls-utils pwgen ed
#
# sqlite3 need more latest version or we cannot access the sqlites
# owned by Firefox.

# Miscellaneous functions.
function wait_a_while {
    sleep 1
}

function is_X_ok {
    [ "${DISPLAY}"x = x ] && false || true
}

# Functions to control /dev/tty.
# If need we will give more functions.
function is_tty {
    tty -s && [ "${EMACS}" != "t" ]
}

function disable_show_input_for_tty {
    if [ "${EMACS}" != "t" ];then
        is_tty && stty -echo
    fi
}

function enable_show_input_for_tty {
    if [ "${EMACS}" != "t" ];then
        is_tty && stty echo
    fi
}

# Functions to get xul/Firefox pathes
function get_current_user_name {
    id -u -n
}

function get_home_dir {
    (
        name=$(get_current_user_name)
        perl -E "\$s=(getpwnam(q{${name}}))[7];say \$s"
    )
}

function is_firefox_db_dir {
    (
        section="$1"
        home=$(get_home_dir)
        if [ -e ${home}/.mozilla/firefox/profiles.ini ];then
            true
        else
            false
        fi
    )
}

function remove_firefox_db_dir {
    home_dir=$(get_home_dir)
    
    if [ -d ${home_dir}/.cache/mozilla/firefox ];then
        rm -rf ${home_dir}/.cache/mozilla/firefox
    fi

    if is_firefox_db_dir;then
        rm -rf ${home_dir}/.mozilla/firefox
    fi
}

function get_firefox_db_dir {
    (
        section="$1"
        home=$(get_home_dir)
        if [ -e ${home}/.mozilla/firefox/profiles.ini ];then
            dir=$(perl -E "
              use Config::IniFiles;
              say Config::IniFiles
              ->new(-file => q{${home}/.mozilla/firefox/profiles.ini})
              ->val(q{${section:-Profile0}}, q{Path});")
            dir=${home}/.mozilla/firefox/${dir}
        else
            echo "Failed to get the home dir of firefox" >&2
            exit 1
        fi
        echo $dir
    )
}

# Functions to init Firefox
function make_sure_firefox_db_dir {
    (
        home=$(get_home_dir)
        if [ ! -e ${home}/.mozilla/firefox/profiles.ini ];then            
            open_firefox_win
            close_firefox_win
        fi
        for ((i=0;i<120;i++));do
            if [ -e ${home}/.mozilla/firefox/profiles.ini ];then
                dir=$(get_firefox_db_dir)
                if [ -e ${dir}/prefs.js -a -e ${dir}/webappsstore.sqlite ];then
                    wait_a_while
                    break
                fi
            fi
            wait_a_while
        done
        get_firefox_db_dir
    )
}

function set_firefox_user_pref {
    (
        key=${1:-};
        value=${2:-}

        if [ "${key}"x = x ];then
            echo "Need at least one argument" >&2
            exit 1
        fi
        [ "${value}"x = x ] && value='false'

        tempfile=$(mktemp)
        dir=$(make_sure_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"${key}\"," ${file} > ${tempfile}
        cat ${tempfile} > ${file}
        echo "user_pref(\"${key}\", $value);" >> ${file}
        rm -f ${tempfile}
    )
}

function set_firefox_user_pref_in_mass {
    (
        value=${1:-};
        if [ "${value}"x = x ];then
            echo "Need at least one argument" >&2
            exit 1
        fi
        shift
        cmds=$(mktemp)
        file=$(make_sure_firefox_db_dir)/prefs.js
        {
            for key in $@;do
                echo "g/user_pref(\"${key}\",/d"
            done
        } > ${cmds}
        echo -n -e '$a\n' >> ${cmds}
        {
            for key in $@;do
                echo "user_pref(\"${key}\", $value);"
            done
        } >> ${cmds}
        echo -n -e '.\nw\nq\n' >> ${cmds}

        ed -s ${file} < ${cmds}
        
        rm -f ${cmds}
    )
}


function set_firefox_no_session_restore {
    (
        tempfile=$(mktemp)
        dir=$(make_sure_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"browser.sessionstore.enabled\"," ${file} \
            | grep -v "user_pref(\"browser.sessionstore.resume_from_crash\"," > ${tempfile}
        cat ${tempfile} > ${file}
        for str in enabled resume_from_crash;do
            echo "user_pref(\"browser.sessionstore.${str}\", false);" >> ${file}
        done
        rm -f ${tempfile}
    )
}

function set_firefox_support_krb5_auth {
    (
        site=$1
        tempfile=$(mktemp)
        dir=$(make_sure_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"network.negotiate-auth.trusted-uris\"," ${file} \
            | grep -v "user_pref(\"network.negotiate-auth.delegation-uris\"," > ${tempfile}
        cat ${tempfile} > ${file}
        for str in trusted-uris delegation-uris;do
            echo "user_pref(\"network.negotiate-auth.${str}\", \"${site:-https://}\");" >> ${file}
        done
        rm -f ${tempfile}
    )
}

function set_firefox_no_password_remember {
    (
        tempfile=$(mktemp)
        dir=$(make_sure_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"signon.rememberSignons\"," ${file} > ${tempfile}
        cat ${tempfile} > ${file}
        echo "user_pref(\"signon.rememberSignons\", false);" >> ${file}
        rm -f ${tempfile}
    )
}

function set_firefox {
    (
        firefox_prefs_boolean_false='
            security.csp.enable
            dom.disable_open_during_load
            browser.sessionstore.restore_on_demand
            browser.tabs.warnOnClose
            browser.tabs.warnOnOpen
            browser.sessionstore.resume_from_crash
            signon.rememberSignons
            dom.disable_window_move_resize
            dom.disable_window_status_change
            update_notifications.enabled
            security.warn_entering_secure
            security.warn_entering_weak
            toolkit.telemetry.enabled
            datareporting.healthreport.service.enabled
            datareporting.healthreport.uploadEnabled
            datareporting.healthreport.service.firstRun
            datareporting.healthreport.logging.consoleEnabled
            datareporting.policy.dataSubmissionEnabled
            datareporting.policy.dataSubmissionPolicyAccepted'
        
        firefox_prefs_boolean_true='
            javascript.enabled
            browser.tabs.loadDivertedInBackground
            browser.cache.memory.enable
            dom.allow_scripts_to_close_windows
            dom.disable_image_src_set
            dom.disable_window_flip
            dom.storage.enabled
            toolkit.telemetry.rejected'
        
        set_firefox_user_pref_in_mass 'false' ${firefox_prefs_boolean_false}
        set_firefox_user_pref_in_mass 'true' ${firefox_prefs_boolean_true}
#        set_firefox_user_pref 'browser.sessionstore.max_tabs_undo' 10
#        set_firefox_user_pref 'browser.sessionstore.max_windows_undo' 3
        set_firefox_user_pref 'toolkit.storage.synchronous' 1
        set_firefox_user_pref 'browser.link.open_newwindow' 3
        set_firefox_user_pref 'dom.max_script_run_time' 60
        set_firefox_user_pref 'dom.popup_maximum' 60
        #        set_firefox_user_pref 'dom.storage.default_quota' 10240
        set_firefox_user_pref 'browser.startup.page' 1
        set_firefox_user_pref 'toolkit.telemetry.prompted' 2
        set_firefox_user_pref 'datareporting.policy.dataSubmissionPolicyResponseType' '"accepted-info-bar-dismissed"'
    )
}

# Functions to control firefox
function open_firefox_win {
    (
        uri=$1

        is_firefox_open && close_firefox_win
        
        setsid firefox --new-instance ${uri:-} &

        for ((i = 0; i < 300; i++));do
            if is_firefox_open;then
                if [ -e "$(get_firefox_db_dir)/webappsstore.sqlite" ];then
                    break
                else
                    wait_a_while
                fi
            else
                wait_a_while
            fi
        done
    )
}

function open_firefox_tab {
    (
        uri=$1

        if ! is_X_ok;then
            echo 'Firefox need an X server' >&2
            exit 1
        fi    
        
        { firefox --new-tab "${uri:-http://redhat.com}"; } 2>&1 > /dev/null
        wait_a_while
    )
}

function is_firefox_open {
    (
        if ! is_X_ok;then
            return 1
        fi

        is_firefox_db_dir || return 1
        
        dir=$(get_firefox_db_dir)
        
        if [ "${dir}"x = x ];then
            return 1
        else
            if [ -e ${dir}/.parentlock ];then
                fuser -s ${dir}/.parentlock
            else
                return 1
            fi
        fi
    )
}

function close_firefox_win {
    (
        dir=$(get_firefox_db_dir)
        lock="${dir}/.parentlock"

        setsid fuser -s -k ${lock}
        wait_a_while;wait_a_while
        
        if [ -e "${lock}" ];then
            for ((i=0;i<10;i++));do
                if [ -e "${lock}" ];then
                    is_firefox_open && setsid fuser -s -k ${lock} \
                        || break
                    wait_a_while
                    is_firefox_open || break
                else
                    break
                fi
            done
        fi
        
        if [ -e "${lock}" ];then
            if fuser -s "${lock}";then
                echo 'Failed to close Firefox' >&2
                exit 1
            else
                rm -f ${lock}
            fi
        fi
    )
}

# Functions to control SSL/TSL certificates
function get_ssl_cert_from_remote {
    (
        host=$1
        port=$2
        
        if [ -z "${host}" ];then
            echo 'Function get_ssl_cert_from_remote need at least one argument' >&2
            echo 'Usage: get_ssl_cert_from_remote host [port]' >&2
            exit 1
        fi
        
        gnutls-cli -p ${port:-443} --insecure --print-cert ${host} < /dev/null \
            | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
    )
}

function get_nickname_from_cert {
    cert=$1
    
    if [ -z "${cert}" ];then
        echo 'Function get_nickname_from_cert need an argument' >&2
        echo 'Usage: get_nickname_from_cert path_to_certification' >&2
        exit 1
    fi
    
    openssl x509 -in ${cert} -noout -subject | cut -s -d'/' -f 7 | cut -s -d'=' -f 2
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
            echo 'Function add_cert_to_db need at least 2 arguments' >&2
            echo 'Usage: add_cert_to_db nickname certification [trust_type]' >&2
            exit 1
        fi
        
        dir=$(get_firefox_db_dir)
        certutil -A -t ${trust_type:-P} -n "${nickname}" -d ${dir} -i "${certification}"
    )
}

function remove_cert_from_db {
    (
        nickname=$1
        
        if [ -z "${nickname}" ];then
            echo 'Function remove_cert_from_db need 1 arguments' >&2
            exit 1
        fi
        
        dir=$(get_firefox_db_dir)
        
        certutil -D -n "${nickname}" -d ${dir}
    )
}

function add_cert_for_each_host_of {
    cf=$(mktemp)
    
    for p in $@;do
        host=$(echo ${p} | cut -d : -f 1)
        port=$(echo ${p} | cut -s -d : -f 2)
        nickname=$(echo ${p} | cut -s -d : -f 3)
        
        get_ssl_cert_from_remote ${host} ${port:-443} > $cf
        
        is_cert_in_db ${nickname:-${host}} \
            || add_cert_to_db ${nickname:-${host}} ${cf}
    done
    
    rm -f $cf
}

function update_cert_for_each_host_of {
    cf=$(mktemp)
    
    for p in $@;do
        host=$(echo ${p} | cut -d : -f 1)
        port=$(echo ${p} | cut -s -d : -f 2)
        nickname=$(echo ${p} | cut -s -d : -f 3)

        get_ssl_cert_from_remote ${host} ${port:-443} > $cf
        
        is_cert_in_db ${nickname:-${host}} \
            && remove_cert_from_db ${nickname:-${host}}
        
        add_cert_to_db ${nickname:-${host}} ${cf}
    done
    
    rm -f $cf
}

# Functions to read/write localStorage/sessionStorage.
# https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage
# {scope, key} must be unique in the localStorage/sessionStorage
function quote_str_for_sqlite3 {
    (
        str="$1"
        tmp_db=$(mktemp)
        
        perl -E "
            use DBI;
            my \$dbh = DBI->connect(q[dbi:SQLite:dbname=${tmp_db}],
                q{}, q{}, { RaiseError => 1, AutoCommit => 0 });
            say \$dbh->quote(q{${str}});"
        
        rm -f ${tmp_db}
    )
}

function get_path_to_localstorage {
    (
        dir=$(make_sure_firefox_db_dir)
        
        if [ -r "${dir}" ];then
            echo "${dir}/webappsstore.sqlite"
        else
            echo "Failed to get the path to localstorage database" >&2
            exit 1
        fi
    )
}

function read_from_localstorage {
    (
        key="$1"
        scope="$2"
        
        if [ "${key}"x = x ];then
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db=$(get_path_to_localstorage)
        tbl=webappsstore2

        key=$(quote_str_for_sqlite3 "${key}")
        if [ "${scope}"x != x ];then
            scope=$(quote_str_for_sqlite3 "${scope}")
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi
        select_clause="SELECT * FROM ${tbl} ${where_clause}"
        
        for ((i=0;i<60;i++));do
            if sqlite3 -batch -noheader ${db} "${select_clause}" 2> /dev/null;then
                break
            else
                if [ $i -eq 59 ];then
                    echo 'Failed to read/write sqlite' >&2
                    exit 1
                fi
                wait_a_while
            fi
        done
    )
}

function read_value_from_localstorage {
    (
        key="$1"
        scope="$2"
        
        if [ "${key}"x = x ];then
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db=$(get_path_to_localstorage)
        tbl=webappsstore2

        key=$(quote_str_for_sqlite3 "${key}")
        if [ "${scope}"x != x ];then
            scope=$(quote_str_for_sqlite3 "${scope}")
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi
        select_clause="SELECT value FROM ${tbl} ${where_clause}"
        
        for ((i=0;i<60;i++));do
            if sqlite3 -batch -noheader ${db} "${select_clause}" 2> /dev/null;then
                break
            else
                if [ $i -eq 59 ];then
                    echo 'Failed to read/write sqlite' >&2
                    exit 1
                fi
                wait_a_while
            fi
        done
    )
}

function read_secure_from_localstorage {
    (
        key="$1"
        scope="$2"
        
        if [ "${key}"x = x ];then
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db=$(get_path_to_localstorage)
        tbl=webappsstore2

        key=$(quote_str_for_sqlite3 "${key}")
        
        if [ "${scope}"x != x ];then
            scope=$(quote_str_for_sqlite3 "${scope}")
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi
        
        select_clause="SELECT secure FROM ${tbl} ${where_clause}"

        for ((i=0;i<60;i++));do
            if sqlite3 -batch -noheader ${db} "${select_clause}" 2> /dev/null;then
                break
            else
                if [ $i -eq 59 ];then
                    echo 'Failed to read/write sqlite' >&2
                    exit 1
                fi
                wait_a_while
            fi
        done
    )
}

function read_owner_from_localstorage {
    (
        key="$1"
        scope="$2"

        if [ "${key}"x = x ];then
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db=$(get_path_to_localstorage)
        tbl=webappsstore2

        key=$(quote_str_for_sqlite3 "${key}")

        if [ "${scope}"x != x ];then
            scope=$(quote_str_for_sqlite3 "${scope}")
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi
        
        select_clause="SELECT owner FROM ${tbl} ${where_clause}"

        for ((i=0;i<60;i++));do
            if sqlite3 -batch -noheader ${db} "${select_clause}" 2> /dev/null;then
                break
            else
                if [ $i -eq 59 ];then
                    echo 'Failed to read/write sqlite' >&2
                    exit 1
                fi
                wait_a_while
            fi
        done
    )
}

function delete_from_localstorage {
    (
        key="$1"
        scope="$2"
        if [ "${key}"x = x ];then
            echo "delete_from_localstorage need at least an argument as follows" >&2
            echo "delete_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db="$(get_path_to_localstorage)"
        tbl='webappsstore2'

        key=$(quote_str_for_sqlite3 "${key}")
        
        if [ "${scope}"x != x ];then
            scope=$(quote_str_for_sqlite3 "${scope}")
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi

        for ((i=0;i<60;i++));do
            if sqlite3 -batch ${db} "DELETE FROM ${tbl} ${where_clause}" 2> /dev/null;then
                break
            else
                if [ $i -eq 59 ];then
                    echo 'Failed to read/write sqlite' >&2
                    exit 1
                fi
                wait_a_while
            fi
        done
    )
}

# We will first delete, then write.
# Here value could be a file path, then we will read it
function write_to_localstorage {
    (
        scope="$1"
        key="$2"
        value="$3"
        secure="$4"
        owner="$5"
        if [ "${scope}"x = x -o "${key}"x = x -o "${value}x" = x ];then
            echo "write_to_localstorage need at least three arguments as follows" >&2
            echo "write_to_localstorage scope key value [secure] [owner]" >&2
            exit 1
        fi

        if [ -r "${value}" -a -f "${value}" ];then
            file="${value}"
            if eval "jq -M -c '.' \"${file}\" > /dev/null 2>&1";then
                value=$(jq -M -c '.' "${file}")
            else
                echo "jq cannnot parse the file $file" >&2
                exit 1
            fi
        fi

        if eval "jq -n -M -c '@sh | ${value}' > /dev/null 2>&1";then
            value=$(jq -n -M -c "@sh | ${value}")
        else
            echo "write_to_localstorage: cannot covert the value to JSON" >&2
            echo $value >&2
            exit 1
        fi

        scope=$(quote_str_for_sqlite3 "${scope}")
        key=$(quote_str_for_sqlite3 "${key}")
        value=$(quote_str_for_sqlite3 "${value}")

        if [ "${secure}"x != x ];then
            secure=$(quote_str_for_sqlite3 "${secure}")
        fi

        if [ "${owner}"x != x ];then
            owner=$(quote_str_for_sqlite3 "${owner}")
        fi
        
        db="$(get_path_to_localstorage)"
        tbl='webappsstore2'
        
        delete_clause="DELETE FROM ${tbl} WHERE scope = ${scope} AND key = ${key}"
        insert_clause="INSERT INTO ${tbl} (scope, key, value, secure, owner)"
        insert_clause="${insert_clause} VALUES"
        insert_clause="${insert_clause} (${scope}, $key, $value, ${secure:-''}, ${owner:-''})"

        for ((i=0;i<60;i++));do
            if sqlite3 ${db} "${delete_clause};${insert_clause}" 2> /dev/null;then
                break
            else
                if [ $i -eq 59 ];then
                    echo 'Failed to read/write sqlite' >&2
                    exit 1
                fi
                wait_a_while
            fi
        done
    )
}

# Firefox need an X window. We could try VNC server for it if need.
function setting_vnc_password {
    (
        passwd=$1
        dir=$(get_home_dir)
        # passwd=$(pwgen -c -n -s 32 1)
        [ -d ${dir}/.vnc ] || mkdir ${dir}/.vnc
        if ! [ -e ${dir}/.vnc/passwd ];then
            touch  ${dir}/.vnc/passwd
            chmod 600 ${dir}/.vnc/passwd
        fi

        echo ${passwd:-redhat} | vncpasswd -f > ${dir}/.vnc/passwd
    )
}

# Functions of message bus
function produce_control_page {
    (
        cat > control.html <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Automation</title>
  </head>
  <body>
    <h3>Automation</h3>
    <p>Just a demo.</p>
  </body>
</html>
EOF
cat > tunnel.html <<EOF
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Automation</title>
  </head>
  <body>
    <h3>Automation</h3>
    <p>Just a demo.</p>
  </body>
</html>
EOF
    )
}
