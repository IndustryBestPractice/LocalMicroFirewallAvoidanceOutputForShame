# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes?view=powershell-7
# https://docs.microsoft.com/en-us/powershell/scripting/windows-powershell/wmf/whats-new/class-overview?view=powershell-7
# Class examples: https://xainey.github.io/2016/powershell-classes-and-concepts/

$filelist = @()
$filelist += "/mb/IndustryBestPractice/lmfao/ufw_new.log,Linux"
$filelist += "/mb/IndustryBestPractice/lmfao/win.log,Windows"
$data_import = $filelist | ForEach-Object -Parallel {

    class ParseRule {
        # Public
        [string]$file_path
        [string]$os_type
        # Hidden
        hidden [String]$test_os = $isLinux
    
        # Constructor
        ParseRule(){
            $this.file_path = 'Undefined'
            $this.os_type = if ($this.test_os) {"Linux"} else {"Windows"}
        }
        # Constructor Overload 1
        ParseRule([string]$file_path, [string]$os_type){
            $this.os_type = $os_type
            $this.file_path = $file_path
        }
        # Constructor Overload 2
        ParseRule([string]$file_path){
            $this.file_path = $file_path
        }
    
        [string] read() {
            throw("Must be an override method!")
        }
    }
    
    class windows : ParseRule {
    
        windows ([string]$file_path) : base($file_path)
        {}
        windows ([string]$file_path, [string]$os_type) : base($file_path,$os_type)
        {}
    
        # Override
        [System.Collections.ArrayList]read() {
            # Local function
            function pspyzip_dict ([string[]]$keys, [string[]]$values)
            {
                $table = @{}
                for ($i = 0; $i -lt $keys.Count; $i++)
                    {
                        $table[$keys[$i]] = $values[$i]
                    }
                return $table
            }
            $file_obj = [System.Collections.ArrayList]$(Get-Content $this.file_path)
            # Import windows firewall log
            $fw_log = $file_obj
            # Get all comments
            $fw_comments = $fw_log | Select-String -Pattern "#"
    
            # Get delimited field names
            [System.Collections.Arraylist]$windows_header = $($($fw_comments | Where-Object {$_ -like "*Fields*"}).ToString().split(":")[1]).split(" ") | Where-Object {$_ -ne ""}
            # Get all data, minus comments and empty lines
            # Did it on two lines to preserve readability and troubleshooting
            $fw_data = $fw_log | Select-String -not -Pattern "#" | Where-Object {$_ -ne " "}
            $fw_data = $fw_data | ForEach-Object {$local_var = $_.ToString().trim(); if ($($local_var).ToString().length -gt 0) {$local_var}}
    
            # Break data into an array of dictionary objects
            $dict_array = foreach ($line in $fw_data) {pspyzip_dict -keys $windows_header -values $line.split(" ")}
            [System.Collections.ArrayList]$retval = $dict_array | Select-Object -Property @{expression={$(get-date $([datetime]::ParseExact("$($($_).date) $($($_).time)", "yyyy-MM-dd HH:mm:ss", $null)) -format "yyyy-MM-dd HH:mm:ss")}; label="date_time"},@{expression={if (@("DROP") -contains $_.action) {"BLOCK"} elseif (@("OPEN","CLOSE","OPEN-INBOUND") -contains $_.action) {"ALLOW"} else {"UNKNOWN"}}; label="verdict"},@{expression={"$($_."src-ip")"}; label="src_ip"},@{expression={"$($_."dst-ip")"}; label="dst_ip"},@{expression={"$($_."src-port")"}; label="src_prt"},@{expression={"$($_."dst-port")"}; label="dst_prt"},@{expression={"$($_.protocol)"}; label="protocol"},@{expression={"$($_.path)"}; label="direction"}
            return [System.Collections.ArrayList]$retval
        }
    
    }
    
    class linux : ParseRule {
        linux ([string]$file_path) : base($file_path)
        {}
        linux ([string]$file_path, [string]$os_type) : base($file_path, $os_type)
        {}
    
        [System.Collections.ArrayList]read(){
            # Get first part of linux file
            $linux_header = "date_time verdict incoming outgoing src_ip dst_ip protocol src_prt dst_prt"
            $raw = $($($(Get-Content "$($this.file_path)" -ReadCount 0) -replace "  "," ")) -split "  "
            # 3.5  minutes
            $raw = $raw | Select-Object -Property @{expression={$val = $([regex]::split("$_", ' ')); "datetime=$($(get-date $([datetime]::ParseExact("$($($val[0,1,2]))", "MMM d HH:mm:ss", $null)) -format "yyyy-MM-dd HH:mm:ss").replace(' ','T').ToString()) verdict=$($val[7].split(']')[0]) $($val[8..99])"}; label="other"}
    
            #2.18 minutes
            $raw = $raw.other | ForEach-Object {$($([regex]::split("$_", ' '))) | where-object {@("datetime","verdict","in","out","src","dst","proto","spt","dpt") -contains "$([regex]::split("$_", '(=|\s)+')[0])"}}
            $raw = $linux_header + $($raw.replace("datetime","`r`ndatetime") -join " ")
            $raw_csv = $raw | Convertfrom-Csv -Delimiter " "
            [System.Collections.ArrayList]$retval = $raw_csv | Select-Object -Property @{expression={$($_.date_time.split("=")[1].split("T")) -join " "}; label="date_time"},@{expression={"$($_.verdict.split("=")[1])"}; label="verdict"},@{expression={"$($_.src_ip.split("=")[1])"}; label="src_ip"},@{expression={"$($_.dst_ip.split("=")[1])"}; label="dst_ip"},@{expression={"$($_.src_prt.split("=")[1])"}; label="src_prt"},@{expression={"$($_.dst_prt.split("=")[1])"}; label="dst_prt"},@{expression={"$($_.protocol.split("=")[1])"}; label="protocol"},@{expression={if ($null -ne $_.incoming) {"RECEIVE"} else {"SEND"}}; label="direction"}
            return [System.Collections.ArrayList]$retval
        }
    }
    
    class lmfao 
        {
            # Store and Fetch
            static [ParseRule[]] $parsers
    
            # Create instance
            [ParseRule] parse([string] $file_path, [string]$os) {
                return New-Object -TypeName $os -ArgumentList $file_path,$os
            }
            # Create instance overload
            [ParseRule] parse([string] $file_path) {
                $os = if ($this.test_os) {"Linux"} else {"Windows"}
                return New-Object -TypeName $os -ArgumentList $file_path
            }
        }
    $test = [lmfao]::new()
    $process = $test.parse($_.split(",")[0],$_.split(",")[1])
    $val = @()
    $val += $process.read()
    $val
    <# $val value looks like this...
    date_time : 2020-08-06 06:25:20
    verdict   : ALLOW
    src_ip    : 123.21.32.5
    dst_ip    : 123.21.32.117
    src_prt   : 37314
    dst_prt   : 11211
    protocol  : TCP
    direction : RECEIVE
    #>
} -ThrottleLimit 5

$data_import.count
