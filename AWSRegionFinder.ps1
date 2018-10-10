function getRemoteIPs($remoteIPs){
    $remoteIPList=@()
    foreach($ip in $remoteIPs){
        if($ip -ne "0.0.0.0" -and $ip -notmatch "\:"){
            $remoteIPList+=[IPAddress]$ip
        }
    }
    return $remoteIPList
}

function IPToDecimal($ip){
    $bytes = $ip.GetAddressBytes()
    if ([BitConverter]::IsLittleEndian) {
            [Array]::Reverse($bytes)
    }
    [BitConverter]::ToUInt32($bytes, 0)
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

$RemoteIPList=(Get-NetTCPConnection).RemoteAddress | % {getRemoteIPs $_}
foreach($remoteIP in $RemoteIPList){
    $decimalIP=IPToDecimal $remoteIP
    foreach($AWSRange in $AWSEndpointData){
        if($decimalIP -gt $AWSRange.StartRange -and $decimalIP -lt $AWSRange.EndRange){
            Write-Output "$remoteIP - $($AWSRange.EndRange)"
        }
    }
}