#!/bin/sh

test_description='Check munged command-line options'

. $(dirname "$0")/sharness.sh

test_expect_success 'munged invalid option' '
    test_must_fail "${MUNGED}" --invalid-option
'

for OPT_HELP in '-h' '--help'; do
    test_expect_success "munged ${OPT_HELP}" '
        "${MUNGED}" "${OPT_HELP}" |
        grep -q "^Usage:"
    '
done

for OPT_LICENSE in '-L' '--license'; do
    test_expect_success "munged ${OPT_LICENSE}" '
        "${MUNGED}" "${OPT_LICENSE}" |
        grep -q "GNU General Public License"
    '
done

for OPT_VERSION in '-V' '--version'; do
    test_expect_success "munged ${OPT_VERSION}" '
        "${MUNGED}" "${OPT_VERSION}" |
        grep -q "^munge-[0-9.]*"
    '
done

# Check if the stop option succeeds in stopping the process and removing the
#   socket and pidfile from the filesystem.
##
for OPT_STOP in '-s' '--stop'; do
    test_expect_success "munged ${OPT_STOP}" '
        local PID &&
        munged_start_daemon &&
        test -f "${MUNGE_PIDFILE}" &&
        PID=$(cat "${MUNGE_PIDFILE}") &&
        ps -p "${PID}" | grep munged &&
        test -S "${MUNGE_SOCKET}" &&
        "${MUNGED}" "${OPT_STOP}" --socket="${MUNGE_SOCKET}" &&
        test ! -S "${MUNGE_SOCKET}" &&
        test ! -f "${MUNGE_PIDFILE}" &&
        ! ps -p "${PID}" &&
        unset MUNGE_SOCKET &&
        unset MUNGE_PIDFILE
    '
done

# Check if the stop option properly fails to stop a daemon on a non-existent
#   socket.
##
test_expect_success 'munged --stop for missing socket' '
    test_must_fail "${MUNGED}" --stop --socket=missing.socket.$$
'

for OPT_VERBOSE in '-v' '--verbose'; do
    test_expect_success "munged ${OPT_VERBOSE}" '
        munged_start_daemon &&
        "${MUNGED}" "${OPT_VERBOSE}" --stop --socket="${MUNGE_SOCKET}" 2>&1 |
        grep -q "Terminated daemon" &&
        unset MUNGE_SOCKET &&
        unset MUNGE_PIDFILE
    '
done

test_expect_failure 'finish writing tests' '
    false
'

test_done
