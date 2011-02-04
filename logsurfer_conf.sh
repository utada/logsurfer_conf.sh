#!/bin/bash

base=/data/logsurfer
mailerr=mail@foo.com
mailslw=slow@foo.com
port=(3306)
hostname=`hostname`
errlog=(/data/mysql/mysql.err)
slwlog=(/data/mysql/slow.log)
logsurferbin=/usr/local/bin/logsurfer

cd /tmp
wget http://kerryt.orcon.net.nz/logsurfer+-1.7.tar.gz
tar xzvf logsurfer+-1.7.tar.gz
cd logsurfer+-1.7
./configure
make
make install
cp /tmp/logsurfer+-1.7/contrib/start-mail/start-mail /usr/local/sbin/
sed -i s'/\/usr\/bin\/sed/\/bin\/sed/'g /usr/local/sbin/start-mail
sed -i s'/\/usr\/lib\/sendmail -odq -t/\/usr\/lib\/sendmail -i -t/'g /usr/local/sbin/start-mail
chmod 755 /usr/local/sbin/start-mail
rm /tmp/logsurfer+-1.7.tar.gz*
rm -rf /tmp/logsurfer+-1.7

mkdir -p ${base}
i=0
for a in port;do

  errconf=${base}/${hostname}.${port[i]}.err.conf
  slwconf=${base}/${hostname}.${port[i]}.slw.conf
  errpid=${base}/${hostname}.${port[i]}.err.pid
  slwpid=${base}/${hostname}.${port[i]}.slw.pid
  errdump=${base}/${hostname}.${port[i]}.err.dump
  slwdump=${base}/${hostname}.${port[i]}.slw.dump
  logerr=${base}/${hostname}.${port[i]}.err.log
  logslw=${base}/${hostname}.${port[i]}.slw.log
  errsh=${base}/${hostname}.${port[i]}.err.sh
  slwsh=${base}/${hostname}.${port[i]}.slw.sh

  cat << EOF > ${errconf} 2>&1
#logsurfer-err.conf
'*' - - - 0
    open '.*' - 300 10800 60
    pipe "/usr/local/sbin/start-mail ${mailerr} \"${hostname}:${port[i]}:${errlog[i]} \""
EOF
  cat << EOF > ${slwconf} 2>&1
#logsurfer-err.conf
'*' - - - 0
    open '.*' - 300 10800 60
    pipe "/usr/local/sbin/start-mail ${mailslw} \"${hostname}:${port[i]}:${slwlog[i]} \""
EOF

  cat << EOF > ${errsh} 2>&1
#!/bin/bash
. /etc/rc.d/init.d/functions
LANG=C
basedir=${base}
errconf=${errconf}
errdump=${errdump}
logsuferbin=${logsurferbin}
errpid=${errpid}
errlog=${errlog}
logerr=${logerr}
prog="logsurfer"
RETVAL=0
start() {
  echo -n $"Starting $prog: "
  if [ ! -s \${errpid} ]; then
    \${logsuferbin} \\
       -c \${errconf} \\
       -d \${errdump} \\
       -f \${errlog} \\
       -e \\
       -p \${errpid} \\
       >> \${logerr} 2>&1 &

    RETVAL=\$?
    [ \$RETVAL -ne 0 ] && failure
    [ \$RETVAL -eq 0 ] && success
    echo
    return \$RETVAL
  else
    failure
    echo
    exit 1
  fi
}
stop() {
  echo -n $"Stopping \$prog: "
  IDERR=\`cat \${errpid} \`
  kill \${IDERR}
  RETVAL=\$?
  [ \$RETVAL -eq 0 ] && rm -f \${errpid} && success
  echo
  return \$RETVAL
}
restart(){
  stop
  start
}
case "\$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  *)
    echo $"Usage: \$0 {start|stop|restart}"
    RETVAL=1
esac
exit \$RETVAL
EOF
  cat << EOF > ${slwsh} 2>&1
#!/bin/bash
. /etc/rc.d/init.d/functions
LANG=C
basedir=${base}
slwconf=${slwconf}
slwdump=${slwdump}
logsuferbin=${logsurferbin}
slwpid=${slwpid[i]}
slwlog=${slwlog[i]}
logslw=${logslw}
prog="logsurfer"
RETVAL=0
start() {
  echo -n $"Starting $prog: "
  if [ ! -s \${slwpid} ]; then
    \${logsuferbin} \\
       -c \${slwconf} \\
       -d \${slwdump} \\
       -f \${slwlog} \\
       -e \\
       -p \${slwpid} \\
       >> \${logslw} 2>&1 &

    RETVAL=\$?
    [ \$RETVAL -ne 0 ] && failure
    [ \$RETVAL -eq 0 ] && success
    echo
    return \$RETVAL
  else
    failure
    echo
    exit 1
  fi
}
stop() {
  echo -n $"Stopping \$prog: "
  IDERR=\`cat \${slwpid} \`
  kill \${IDERR}
  RETVAL=\$?
  [ \$RETVAL -eq 0 ] && rm -f \${slwpid} && success
  echo
  return \$RETVAL
}
restart(){
  stop
  start
}
case "\$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    restart
    ;;
  *)
    echo $"Usage: \$0 {start|stop|restart}"
    RETVAL=1
esac
exit \$RETVAL
EOF

  i=$((i + 1))

done

chown -R mysql.mysql ${base}
chmod 755 ${base}/*.sh

exit 0;

