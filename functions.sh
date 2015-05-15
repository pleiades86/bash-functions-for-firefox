# Requirements (package names on CentOS)
#
# perl perl-Config-IniFiles jq sqlite3 perl(DBI) perl(DBD::SQLite)
# util-linux-ng gnutls-utils pwgen ed libselinux-utils nc
#
# sqlite3 need more latest version or we cannot access the sqlites
# owned by Firefox.

# Miscellaneous functions.
function wait_a_while {
    sleep 1
}

function wait_as_long_as_until {
    (
        time_out=$1
        interval=$2
        cond_exp=$3

        shift 3
        
        if [ ${time_out} -lt ${interval} ];then
            caller >&2
            echo "In function wait_as_long_as_until time_out should be big than interval" >&2
            exit 1
        fi

        err=$(mktemp)
        
        max=$(expr ${time_out} / ${interval})

        for ((i=0;i<${max};i++));do
            if [ $# -ge 1 ];then
                ${cond_exp} "$@" 2> ${err} && rm -f ${err} && return
            else
                ${cond_exp} 2> ${err} && rm -f ${err} && return
            fi
            test -s ${err} && cat ${err} && rm -f ${err} && exit 1
            sleep ${interval}
        done
        rm -f ${err}
        false
    )
}

function wait_thirty_seconds {
    wait_as_long_as_until 30 2 "$@"
}

function wait_one_minute {
    wait_as_long_as_until 60 5 "$@"
}

function wait_three_minutes {
    wait_as_long_as_until 180 10 "$@"
}


function wait_ten_minutes {
    wait_as_long_as_until 600 10 "$@"
}

function wait_twenty_minutes {
    wait_as_long_as_until 1200 10 "$@"
}

function wait_thirty_minutes {
    wait_as_long_as_until 1800 15 "$@"
}

function wait_one_hour {
    wait_as_long_as_until 3600 30 "$@"
}

function is_X_ok {
    [ "${DISPLAY}"x = x ] && false || true
}

function get_info_from_url_in_raw {
    (
        url=$1
        perl -E "
          use URI::URL;
          my (\$scheme, \$host, \$port, \$path);
          my \$u = URI->new(q{${url}});
          if (\$u->can(scheme)) {
            \$scheme = \$u->scheme;
          }
          else {
            \$scheme = q{};
          }

          if (\$u->can(host)) {
            \$host = \$u->host; 
          }
          else {
            \$host = q{};
          }

          if (\$u->can(path)) {
            \$path = \$u->path; 
          }
          else {
            \$path = q{};
          }

          if (\$u->can(port)) {
            \$port = \$u->port; 
          }
          else {
            \$port = q{};
          }
          
          say join(q{:}, (\$scheme, \$host, \$port, \$path));
        "
    )
}

function get_info_from_url {
    url="$1"
    
    if [ "${url}"x = x ];then
        caller >&2
        echo 'The function get_info_from_url need an URL' 2>&1
        exit 1
    fi
    
    info="$(get_info_from_url_in_raw ${url})"
    scheme="$(echo ${info} | cut -d ':' -f 1)"
    host="$(echo ${info} | cut -d ':' -f 2)"
    port="$(echo ${info} | cut -d ':' -f 3)"
    path="$(echo ${info} | cut -d ':' -f 4)"

    if [ "${host}"x != x -a "${scheme}"x = x ];then
        scheme='http'
        if [ "${port}"x = x ];then
            port=80
        fi
    fi

    if [ "${host}"x = x -a "${scheme}"x != x ];then
        host='localhost'
    fi
    
    if [ "${host}"x = x -a "${scheme}"x = x ];then
        scheme='file'
    fi

    echo "${scheme}:${host}:${port}:${path}"
}

function get_host_and_port_from_url {
    url="$1"
    server_info="$(get_info_from_url ${url})"
    echo "${server_info}" | cut -d ':' -f 2,3
}

function get_host_from_url {
    url="$1"
    get_host_and_port_from_url "${url}" | cut -d ':' -f 1
}

function get_port_from_url {
    url="$1"
    get_host_and_port_from_url "${url}" | cut -d ':' -f 2
}

function get_scheme_from_url {
    url="$1"
    get_info_from_url "${url}" | cut -d ':' -f 1
}

function get_path_from_url {
    url="$1"
    get_info_from_url "${url}" | cut -d ':' -f 4
}

function get_search_key {
    (
        uuid='73b60b75-380d-47d9-809d-908736450d86'
        echo "${uuid}"
    )
}

function get_ticket_id {
    (
        uuid='18d29b50-0a92-46a0-a2ca-fbc8fd036c00'
        echo "${uuid}"
    )
}

function get_agent_id_of_msg_transfer_station {
    (
        uuid='8366e0c0-1e65-4aa5-8420-2ffa09081f67'
        echo "${uuid}"
    )
}

function get_default_js_top_dir {
    (
        uuid='5a4863c7-ca1a-41a2-8737-c502da05a8c3'
        echo "/${uuid}/"
    )
}

function is_file_exists {
    [ -e "$1" ]
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
        name="$(get_current_user_name)"
        perl -E "\$s=(getpwnam(q{${name}}))[7];say \$s"
    )
}

function is_firefox_db_dir {
    (
        section="$1"
        home="$(get_home_dir)"
        if [ -e "${home}/.mozilla/firefox/profiles.ini" ];then
            true
        else
            false
        fi
    )
}

function remove_firefox_db_dir {
    home_dir="$(get_home_dir)"
    
    if [ -d "${home_dir}/.cache/mozilla/firefox" ];then
        rm -rf "${home_dir}/.cache/mozilla/firefox"
    fi

    if is_firefox_db_dir;then
        rm -rf "${home_dir}/.mozilla/firefox"
    fi
}

function get_firefox_db_dir {
    (
        section="$1"
        home="$(get_home_dir)"
        if [ -e "${home}/.mozilla/firefox/profiles.ini" ];then
            dir=$(perl -E "
              use Config::IniFiles;
              say Config::IniFiles
              ->new(-file => q{${home}/.mozilla/firefox/profiles.ini})
              ->val(q{${section:-Profile0}}, q{Path});")
            dir="${home}/.mozilla/firefox/${dir}"
        fi
        
        echo "$dir"
        
        if [ "${dir}"x = x ];then
            false
        else
            true
        fi
        
    )
}

# Functions to init Firefox
function make_sure_firefox_db_dir {
    (
        home="$(get_home_dir)"
        
        if [ ! -e "${home}/.mozilla/firefox/profiles.ini" ];then            
            open_firefox_win
            close_firefox_win
        fi

        dir="$(get_firefox_db_dir)"
        wait_three_minutes "[ -e ${home}/.mozilla/firefox/profiles.ini ]"
        wait_three_minutes "[ -e ${dir}/prefs.js ]"
        wait_three_minutes "[ -e ${dir}/webappsstore.sqlite ]"
        
        get_firefox_db_dir
    )
}

function set_firefox_user_pref {
    (
        key="$1"
        value="$2"

        if [ "${key}"x = x ];then
            caller >&2
            echo "Need at least one argument" >&2
            exit 1
        fi
        [ "${value}"x = x ] && value='false'

        tempfile="$(mktemp)"
        dir="$(make_sure_firefox_db_dir)"
        file="${dir}/prefs.js"
        grep -v "user_pref(\"${key}\"," "${file}" > "${tempfile}"
        cat "${tempfile}" > "${file}"
        echo "user_pref(\"${key}\", $value);" >> "${file}"
        rm -f "${tempfile}"
    )
}

function set_firefox_user_pref_in_mass {
    (
        value="$1";
        if [ "${value}"x = x ];then
            caller >&2
            echo "Need at least one argument" >&2
            exit 1
        fi
        shift
        cmds="$(mktemp)"
        file="$(make_sure_firefox_db_dir)/prefs.js"
        {
            for key in "$@";do
                echo "g/user_pref(\"${key}\",/d"
            done
        } > "${cmds}"
        echo -n -e '$a\n' >> "${cmds}"
        {
            for key in "$@";do
                echo "user_pref(\"${key}\", $value);"
            done
        } >> "${cmds}"
        echo -n -e '.\nw\nq\n' >> "${cmds}"

        ed -s "${file}" < "${cmds}"
        
        rm -f "${cmds}"
    )
}


function set_firefox_no_session_restore {
    (
        tempfile="$(mktemp)"
        dir="$(make_sure_firefox_db_dir)"
        file="${dir}/prefs.js"
        grep -v "user_pref(\"browser.sessionstore.enabled\"," "${file}" \
            | grep -v "user_pref(\"browser.sessionstore.resume_from_crash\"," > "${tempfile}"
        cat "${tempfile}" > "${file}"
        for str in enabled resume_from_crash;do
            echo "user_pref(\"browser.sessionstore.${str}\", false);" >> "${file}"
        done
        rm -f "${tempfile}"
    )
}

function set_firefox_support_krb5_auth {
    (
        site="$1"
        tempfile="$(mktemp)"
        dir="$(make_sure_firefox_db_dir)"
        file="${dir}/prefs.js"
        
        grep -v "user_pref(\"network.negotiate-auth.trusted-uris\"," "${file}" \
            | grep -v "user_pref(\"network.negotiate-auth.delegation-uris\"," \
            > "${tempfile}"
        cat "${tempfile}" > "${file}"
        
        for str in trusted-uris delegation-uris;do
            echo "user_pref(\"network.negotiate-auth.${str}\", \"${site:-https://}\");" \
                >> "${file}"
        done
        
        rm -f "${tempfile}"
    )
}

function set_firefox_no_password_remember {
    (
        tempfile="$(mktemp)"
        dir="$(make_sure_firefox_db_dir)"
        file="${dir}/prefs.js"
        grep -v "user_pref(\"signon.rememberSignons\"," "${file}" > "${tempfile}"
        cat "${tempfile}" > "${file}"
        echo "user_pref(\"signon.rememberSignons\", false);" >> "${file}"
        rm -f "${tempfile}"
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
        set_firefox_user_pref \
            'datareporting.policy.dataSubmissionPolicyResponseType' \
            '"accepted-info-bar-dismissed"'
    )
}

# Functions to control firefox
function init_firefox {
    delete_all_search_key
    delete_all_ticket
}
function open_firefox_win {
    (
        uri="$1"

        is_firefox_open && close_firefox_win
        
        setsid firefox --new-instance "${uri:-}" &

        wait_one_minute is_firefox_open

        wait_one_minute is_file_exists "$(get_firefox_db_dir)/.parentlock"
        wait_one_minute is_file_exists "$(get_firefox_db_dir)/webappsstore.sqlite"
    )
}

function open_firefox_tab {
    (
        uri="$1"

        if ! is_X_ok;then
            caller >&2
            echo 'Firefox need an X server' >&2
            exit 1
        fi    
        
        { firefox --new-tab "${uri:-http://redhat.com}"; } 2>&1 > /dev/null
        wait_a_while
    )
}

function open_firefox {
    for p in "$@";do
        if is_firefox_open;then
            #            firefox "$p"
            open_firefox_tab "$p" 2>&1 > /dev/null
        else
            open_firefox_win "$p" 2>&1 > /dev/null
            wait_one_minute is_firefox_open
        fi
        wait_a_while
    done
}

function is_firefox_open {
    (
        if ! is_X_ok;then
            return 1
        fi

        is_firefox_db_dir || return 1
        
        dir="$(get_firefox_db_dir)"
        
        if [ "${dir}"x = x ];then
            return 1
        else
            if [ -e "${dir}/.parentlock" ];then
                fuser -s "${dir}/.parentlock"
            else
                return 1
            fi
        fi
    )
}

function is_firefox_close {
    if is_firefox_open;then
        false
    else
        true
    fi
}

function close_firefox_win {
    (
        dir="$(get_firefox_db_dir)"
        lock="${dir}/.parentlock"

        setsid fuser -s -k "${lock}"
        wait_a_while;wait_a_while

        wait_thirty_seconds is_file_exists "${lock}"
        
        if [ -e "${lock}" ];then
            is_firefox_open && setsid fuser -s -k ${lock}
        else
            return
        fi
        
        wait_thirty_seconds is_file_exists "${lock}"
        
        if [ -e "${lock}" ];then
            if fuser -s "${lock}";then
                caller >&2
                echo 'Failed to close Firefox' >&2
                exit 1
            else
                rm -f "${lock}"
            fi
        fi
    )
}

# Functions to control SSL/TSL certificates
function get_ssl_cert_from_remote {
    (
        if [ $# -eq 1 ];then
            host="$(get_host_from_url $1)"
            port="$(get_port_from_url $1)"
        elif [ $# -gt 1 ];then
            host="$1"
            port="$2"
        fi
        
        if [ -z "${host}" ];then
            caller >&2
            echo 'Function get_ssl_cert_from_remote need at least one argument' >&2
            echo 'Usage: get_ssl_cert_from_remote host [port]' >&2
            exit 1
        fi
        
        gnutls-cli -p "${port:-443}" --insecure --print-cert "${host}" < /dev/null \
            | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p'
    )
}

function get_nickname_from_cert_if_need {
    cert="$1"
    
    if [ -z "${cert}" ];then
        caller >&2
        echo 'Function get_nickname_from_cert need an argument' >&2
        echo 'Usage: get_nickname_from_cert path_to_certification' >&2
        exit 1
    fi
    
    openssl x509 -in "${cert}" -noout -subject | cut -s -d'/' -f 7 | cut -s -d'=' -f 2
}

function is_cert_in_db {
    (
        nickname="$1"
        dir="$(get_firefox_db_dir)"
        certutil -L -n "$nickname" -d "${dir}" > /dev/null 2>&1
    )
}

function add_cert_to_db {
    (
        nickname="$1"
        certification="$2"
        trust_type="$3"
        
        if [ -z "${nickname}" -o -z "${certification}" ];then
            caller >&2
            echo 'Function add_cert_to_db need at least 2 arguments' >&2
            echo 'Usage: add_cert_to_db nickname certification [trust_type]' >&2
            exit 1
        fi
        
        dir="$(get_firefox_db_dir)"
        certutil -A -t "${trust_type:-TC,Tw,Tw}" -n "${nickname}" -d "${dir}" -i "${certification}"
    )
}

function remove_cert_from_db {
    (
        nickname="$1"
        
        if [ -z "${nickname}" ];then
            caller >&2
            echo 'Function remove_cert_from_db need 1 arguments' >&2
            exit 1
        fi
        
        dir="$(get_firefox_db_dir)"
        
        certutil -D -n "${nickname}" -d "${dir}"
    )
}

function add_cert_for_each_host_of {
    (
        cf="$(mktemp)"
        
        for p in "$@";do
            host="$(get_host_from_url ${p})"
            port="$(get_port_from_url ${p})"
            nickname="${host}"
            
            get_ssl_cert_from_remote "${host}" "${port:-443}" > "$cf"
            
            is_cert_in_db "${nickname:-${host}}" \
                || add_cert_to_db "${nickname:-${host}}" "${cf}"
        done
        
        rm -f "$cf"
    )
}

function update_cert_for_each_host_of {
    (
        cf="$(mktemp)"
        
        for p in "$@";do
            host="$(get_host_from_url ${p})"
            port="$(get_port_from_url ${p})"
            nickname="${host}"

            get_ssl_cert_from_remote "${host}" "${port:-443}" > "$cf"
            
            is_cert_in_db "${nickname:-${host}}" \
                && remove_cert_from_db "${nickname:-${host}}"
            
            add_cert_to_db "${nickname:-${host}}" "${cf}"
        done
        
        rm -f "$cf"
    )
}

# Functions to read/write localStorage/sessionStorage.
# https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Storage
# {scope, key} must be unique in the localStorage/sessionStorage
function quote_str_for_sqlite3 {
    (
        str="$1"
        tmp_db="$(mktemp)"
        
        perl -E "
            use DBI;
            my \$dbh = DBI->connect(q[dbi:SQLite:dbname=${tmp_db}],
                q{}, q{}, { RaiseError => 1, AutoCommit => 0 });
            say \$dbh->quote(q{${str}});"
        
        rm -f "${tmp_db}"
    )
}

function get_path_to_localstorage {
    (
        dir="$(make_sure_firefox_db_dir)"
        
        if [ -r "${dir}" ];then
            echo "${dir}/webappsstore.sqlite"
        else
            caller >&2
            echo "Failed to get the path to localstorage database" >&2
            exit 1
        fi
    )
}

function read_from_localstorage {
    wait_three_minutes read_from_localstorage_unreliable "$@"
}

function read_from_localstorage_unreliable {
    (
        key="$1"
        scope="$2"
        
        if [ "${key}"x = x ];then
            caller >&2
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db="$(get_path_to_localstorage)"
        tbl="webappsstore2"

        key="$(quote_str_for_sqlite3 ${key})"
        if [ "${scope}"x != x ];then
            scope="$(quote_str_for_sqlite3 ${scope})"
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi

        select_clause="SELECT * FROM ${tbl} ${where_clause}"

        sqlite3 -batch -noheader "${db}" "${select_clause}" 2> /dev/null
    )
}

function read_value_from_localstorage {
    wait_three_minutes read_value_from_localstorage_unreliable "$@"
}

function read_value_from_localstorage_unreliable {
    (
        key="$1"
        scope="$2"
        
        if [ "${key}"x = x ];then
            caller >&2
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db="$(get_path_to_localstorage)"
        tbl="webappsstore2"

        key="$(quote_str_for_sqlite3 ${key})"
        if [ "${scope}"x != x ];then
            scope="$(quote_str_for_sqlite3 ${scope})"
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi
        select_clause="SELECT value FROM ${tbl} ${where_clause}"

        sqlite3 -batch -noheader "${db}" "${select_clause}" 2> /dev/null
    )
}

function read_secure_from_localstorage {
    wait_three_minutes read_secure_from_localstorage_unreliable "$@"
}

function read_secure_from_localstorage_unreliable {
    (
        key="$1"
        scope="$2"
        
        if [ "${key}"x = x ];then
            caller >&2
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db="$(get_path_to_localstorage)"
        tbl="webappsstore2"

        key="$(quote_str_for_sqlite3 ${key})"
        
        if [ "${scope}"x != x ];then
            scope="$(quote_str_for_sqlite3 ${scope})"
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi
        
        select_clause="SELECT secure FROM ${tbl} ${where_clause}"

        sqlite3 -batch -noheader "${db}" "${select_clause}" 2> /dev/null
    )
}

function read_owner_from_localstorage {
    wait_three_minutes read_owner_from_localstorage_unreliable "$@"
}

function read_owner_from_localstorage_unreliable {
    (
        key="$1"
        scope="$2"

        if [ "${key}"x = x ];then
            caller >&2
            echo "read_from_localstorage need at least an argument as the key" >&2
            echo "read_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db="$(get_path_to_localstorage)"
        tbl="webappsstore2"

        key="$(quote_str_for_sqlite3 ${key})"

        if [ "${scope}"x != x ];then
            scope="$(quote_str_for_sqlite3 ${scope})"
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi
        
        select_clause="SELECT owner FROM ${tbl} ${where_clause}"

        sqlite3 -batch -noheader "${db}" "${select_clause}" 2> /dev/null
    )
}

function delete_from_localstorage {
    wait_three_minutes delete_from_localstorage_unreliable "$@"
}

function delete_from_localstorage_unreliable {
    (
        key="$1"
        scope="$2"
        secure="$3"
        owner="$4"
        if [ "${key}"x = x ];then
            caller >&2
            echo "delete_from_localstorage need at least an argument as follows" >&2
            echo "delete_from_localstorage key [scope]" >&2
            exit 1
        fi
        
        db="$(get_path_to_localstorage)"
        tbl='webappsstore2'

        key="$(quote_str_for_sqlite3 ${key})"
        
        if [ "${scope}"x != x ];then
            scope="$(quote_str_for_sqlite3 ${scope})"
            where_clause="WHERE scope = ${scope} AND key = ${key}"  
        else
            where_clause="WHERE key = ${key}"
        fi

        if [ "${secure}"x != x ];then
            secure="$(quote_str_for_sqlite3 ${secure})"
            where_clause="${where_clause} AND secure = ${secure}"  
        fi

        if [ "${owner}"x != x ];then
            secure="$(quote_str_for_sqlite3 ${owner})"
            where_clause="${where_clause} AND owner = ${owner}"  
        fi

        sqlite3 -batch "${db}" "DELETE FROM ${tbl} ${where_clause}" 2> /dev/null
    )
}

function delete_from_localstorage_for_url {
    (
        url="$1"
        key="$2"
        
        if [ "${url}"x = x ];then
            caller >&2
            echo "Function need at least one argument" >&2
            exit 1
        fi

        localstorage_parameters="$(get_localstorage_parameters_by_origin ${url})"

        scope="$(echo $localstorage_parameters | cut -d '|' -f 1)"
        secure="$(echo $localstorage_parameters | cut -d '|' -f 2)"
        onwer="$(echo $localstorage_parameters | cut -d '|' -f 3)"

        delete_from_localstorage "${key}" "${scope}" "${secure}" "${owner}"
    )
}

function delete_all_search_key {
    delete_from_localstorage "$(get_search_key)"
}

function delete_all_ticket {
    delete_from_localstorage "$(get_ticket_id)"
}

# We will first delete, then write.
# Here value could be a file path, then we will read it
function write_to_localstorage {
    wait_three_minutes write_to_localstorage_unreliable "$@"
}

function write_to_localstorage_unreliable {
    (
        scope="$1"
        key="$2"
        value="$3"
        secure="$4"
        owner="$5"
        if [ "${scope}"x = x -o "${key}"x = x -o "${value}x" = x ];then
            caller >&2
            echo "write_to_localstorage need at least three arguments as follows" >&2
            echo "write_to_localstorage scope key value [secure] [owner]" >&2
            exit 1
        fi

        if [ -r "${value}" -a -f "${value}" ];then
            file="${value}"
            if eval "jq -M -c '.' \"${file}\" > /dev/null 2>&1";then
                value=$(jq -M -c '.' "${file}")
            else
                caller >&2
                echo "jq cannnot parse the file $file" >&2
                exit 1
            fi
        fi

        if eval "jq -n -M -c '@sh | ${value}' > /dev/null 2>&1";then
            value=$(jq -n -M -c "@sh | ${value}")
        else
            caller >&2
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

        sqlite3 "${db}" "${delete_clause};${insert_clause}" 2> /dev/null
    )
}

function read_all_from_localstorage {
    wait_three_minutes read_all_from_localstorage "$@"
}

function read_all_from_localstorage {
    (
        db="$(get_path_to_localstorage)"
        tbl='webappsstore2'

        select_clause="SELECT * FROM ${tbl}"

        sqlite3 -batch -noheader "${db}" "${select_clause}"
    )
}

function get_localstorage_parameters_when_scheme_is_file {
    (
        path="$1"
        if [ "${path}"x = x ];then
            caller >&2
            echo "Path cannot be empty" >&2
            exit 1
        fi

        path=$(get_path_from_url "${path}")

        search_key="$(get_search_key)"
        hosts_localstorage_info=''
        for r in $(read_from_localstorage "${search_key}");do
            path_r="$(echo $r | cut -d '|' -f 3)"
            scheme_r="$(echo $r | cut -d '|' -f 1 | cut -d ':' -f 2)"
            if [ "${path_r}" = "${path}" \
                -a "${scheme_r}" = 'file' ];then
                ret="$(echo $r | cut -d '|' -f 1,4-5)"
                break
            fi
        done        

        echo "${ret}"
        
        if [ "${ret}"x = x ];then
            false
        else
            true
        fi
    )
}

function get_localstorage_parameters_by_origin {
    (
        if [ $# -gt 1 ];then
            host="$1"
            scheme="$2"
            port="$3"
        else
            origin_info=$(get_info_from_url "$1")
            scheme="$(echo ${origin_info} | cut -d ':' -f 1)"
            host="$(echo ${origin_info} | cut -d ':' -f 2)"
            port="$(echo ${origin_info} | cut -d ':' -f 3)"
            path="$(echo ${origin_info} | cut -d ':' -f 4)"
        fi

        if [ "${scheme}" = 'file' ];then
            get_localstorage_parameters_when_scheme_is_file "${path}"
            return
        fi

        if [ "${host}"x = x ];then
            caller >&2
            echo 'Function get_localstorage_info_by_origin at least need an argument' >&2
            exit 1
        fi

        if [ "${scheme}"x = x -a "${port}"x = x ];then
            scheme='http'
            port=80
        fi

        if [ "${host}"x = x \
            -o "${scheme}"x = x  \
            -o "${port}"x = x ];then
            caller >&2
            echo 'The function get_localstorage_parameters_by_origin need at least an argument' >&2
            exit 1
        fi

        search_key="$(get_search_key)"
        hosts_localstorage_info=''
        for r in $(read_from_localstorage "${search_key}");do
            origin_r="$(echo $r | cut -d '|' -f 3)"
            host_r="$(get_host_from_url ${origin_r})"
            scheme_r="$(echo $r | cut -d '|' -f 1 | cut -d ':' -f 2)"
            port_r="$(echo $r | cut -d '|' -f 1 | cut -d ':' -f 3)"
            if [ "${host_r}" = "${host}" \
                -a "${scheme_r}" = "${scheme}" \
                -a "${port_r}" = "${port}" ];then
                ret="$(echo $r | cut -d '|' -f 1,4-5)"
                break
            fi
        done

        echo "${ret}"
        
        if [ "${ret}"x = x ];then
            false
        else
            true
        fi
    )
}

function is_localstorage_parameters_ok {
    (
        ok=0
        for p in "$@";do
            ret="$(get_localstorage_parameters_by_origin ${p})"
            if [ "${ret}"x = x ];then
                ok=1
                break
            fi
        done

        if [ ${ok} -eq 0 ];then
            true
        else
            false
        fi
    )
}

function create_ticket {
    (
        path="$1"
        is_ctrl="$2"
        status="$3"
        target_path="$4"
        
        if [ "${path}"x = x ];then
            path="$(get_default_js_top_dir)main.js"
        fi

        is_ctrl="${is_ctrl:-true}"
        
        status="${status:-queuing}"        
        
        tm_utc="$(date -u)"
        tm_local=$(date -d "${tm_utc}")

        if [ "${target_path}"x = x ];then
            cat <<EOF1 | jq -M -c '.'
{
"action": "insert_js_file",
"store": {
    "path": "${path}"
},
"is_ctrl": "${is_ctrl}",
"id": "$(uuidgen -r)",
"tm_utc": "${tm_utc}",
"tm_local": "${tm_local}", 
"status": "${status}",
"wrapper": {
     "id": "$(get_ticket_id)",
     "name": "mod_triger ticket"  
}
}
EOF1

        else
            cat <<EOF2 | jq -M -c '.'
{
"action": "insert_js_file",
"store": {
    "path": "${path}"
},
"is_ctrl": "${is_ctrl}",
"id": "$(uuidgen -r)",
"tm_utc": "${tm_utc}",
"tm_local": "${tm_local}", 
"status": "${status}",
"target_path": "${target_path}",
"wrapper": {
     "id": "$(get_ticket_id)",
     "name": "mod_triger ticket"  
}
}
EOF2
        fi        
    )
}

function is_status_of_ticket_of_url_not_queuing {
    (
        url="$1"
        
        status="$(read_ticket_status_for_url ${url})"

        if [ "${status}"x != x -a "${status}" != "queuing" ];then
            true
        else
            false
        fi
    )
}

function write_ticket_for_url {
    (
        url="$1"
        shift
        if [ "${url}"x = x ];then
            caller >&2
            echo "Function write_ticket_to_localstorage_for_url need at least an argument" >&2
            exit 1
        fi
        path="$1"
        status="$2"

        ticket="$(create_ticket ${path} ${status})"

        if is_localstorage_parameters_ok "${url}";then

            parameters="$(get_localstorage_parameters_by_origin ${url})"

            scope="$(echo $parameters | cut -d '|' -f 1)"
            secure="$(echo $parameters | cut -d '|' -f 2)"
            owner="$(echo $parameters | cut -d '|' -f 3)"

            write_to_localstorage "${scope}" "$(get_ticket_id)" \
                "${ticket}" "${secure}" "${owner}"

        else
            caller >&2
            echo "None localstorage parameters found for ${url}" >&2
            exit 1
        fi
    )
}

function read_ticket_for_url {
    (
        url="$1"
        
        if [ "${url}"x = x ];then
            caller >&2
            echo "Function read_ticket_for_url need at least an argument" >&2
            exit 1
        fi

        if is_localstorage_parameters_ok "${url}";then
            parameters="$(get_localstorage_parameters_by_origin ${url})"
            scope="$(echo $parameters | cut -d '|' -f 1)"
            secure="$(echo $parameters | cut -d '|' -f 2)"
            owner="$(echo $parameters | cut -d '|' -f 3)"
            key="$(get_ticket_id)"
            read_value_from_localstorage "${key}" "${scope}" "${secure}" "${owner}" \
                | jq -M '.'
        else
            caller >&2
            echo "None localstorage parameters found for ${url}" >&2
            exit 1
        fi
    )
}

function read_ticket_status_for_url {
    (
        url="$1"
        
        if [ "${url}"x = x ];then
            caller >&2
            echo "Function read_ticket_status_for_url need at least an argument" >&2
            exit 1
        fi

        if is_localstorage_parameters_ok "${url}";then
            parameters="$(get_localstorage_parameters_by_origin ${url})"
            scope="$(echo $parameters | cut -d '|' -f 1)"
            secure="$(echo $parameters | cut -d '|' -f 2)"
            owner="$(echo $parameters | cut -d '|' -f 3)"
            key="$(get_ticket_id)"
            read_value_from_localstorage "${key}" "${scope}" "${secure}" "${owner}" \
                | jq -M -r '.status'
        else
            caller >&2
            echo "None localstorage parameters found for ${url}" >&2
            exit 1
        fi
    )
}

function read_ticket_tm_utc_for_url {
    (
        url="$1"
        
        if [ "${url}"x = x ];then
            caller >&2
            echo "Function read_ticket_tm_utc_for_url need at least an argument" >&2
            exit 1
        fi

        if is_localstorage_parameters_ok "${url}";then
            parameters="$(get_localstorage_parameters_by_origin ${url})"
            scope="$(echo $parameters | cut -d '|' -f 1)"
            secure="$(echo $parameters | cut -d '|' -f 2)"
            owner="$(echo $parameters | cut -d '|' -f 3)"
            key="$(get_ticket_id)"
            read_value_from_localstorage "${key}" "${scope}" "${secure}" "${owner}" \
                | jq -M -r '.tm_utc'
        else
            caller >&2
            echo "None localstorage parameters found for ${url}" >&2
            exit 1
        fi
    )
}

function read_ticket_tm_local_for_url {
    (
        url="$1"
        
        if [ "${url}"x = x ];then
            caller >&2
            echo "Function read_ticket_tm_local_for_url need at least an argument" >&2
            exit 1
        fi

        if is_localstorage_parameters_ok "${url}";then
            parameters="$(get_localstorage_parameters_by_origin ${url})"
            scope="$(echo $parameters | cut -d '|' -f 1)"
            secure="$(echo $parameters | cut -d '|' -f 2)"
            owner="$(echo $parameters | cut -d '|' -f 3)"
            key="$(get_ticket_id)"
            read_value_from_localstorage "${key}" "${scope}" "${secure}" "${owner}" \
                | jq -M -r '.tm_local'
        else
            caller >&2
            echo "None localstorage parameters found for ${url}" >&2
            exit 1
        fi
    )
}

function read_ticket_is_ctrl_for_url {
    (
        url="$1"
        
        if [ "${url}"x = x ];then
            caller >&2
            echo "Function read_ticket_is_ctrl_for_url need at least an argument" >&2
            exit 1
        fi

        if is_localstorage_parameters_ok "${url}";then
            parameters="$(get_localstorage_parameters_by_origin ${url})"
            scope="$(echo $parameters | cut -d '|' -f 1)"
            secure="$(echo $parameters | cut -d '|' -f 2)"
            owner="$(echo $parameters | cut -d '|' -f 3)"
            key="$(get_ticket_id)"
            read_value_from_localstorage "${key}" "${scope}" "${secure}" "${owner}" \
                | jq -M -r '.is_ctrl'
        else
            caller >&2
            echo "None localstorage parameters found for ${url}" >&2
            exit 1
        fi
    )
}

# Thanks to KVM and Virtualbox, we easily get a exclusive machine.
# Hence shall we remove the following function?
# Firefox need an X window. We could try VNC server for it if need.
function setting_vnc_password {
    (
        passwd="$1"
        dir="$(get_home_dir)"
        # passwd=$(pwgen -c -n -s 32 1)
        [ -d "${dir}/.vnc" ] || mkdir "${dir}/.vnc"
        if ! [ -e "${dir}/.vnc/passwd" ];then
            touch  "${dir}/.vnc/passwd"
            chmod 600 "${dir}/.vnc/passwd"
        fi

        echo "${passwd:-redhat}" | vncpasswd -f > "${dir}/.vnc/passwd"
    )
}

# Functions of message bus
function fire_ticket {
    (
        msg="$1"
        mod_triger_js="$2"
        port="$3"
        host="$4"
        
        msg="${msg:-$(create_ticket)}"
        mod_triger_js=$(o=$(pwd);cd $(dirname $0);echo $(pwd)/mod_triger.js;cd $o)
        if [ ! -r "${mod_triger_js}" ];then
            old_mod_triger_js="${mod_triger_js}"
            mod_triger_js=$(pwd)/mod_triger.js
            if [ ! -r "${mod_triger_js}" ];then
                echo "The path to file mod_triger.js not found" 2>&1
                exit 1
            fi
        fi
        port=${port:-8080}
        host="${host:-localhost}"

        res=$(mktemp)
        cat > $res <<EOF1 
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Messages Transfer Station</title>
  </head>
  <body>
    <h3>Message Transfer Station for the mod_triger</h3>
    <p>So, How to use this page?</p>
    <p>We will add our ticket directly to the current agent. Let's check it now.</p>
   <script type="text/javascript" defer>
$(cat "${mod_triger_js}")
mod_triger.self.tkt_need_do[JSON.parse('${msg}').id] = JSON.parse('${msg}');
   </script>
  </body>
</html>
EOF1
        cat <<EOF2 | nc -C -l ${host} ${port} 2>&1 > /dev/null
HTTP/1.1 200 OK
Content-Type: text/html; charset=UTF-8
Connection: close
Cache-Control: no-cache
Date: $(date --rfc-822)
Conten-lenth: $(wc -c $res | cut -d ' ' -f 1)

$(cat $res)
EOF2

        rm -f $res
    )
}
