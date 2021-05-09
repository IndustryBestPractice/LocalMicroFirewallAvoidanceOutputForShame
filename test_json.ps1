<#
CREATE
(Keanu)-[:ACTED_IN {roles:['Neo']}]->(TheMatrix),
(Carrie)-[:ACTED_IN {roles:['Trinity']}]->(TheMatrix),
(Laurence)-[:ACTED_IN {roles:['Morpheus']}]->(TheMatrix),
(Hugo)-[:ACTED_IN {roles:['Agent Smith']}]->(TheMatrix),
(LillyW)-[:DIRECTED]->(TheMatrix),
(LanaW)-[:DIRECTED]->(TheMatrix),
(JoelS)-[:PRODUCED]->(TheMatrix)
#>

<#
$fname = "kevin"
$lname = "roman"
$query = "MERGE (test1:person { fname: `"$($fname)`", lname: `"$($lname)`" })"
$queries['statements'] += [ordered]@{'statement'="$($query)"}

$fname = "kevin"
$lname = "roman"
$query = "MERGE (test2:person { fname: `"$($fname)`", lname: `"$($lname)`" })"
$queries['statements'] += [ordered]@{'statement'="$($query)"}


$fname = "kevin"
$lname = "bacon"
$query = "MERGE (test3:person { fname: `"$($fname)`", lname: `"$($lname)`" })"
$queries['statements'] += [ordered]@{'statement'="$($query)"}

$fname = "lauren"
$lname = "salopek"
$query = "MERGE (test4:person { fname: `"$($fname)`", lname: `"$($lname)`" })"
$queries['statements'] += [ordered]@{'statement'="$($query)"}
#>

<#
# Delete all nodes and relationships
MATCH (n)
DETACH DELETE n
#>

<#
match (variable_name:indexname {propertyname:"property value"}) return variable_name
# return just kevin roman
match (n:person {fname:"kevin", lname:"roman"}) return n
# return all people with first name kevin
match (n:person {fname:"kevin"}) return n

# return multiple people
match (from:person {fname:"kevin", lname:"roman"})
match (to:person {fname:"lauren", lname:"salopek"})
return from,to

# create relationship between two existing nodes
match (from:person {fname:"kevin", lname:"roman"})
match (to:person {fname:"lauren", lname:"salopek"})
MERGE (from)-[datatransfer:SENT {date:"2021-05-01 00:00:00.000", type:"ICMP", size:"291729"}]->(to)
return datatransfer

# Load CSV file and create data that way
# https://neo4j.com/developer/guide-import-csv/
# https://neo4j.com/blog/bulk-data-import-neo4j-3-0/
# sudo docker run --rm --env NEO4J_AUTH=neo4j/test --name neo4j -p 7474:7474 -p 7473:7473 -p 7687:7687 -v ~/golang/data:/var/lib/neo4j/import/data -it neo4j
# sudo docker run --rm --name golang -v /home/kroman/golang:/data -it golang
# LOAD CSV WITH HEADERS FROM 'file:///data/send_data.csv' AS row WITH row LIMIT 100
LOAD CSV WITH HEADERS FROM 'file:///data/send_data.csv' AS row
MERGE (from:ipv4 {ip: row.srcip})
MERGE (tokr:ipv4 {ip: row.dstip})
MERGE (from)-[datatransfer:SENT {date: row.date, type: row.action, size: row.size}]->(tokr)

LOAD CSV WITH HEADERS FROM 'file:///data/receive_data.csv' AS row
MERGE (from:ipv4 {ip: row.srcip})
MERGE (tokr:ipv4 {ip: row.dstip})
MERGE (from)<-[datatransfer:RECEIVED {date: row.date, type: row.action, size: row.size}]-(tokr)
#>

$data = "C:\users\kroman\Documents\golang\data"

###########################################
# THIS WORKS TO CREATE ONE STATEMENT IN STATEMENTS
###########################################
foreach ($UUID in ($(Get-ChildItem "$($data)\go_output\*.csv" -File).name | ForEach-Object {$_.split("_")[0]} | Sort-Object -Unique))
    {
        $queries = @{}
        $queries['statements'] = @()

        $query = "LOAD CSV WITH HEADERS FROM 'file:///data/go_output/$($uuid)_send_data.csv' AS row
        MERGE (from:ipobj {ip: row.srcip, ipversion: row.srcipver})
        MERGE (to:ipobj {ip: row.dstip, ipversion: row.dstipver})
        MERGE (from)-[datatransfer:SENT {date: row.date, type: row.action, size: row.size}]->(to)"
        $queries['statements'] += [ordered]@{'statement'="$($query)"}

        $query = "LOAD CSV WITH HEADERS FROM 'file:///data/go_output/$($uuid)_receive_data.csv' AS row
        MERGE (from:ipobj {ip: row.srcip, ipversion: row.srcipver})
        MERGE (to:ipobj {ip: row.dstip, ipversion: row.dstipver})
        MERGE (from)<-[datatransfer:RECEIVED {date: row.date, type: row.action, size: row.size}]-(to)"
        $queries['statements'] += [ordered]@{'statement'="$($query)"}

        $query = "LOAD CSV WITH HEADERS FROM 'file:///data/go_output/$($uuid)_forward_data.csv' AS row
        MERGE (from:ipobj {ip: row.srcip, ipversion: row.srcipver})
        MERGE (to:ipobj {ip: row.dstip, ipversion: row.dstipver})
        MERGE (from)<-[datatransfer:FORWARD {date: row.date, type: row.action, size: row.size}]-(to)"
        $queries['statements'] += [ordered]@{'statement'="$($query)"}

        $query = "LOAD CSV WITH HEADERS FROM 'file:///data/go_output/$($uuid)_unknown_data.csv' AS row
        MERGE (from:ipobj {ip: row.srcip, ipversion: row.srcipver})
        MERGE (to:ipobj {ip: row.dstip, ipversion: row.dstipver})
        MERGE (from)<-[datatransfer:UNKNOWN {date: row.date, type: row.action, size: row.size}]-(to)"
        $queries['statements'] += [ordered]@{'statement'="$($query)"}

        $retval = $queries| ConvertTo-Json

        $url = "http://127.0.0.1:7474"
        $credPair = "neo4j:test"
        $encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
        $headers = @{"Authorization"="Basic $encodedCredentials"; "Accept"="application/json; charset=UTF-8";"Content-Type"="application/json"}

        $response = Invoke-WebRequest -Uri "$($url)/db/data/transaction/commit" -Method Post -Headers $headers -Body $($retval)
        $response.content
    }

$queries = @{}
$queries['statements'] = @()
$query = "match (n) where n.ipversion = 'ipv6' SET n :IPv6"
$queries['statements'] += [ordered]@{'statement'="$($query)"}
$query = "match (n) where n.ipversion = 'ipv4' SET n :IPv4"
$queries['statements'] += [ordered]@{'statement'="$($query)"}

$retval = $queries| ConvertTo-Json

$url = "http://127.0.0.1:7474"
$credPair = "neo4j:test"
$encodedCredentials = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($credPair))
$headers = @{"Authorization"="Basic $encodedCredentials"; "Accept"="application/json; charset=UTF-8";"Content-Type"="application/json"}

$response = Invoke-WebRequest -Uri "$($url)/db/data/transaction/commit" -Method Post -Headers $headers -Body $($retval)
$response.content