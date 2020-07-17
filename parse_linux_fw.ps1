# get firewall log
#$start_time = get-date
#$file_path = "/var/log/ufw.log"
$file_path = "/mb/IndustryBestPractice/lmfao/ufw.log"
$linux_header = "month day time hostname kernel1 kernel2 verdict1 verdict2 interface outerface mac src_ip dst_ip msg_size tos prec ttl id1 id2 protocol src_prt dst_prt window res1 res2 urgp"
#$raw = $(Get-Content "$($file_path)" -ReadCount 0) -replace "  "," "
$raw = $($linux_header + "  " + $($(Get-Content "$($file_path)" -ReadCount 0) -replace "  "," ")) -split "  "
$raw_csv = $raw | Convertfrom-Csv -Delimiter " "

<#
@{expression={$(get-date $([datetime]::ParseExact("$($($_).month) $($($_).day) $($($_).time)", "MMM d HH:mm:ss", $null)) -format "yyyy-MM-dd HH:mm:ss")}; label="date_time"},
@{expression={$_.hostname}; label="host_name"},
@{expression={"$($_.verdict2.split("]")[0])"}; label="verdict"},
@{expression={"$($_.interface.split("=")[1])"}; label="interface"},
@{expression={"$($_.outerface.split("=")[1])"}; label="outerface"},
@{expression={"$($_.mac.split("=")[1])"}; label="mac"},
@{expression={"$($_.src_ip.split("=")[1])"}; label="src_ip"},
@{expression={"$($_.dst_ip.split("=")[1])"}; label="dst_ip"},
@{expression={"$($_.src_prt.split("=")[1])"}; label="src_prt"},
@{expression={"$($_.dst_prt.split("=")[1])"}; label="dst_prt"},
@{expression={"$($_.protocol.split("=")[1])"}; label="protocol"}
#>
$final_csv = $raw_csv | Select-Object -Property @{expression={$(get-date $([datetime]::ParseExact("$($($_).month) $($($_).day) $($($_).time)", "MMM d HH:mm:ss", $null)) -format "yyyy-MM-dd HH:mm:ss")}; label="date_time"},@{expression={$_.hostname}; label="host_name"},@{expression={"$($_.verdict2.split("]")[0])"}; label="verdict"},@{expression={"$($_.interface.split("=")[1])"}; label="interface"},@{expression={"$($_.outerface.split("=")[1])"}; label="outerface"},@{expression={"$($_.mac.split("=")[1])"}; label="mac"},@{expression={"$($_.src_ip.split("=")[1])"}; label="src_ip"},@{expression={"$($_.dst_ip.split("=")[1])"}; label="dst_ip"},@{expression={"$($_.src_prt.split("=")[1])"}; label="src_prt"},@{expression={"$($_.dst_prt.split("=")[1])"}; label="dst_prt"},@{expression={"$($_.protocol.split("=")[1])"}; label="protocol"}

#$stop_time = Get-Date
#New-TimeSpan -Start $start_time -End $stop_time
