# Test 1 (delete path) — step B: remove it. Expect "Deleting" then idempotent.
networkmanager_connection { 'nm-pr2-del':
  ensure => 'absent',
}
