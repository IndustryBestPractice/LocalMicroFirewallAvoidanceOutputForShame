cls
# Powershell version of the Python "zip" feature. "Zips" two arrays into one dictionary object
function pspyzip_dict ([string[]]$keys, [string[]]$values)
    {
        $table = @{}
        for ($i = 0; $i -lt $keys.Count; $i++)
            {
                $table[$keys[$i]] = $values[$i]
            }
        return $table
    }

# Import windows firewall log
#$fwlog = get-content "$($env:systemroot)\system32\LogFiles\Firewall\pfirewall.log"
$fwlog = get-content "C:\mb\security\tmp\pfirewall.log"

# Get all comments
$fw_comments = $fwlog | Select-String -Pattern "#"

# Get delimited field names
$fw_field_names = $($($fw_comments | Where-Object {$_ -like "*Fields*"}).ToString().split(":")[1]).split(" ") | Where-Object {$_ -ne ""}

# Get all data, minus comments and empty lines
# Did it on two lines to preserve readability and troubleshooting
$fw_data = $fwlog | Select-String -not -Pattern "#" | Where-Object {$_ -ne " "}
$fw_data = $fw_data | ForEach-Object {$local_var = $_.ToString().trim(); if ($($local_var).ToString().length -gt 0) {$local_var}}

# Break data into an array of dictionary objects
$dict_array = foreach ($line in $fw_data) {pspyzip_dict -keys $fw_field_names -values $line.split(" ")}

# Convert to JSON for easy parsing
$fw_log_json = $dict_array | convertto-json
$fw_log_obj = $fw_log_json | convertfrom-json

# Received IPv4 connections
#$ipv4_inbound_allowed = $fw_log_obj | Where-Object {$_.path -eq "RECEIVE"} | Where-Object {$_.ACTION -eq "ALLOW"} | Select-Object -Property src-ip,src-port | Where-Object {$_."src-ip" -notlike "*:*"}
$ipv4_outbound_allowed = $fw_log_obj | Where-Object {$_.path -ne "RECEIVE"} | Where-Object {$_.ACTION -eq "ALLOW"} | Where-Object {$_."src-ip" -notlike "*:*"}

$ipv4_inbound_allowed = $fw_log_obj | Where-Object {$_.path -eq "RECEIVE"} | Where-Object {$_.ACTION -eq "ALLOW"} | Where-Object {$_."src-ip" -notlike "*:*"}
$non_ephemeral_connections_tcp = $ipv4_inbound_allowed | Where-Object {$_.protocol -eq "tcp"} | Where-Object {$_."src-port" -lt 32768} | Select-Object -Property src-ip,src-port -Unique
$non_ephemeral_connections_udp = $ipv4_inbound_allowed | Where-Object {$_.protocol -eq "udp"} | Where-Object {$_."src-port" -lt 32768} | Where-Object {$_."src-ip" -ne "127.0.0.1"} | Select-Object -Property src-ip,src-port -Unique