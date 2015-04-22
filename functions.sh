# Requirements (package names on CentOS)
# perl perl-Config-IniFiles jq sqlite3 perl(DBI) perl(DBD::SQLite)
# sqlite3 need more latest version or we cannot access the sqlites
# owned by Firefox.

# Functions to get xul/Firefox pathes
function wait_a_while {
    sleep 1
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

function get_firefox_db_dir {
    (
        section="$1"
        ret=0
        home=$(get_home_dir)
        if [ -e ${home}/.mozilla/firefox/profiles.ini ];then
            dir=$(perl -E "\
                    use Config::IniFiles;\
                    say Config::IniFiles->new(-file => q{${home}/.mozilla/firefox/profiles.ini})->val(q{${section:-Profile0}}, q{Path});")
            dir=${home}/.mozilla/firefox/${dir}
        else
            dir=''
            ret=1
        fi
        echo $dir
        return ${ret}
    )
}

function make_sure_firefox_db_dir {
    (
        dir=$(get_firefox_db_dir)
        if [ "${dir}"x = x ];then
            open_firefox_win
            wait_a_while
            close_firefox_win
            get_firefox_db_dir
        else
            echo $dir
        fi
        
        return $(true && echo $?)
    )
}

# Functions to control Firefox
function set_firefox_user_pref {
    (
        key=${1:-};
        value=${2:-}
        if [ "${key}"x = x ];then
            echo "Need at least one argument" >&2
            exit $(false || echo $?)
        fi
        [ "${value}"x = x ] && value='false'

        tempfile=$(mktemp)
        dir=$(get_firefox_db_dir)
        file=${dir}/prefs.js
        grep -v "user_pref(\"${key}\"," ${file} > ${tempfile}
        cat ${tempfile} > ${file}
        echo "user_pref(\"${key}\", $value);" >> ${file}
        rm -f ${tempfile}
        wait_a_while
    )
}

function set_firefox_user_pref_in_mass {
    (
        value=${1:-};
        if [ "${value}"x = x ];then
            echo "Need at least one argument" >&2
            exit $(false || echo $?)
        fi
        shift
        tempfile=$(mktemp)
        tempfile2=$(mktemp)
        dir=$(get_firefox_db_dir)
        file=${dir}/prefs.js
        cat ${file} > ${tempfile}
        for key in $@;do
            grep -v "user_pref(\"${key}\"," ${tempfile} > ${tempfile2}
            mv -f ${tempfile2} ${tempfile}
        done
        cat ${tempfile} > ${file}
        for key in $@;do
            echo "user_pref(\"${key}\", $value);" >> ${file}
        done
        rm -f ${tempfile} ${tempfile2}
        wait_a_while
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
        d=$(mktemp -d)
        o=$(pwd)
        cd $d
        is_firefox_open && close_firefox_win
        { nohup firefox --new-instance ${uri:-} & } 2>&1 > /dev/null
        for ((i = 0; i < 60; i++));do
            if is_firefox_open;then
                break
            else
                wait_a_while
            fi
        done
        rm -rf $d
        cd ${o}
    )
}

function open_firefox_tab {
    (
        uri=$1
        { firefox --new-tab "${uri:-http://redhat.com}"; } 2>&1 > /dev/null
        wait_a_while
    )
}

function is_firefox_open {
    (
        dir=$(get_firefox_db_dir)
        if [ "${dir}"x = x ];then
            return $(false || echo $?)
        else
            if [ -e ${dir}/.parentlock ];then
                fuser -s ${dir}/.parentlock
            else
                return $(false || echo $?)
            fi
        fi
    )
}

function close_firefox_win {
    (
        dir=$(get_firefox_db_dir)
        { fuser -s -k ${dir}/.parentlock && wait_a_while; } 2>&1 > /dev/null
        rm -f ${dir}/.parentlock
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
            exit $(false || echo $?)
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
            exit $(false || echo $?)
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
            echo 'Function remove_cert_from_db need 1 arguments' >&2
            exit $(false || echo $?)
        fi
        dir=$(get_firefox_db_dir)
        certutil -D -n "${nickname}" -d ${dir}
        wait_a_while
    )
}

# Functions to read/write localStorage/sessionStorage.
# https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage
# {scope, key} must be unique in the localStorage/sessionStorage
function quote_str_for_sqlite3 {
    (
        str="$1"
        tmp_db=$(mktemp)
        perl -E "\
              use DBI;\
              my \$dbh = DBI->connect(q[dbi:SQLite:dbname=${tmp_db}], \
                 q{}, q{}, { RaiseError => 1, AutoCommit => 0 });\
              say \$dbh->quote(q{${str}});\
        "
        rm -f ${tmp_db}
    )
}

function get_path_to_localstorage {
    (
        dir=$(make_sure_firefox_db_dir)
        dir="${dir}/webappsstore.sqlite"
        if [ -r "${dir}" ];then
            echo "${dir}"
            return $(true && echo $?)
        else
            echo ''
            return $(false || echo $?)
        fi
    )
}

function read_value_from_localstorage {
    (
        key="$1"
        scope="$2"
        
        if [ "${key}"x = x ];then
            echo "read_from_localstorage need at least an argument as the key"
            return $(false || echo $?)
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
        sqlite3 -batch -noheader ${db} "${select_clause}"
    )
}

function read_secure_from_localstorage {
    (
        key="$1"
        scope="$2"
        if [ "${key}"x = x ];then
            echo "read_from_localstorage need at least an argument as the key"
            return $(false || echo $?)
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
        sqlite3 -batch -noheader ${db} "${select_clause}"
    )
}

function read_owner_from_localstorage {
    (
        key="$1"
        scope="$2"
        if [ "${key}"x = x ];then
            echo "read_from_localstorage need at least an argument as the key"
            return $(false || echo $?)
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
        sqlite3 -batch -noheader ${db} "${select_clause}"
    )
}

function delete_from_localstorage {
    (
        key="$1"
        scope="$2"
        if [ "${key}"x = x ];then
            echo "delete_from_localstorage need at least an argument as follows"
            echo "delete_from_localstorage key [scope]"
            return $(false || echo $?)
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
        
        sqlite3 ${db} "DELETE FROM ${tbl} ${where_clause}"
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
            echo "write_to_localstorage need at least three arguments as follows"
            echo "write_to_localstorage scope key value [secure] [owner]"
            return $(false || echo $?)
        fi

        if [ -r "${value}" -a -f "${value}" ];then
            file="${value}"
            if eval "jq -M -c '.' \"${file}\" >/dev/null 2>&1";then
                value=$(jq -M -c '.' "${file}")
            else
                echo "jq cannnot parse the file $file" >&2
                exit $(false || echo $?)
            fi
        fi
        if eval "jq -n -M -c '@sh | ${value}' > /dev/null 2>&1";then
            value=$(jq -n -M -c "@sh | ${value}")
        else
            echo "write_to_localstorage: cannot covert the value to JSON" >&2
            echo $value >&2
            exit $(false || echo $?)
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
        
        insert_clause="INSERT INTO ${tbl} (scope, key, value, secure, owner) VALUES"
        sqlite3 ${db} "${delete_clause};${insert_clause} (${scope}, $key, $value, ${secure:-''}, ${owner:-''})"
    )
}

# Firefox need an X window. We could try VNC server for it if need.
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
