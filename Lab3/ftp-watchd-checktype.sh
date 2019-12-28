#!/bin/sh
#
#

# PROVIDE: pureftpd
# REQUIRE: NETWORKING SERVERS
# BEFORE: DAEMON
# KEYWORD: shutdown

# Add the following lines to /etc/rc.conf to enable pure-ftpd:
#
# Add the following lines to /etc/rc.conf to enable uploadscript daemon:
#
# ftp_watchd_enable="yes"

. /etc/rc.subr

name=ftp_watchd_checktype
rcvar=ftp_watchd_checktype_enable

load_rc_config ${name}

# uploadscript
command="/usr/local/sbin/pure-uploadscript"
pidfile_ftp_watchd_checktype=${pidfile_ftp_watchd_checktype:-"/var/run/pure-uploadscript.pid"}
ftp_watchd_checktype_enable=${ftp_watchd_checktype_enable:-"NO"}
ftp_watchd_checktype_uploadscript=${ftp_watchd_checktype_uploadscript:-"/usr/home/leeang6969/hw/hw3/uploadscript_checktype.sh"}
# command_args
command_args="-B -p ${pidfile_ftp_watchd_checktype} -r ${ftp_watchd_checktype_uploadscript}"

stop_cmd=stop_cmd

stop_cmd()
{
	if checkyesno ftp_watchd_enable; then
		pid=$(check_pidfile ${pidfile_ftp_watchd_checktype} ${command})
		if [ -z $pid ]; then
			echo "${name} not running? (Check ${pidfile_ftp_watchd_checktype})"
			return 1
		fi
		echo "Kill: ${pid}"
		kill -${sig_stop:-TERM} ${pid}
		[ $? -ne 0 ] && [ -z "$rc_force" ] && return 1
	fi
}

run_rc_command "$1"