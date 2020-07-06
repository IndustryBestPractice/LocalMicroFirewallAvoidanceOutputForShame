# get firewall log
$start_time = get-date
#$file_path = "/var/log/ufw.log"
$file_path = "/kr/IndustryBestPractice/lmfao/ufw.log"
$linux_header = "month day time hostname kernel1 kernel2 verdict1 verdict2 interface outerface mac src_ip dst_ip msg_size tos prec ttl id1 id2 protocol src_prt dst_prt window res1 res2 urgp"
#$raw = $(Get-Content "$($file_path)" -ReadCount 0) -replace "  "," "
$raw = $($linux_header + "  " + $($(Get-Content "$($file_path)" -ReadCount 0) -replace "  "," ")) -split "  "
$raw_csv = $raw | Convertfrom-Csv -Delimiter " "

$raw_csv | ForEach-Object {$_.urgp = $_.urgp.split("=")[1]}
$raw_csv | ForEach-Object {$_.res1 = "$($_.res1.split("=")[1]) $($_.res2)"}
$raw_csv | ForEach-Object {$_.window = $_.window.split("=")[1]}
$raw_csv | ForEach-Object {$_.src_prt = $_.src_prt.split("=")[1]}
$raw_csv | ForEach-Object {$_.dst_prt = $_.dst_prt.split("=")[1]}
$raw_csv | ForEach-Object {$_.protocol = $_.protocol.split("=")[1]}
$raw_csv | ForEach-Object {$_.id1 = "$($_.id1.split("=")[1]) $($_.id2)"}
$raw_csv | ForEach-Object {$_.ttl = $_.ttl.split("=")[1]}
$raw_csv | ForEach-Object {$_.prec = $_.prec.split("=")[1]}
$raw_csv | ForEach-Object {$_.tos = $_.tos.split("=")[1]}
$raw_csv | ForEach-Object {$_.msg_size = $_.msg_size.split("=")[1]}
$raw_csv | ForEach-Object {$_.dst_ip = $_.dst_ip.split("=")[1]}
$raw_csv | ForEach-Object {$_.src_ip = $_.src_ip.split("=")[1]}
$raw_csv | ForEach-Object {$_.mac = $_.mac.split("=")[1]}
$raw_csv | ForEach-Object {$_.outerface = $_.outerface.split("=")[1]}
$raw_csv | ForEach-Object {$_.interface = $_.interface.split("=")[1]}
$raw_csv | ForEach-Object {$_.verdict1 = "$($_.verdict2.split("]")[0])"}
$raw_csv | ForEach-Object {$_.kernel1 = "$($_.kernel1.split("=")[0]) $($_.kernel2)"}
$raw_csv | ForEach-Object {$_.time = $(get-date $([datetime]::ParseExact("$($($_).month) $($($_).day) $($($_).time)", "MMM d HH:mm:ss", $null)) -format "yyyy-MM-dd HH:mm:ss")}

$final_csv = $raw_csv | Select-Object -Property @{expression={$_.time}; label="date_time"},@{expression={$_.hostname}; label="host_name"},@{expression={$_.verdict1}; label="verdict"},interface,outerface,mac,src_ip,dst_ip,src_prt,dst_prt,protocol

$stop_time = Get-Date
New-TimeSpan -Start $start_time -End $stop_time
#write-host "stop"