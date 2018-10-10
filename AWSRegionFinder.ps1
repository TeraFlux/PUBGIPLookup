function filterRemoteIPs($remoteIPs){
    $remoteIPList=@()
    foreach($ip in $remoteIPs){
        if($ip -ne "0.0.0.0" -and $ip -notmatch "\:" -and $ip -ne "127.0.0.1"){
            $remoteIPList+=[IPAddress]$ip
        }
    }
    return $remoteIPList
}

function IPToDecimal([IPAddress]$ip){
    $bytes = $ip.GetAddressBytes()
    if ([BitConverter]::IsLittleEndian) {
            [Array]::Reverse($bytes)
    }
    [BitConverter]::ToUInt32($bytes, 0)
}

function mapRegionNames(){
    $regionNames=@{}
    $regions=Invoke-WebRequest -Uri "https://docs.aws.amazon.com/general/latest/gr/rande.html"
    $regionTable=$regions.ParsedHtml.getElementById("w128aab7d113b5")
    foreach($tr in $regionTable.getElementsByTagName("tr")){
        $tds=$tr.getElementsByTagName("td")
        $regionName=$tds[0].innerText
        $AWSName=$tds[1].innerText
        if($regionName -ne $null){
            $regionNames[$AWSName]=$regionName
        }
    }
    return $regionNames
}

$AWSEndpointData=@{}
$AWSEndpoints=((Invoke-WebRequest "https://ip-ranges.amazonaws.com/ip-ranges.json") | ConvertFrom-Json).prefixes
foreach($AWSEndpoint in $AWSEndpoints){
    [IPAddress]$ipAddress=$AWSEndpoint.ip_prefix.split("/")[0]
    [int]$slashNotation=$AWSEndpoint.ip_prefix.split("/")[1]
    $networkAddresses=[math]::pow(2,32-$slashNotation)
    $startDec=(IPToDecimal $ipAddress)
    $AWSEndpointData[$AWSEndpoint.ip_prefix]=@{
        "StartRange"=$startDec;
        "EndRange"=($startDec+$networkAddresses);
        "AWSRegion"=$AWSEndpoint.region
    }
}
$AWSRegionNameMapping=mapRegionNames

try {
    $processId=(get-process "TslGame" -ErrorAction Stop).Id
    $RemoteIPList=(Get-NetTCPConnection -OwningProces $processId).RemoteAddress | select -Unique | % {filterRemoteIPs $_}
    foreach($remoteIP in $RemoteIPList){
        $decimalIP=IPToDecimal ($remoteIP.IPAddressToString)
        foreach($AWSRange in $AWSEndpointData.keys){
            $startRange=$AWSEndpointData[$AWSRange].StartRange
            $endRange=$AWSEndpointData[$AWSRange].EndRange
            $region=$AWSEndpointData[$AWSRange].AWSRegion
            if($decimalIP -gt $startRange -and $decimalIP -lt $endRange){
                if($AWSRegionNameMapping.ContainsKey($region)){
                    $regionName=$AWSRegionNameMapping[$region]
                }else{
                    $regionName=$region
                }
                Write-Output "$remoteIP - $regionName"
            }
        }
    }
}catch{
    Write-Error "PUBG process is not running"
}