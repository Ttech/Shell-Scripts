$i = 0
$password = "$%G(@#J%G)@#JG"
#
# Bulk User Creator (Local)
#
# Designed to test network account management software
# Probably doesn't have much use to anyone else
# 
while ( $i -le 500 ) {
    $i++
  $prefix_int = (Get-Random -Minimum 0 -Maximum 20)
  if ($prefix_int -le 5 ) {
		$prefix = "NOAA"
	} elseif  (($prefix_int -gt 5) -and ($prefix_int -lt 10)) {
		$prefix = "Administrator"
	} elseif  (($prefix_int -gt 10) -and ($prefix_int -lt 15)) {
		$prefix = "User"
	} elseif  ($prefix_int -gt 15) {
		$prefix = "Awesome"
	}
	
	$username = $prefix + ( Get-Random -Maximum 9999 )
    	net user $username $password /add /active:yes /passwordreq:no
	net localgroup Users $username /add
}

