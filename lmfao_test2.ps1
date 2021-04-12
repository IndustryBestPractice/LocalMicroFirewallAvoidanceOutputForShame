$import_file = "/mb/IndustryBestPractice/lmfao/output.csv"
$csv = Import-Csv $import_file
$csv = $csv | foreach-object {if ($_.direction -ne "RECEIVE") {$_.direction = "SEND"}; $_}

# How to start docker to insert files
<#
sudo docker run --name neo4j -p7474:7474 -p7687:7687 -d -v /docker/neo4j/shared/data:/data -v /docker/neo4j/shared/logs:/logs -v /docker/neo4j/shared/import:/var/lib/neo4j/import -v /docker/neo4j/shared/plugins:/plugins --env NEO4J_AUTH=neo4j/test neo4j:latest
sudo docker container neo4j start
sudo docker container start neo4j:latest
sudo docker container start neo4j
#>

$url = "http://127.0.0.1:7474"
$credPair = "neo4j:test"
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
$headers = @{"Authorization"="Basic $encodedCredentials"; "Accept"="application/json; charset=UTF-8";"Content-Type"="application/json"}

# 80,377
function ipv4_obj_create_send ($insert_obj)
    {
        $dst_name = "ipv4_$($insert_obj.dst_ip.replace('.','_'))"
        $src_name = "ipv4_$($insert_obj.src_ip.replace('.','_'))"
        $retval = "CREATE ($($dst_name):ipv4 
                    {ip:`'$($insert_obj.dst_ip)`'})
                CREATE ($($src_name):ipv4 
                    {ip:`'$($insert_obj.src_ip)`'})
                CREATE ($src_name)-[:SENT_REQUEST {
                        from_prt: [`'$($insert_obj.src_prt)`'], 
                        to_prt: [`'$($insert_obj.dst_prt)`'], 
                        protocol: [`'$($insert_obj.protocol)`'], 
                        verdict: [`'$($insert_obj.verdict)`'],
                        datetime: [`'$($insert_obj.date_time)`']
                    }]->($dst_name)
                CREATE ($dst_name)-[:RECIEVED_REQUEST {
                        from_prt: [`'$($insert_obj.src_prt)`'], 
                        to_prt: [`'$($insert_obj.dst_prt)`'], 
                        protocol: [`'$($insert_obj.protocol)`'], 
                        verdict: [`'$($insert_obj.verdict)`'],
                        datetime: [`'$($insert_obj.date_time)`']
                    }]->($src_name)
                "
        return $retval
    }

function ipv4_obj_create_receive ($insert_obj)
    {
        $dst_name = "ipv4_$($insert_obj.dst_ip.replace('.','_'))"
        $src_name = "ipv4_$($insert_obj.src_ip.replace('.','_'))"
        $retval = "CREATE ($($dst_name):ipv4 
                    {ip:`'$($insert_obj.dst_ip)`'})
                CREATE ($($src_name):ipv4 
                    {ip:`'$($insert_obj.src_ip)`'})
                CREATE ($dst_name)-[:RECIEVED_REQUEST {
                        to_prt: [`'$($insert_obj.dst_prt)`'], 
                        from_prt: [`'$($insert_obj.src.prt)`'], 
                        protocol: [`'$($insert_obj.protocol)`'], 
                        verdict: [`'$($insert_obj.verdict)`'],
                        datetime: [`'$($insert_obj.date_time)`']
                    }]->($src_name)
                CREATE ($src_name)-[:SENT_REQUEST {
                        to_prt: [`'$($insert_obj.dst_prt)`'], 
                        from_prt: [`'$($insert_obj.src.prt)`'], 
                        protocol: [`'$($insert_obj.protocol)`'], 
                        verdict: [`'$($insert_obj.verdict)`'],
                        datetime: [`'$($insert_obj.date_time)`']
                    }]->($dst_name)"
        return $retval
    }
# This this shows all the remote IPS that communicated with local

#$input_object = $csv[0]
#$retval = "CREATE (`"$($insert_obj.src_ip.Trim(" "))`")-[:COMMUNICATED {dst_prt: `"$($insert_obj.dst_prt.Trim(" "))`", src_prt: `"$($insert_obj.src_prt.Trim(" "))`", protocol: `"$($insert_obj.protocol.Trim(" "))`", verdict: `"$($insert_obj.verdict.Trim(" "))`" }]->(`"$($insert_obj.dst_ip.Trim(" ").Trim("`n"))`")"

#match (n) detach delete (n)

#CREATE (TheMatrix:Movie {title:'The Matrix', released:1999, tagline:'Welcome to the Real World'})
#CREATE (Keanu:Person {name:'Keanu Reeves', born:1964})
#WITH TomH as a
#MATCH (a)-[:ACTED_IN]->(m)<-[:DIRECTED]-(d) RETURN a,m,d LIMIT 10;

#CREATE (ipv4_123_21_32_5:ipv4)
#CREATE (ipv4_123_21_32_5)-[:SENT {src_prt:['39850'], dst_prt:['11211'], protocol:['TCP'], verdict:['ALLOW']}]->(ipv4_123_21_32_107)
#MATCH (ipv4_123_21_32_5)

$statements = @()
$csv.Count
$num = 0
# IPv6
#$csv | Where-Object {$_.direction -eq "RECEIVE" -and $_.src_ip -like "*:*"} | ForEach-Object {
# IPv4
$csv | Where-Object {$_.src_ip -like "*.*" -and $_.dst_ip -like "*.*"} | Where-Object {$_.direction -eq "SEND"} | ForEach-Object {
    $insert_obj = $_
    if ($num -like "*000")
        {
            Write-Host "$num" -ForegroundColor Green
            $query = $(ipv4_obj_create_send -insert_obj $insert_obj)
            $statements += [ordered]@{"statement"= "$($query)"}
            $json_statement = @{"statements" = $statements}
            $retval = $json_statement | ConvertTo-Json
            
            $response = Invoke-WebRequest -Uri "$($url)/db/data/transaction/commit" -Method Post -Headers $headers -Body $($retval)
            $statements = @()
            $num++
        }
    else
        {
            $query = $(ipv4_obj_create_send -insert_obj $insert_obj)
            $statements += [ordered]@{"statement"= "$($query)"}
            $num++
        }
}
# Now we've broken out, time to send the last one!
Write-Host "$num" -ForegroundColor Green
$json_statement = @{"statements" = $statements}
$retval = $json_statement | ConvertTo-Json
$response = Invoke-WebRequest -Uri "$($url)/db/data/transaction/commit" -Method Post -Headers $headers -Body $($retval)

# NUMBER 2.0#
$statements = @()
$csv.Count
$num = 0
$csv | Where-Object {$_.src_ip -like "*.*" -and $_.dst_ip -like "*.*"} | Where-Object {$_.direction -eq "RECEIVE"} | ForEach-Object {
    $insert_obj = $_
    if ($num -like "*000")
        {
            Write-Host "$num" -ForegroundColor Green
            $query = $(ipv4_obj_create_receive -insert_obj $insert_obj)
            $statements += [ordered]@{"statement"= "$($query)"}
            $json_statement = @{"statements" = $statements}
            $retval = $json_statement | ConvertTo-Json
            
            $response = Invoke-WebRequest -Uri "$($url)/db/data/transaction/commit" -Method Post -Headers $headers -Body $($retval)
            $statements = @()
            $num++
        }
    else
        {
            $query = $(ipv4_obj_create_receive -insert_obj $insert_obj)
            $statements += [ordered]@{"statement"= "$($query)"}
            $num++
        }
}
# Now we've broken out, time to send the last one!
Write-Host "$num" -ForegroundColor Green
$json_statement = @{"statements" = $statements}
$retval = $json_statement | ConvertTo-Json
$response = Invoke-WebRequest -Uri "$($url)/db/data/transaction/commit" -Method Post -Headers $headers -Body $($retval)

<#
MATCH (ipv4_123_21_32_5:ipv4)-[:SENT]->(p:Part)-[:FROM_DEALER]-(d:Dealer)
RETURN v, p, d;
#>
