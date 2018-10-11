[CmdletBinding()]
Param ()
DynamicParam { 
    function parseWireSharkAdapters($wiresharkAdapters){
        $wiresharkMapping=@{}
        foreach($adapter in $wiresharkAdapters){
            $matched=$adapter -match "(\{.*\})"
            $guid=$matches[1]
            $wiresharkMapping.Add($guid, $adapter.split(".")[0])
        }
        return $wiresharkMapping
    }
    function mapNICToWireSharkIF($nicproperties,$wiresharkMapping){
        $friendlyMapping=@{}
        foreach($nic in $nicproperties){
            $nicGuid=$nic.interfaceguid
            $friendlyMapping.Add($nic.ifDesc, $wiresharkMapping[$nicGuid])
        }
        return $friendlyMapping
    }

    $wiresharkAdapters=& "C:\Program Files\Wireshark\tshark.exe" "-D"
    $wiresharkMapping = parseWireSharkAdapters $wiresharkAdapters
    $ifMapping=mapNICtoWiresharkIF (Get-NetAdapter) $wiresharkMapping
    #configure dynamic params
    $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
    $ParamName_InterfaceName = 'InterfaceName'
    $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
    $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
    $ParameterAttribute.Mandatory = $true
    $ParameterAttribute.Position = 0
    $AttributeCollection.Add($ParameterAttribute)
    #add param validation set
    $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($ifMapping.keys)
    $AttributeCollection.Add($ValidateSetAttribute)
    $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParamName_InterfaceName, [string], $AttributeCollection)
    $RuntimeParameterDictionary.Add($ParamName_InterfaceName, $RuntimeParameter)
    return $RuntimeParameterDictionary

}
Process{
    $interfaceId=$ifMapping[$PSBoundParameters['InterfaceName']]
    $udpPorts=(Get-NetUDPEndpoint -OwningProcess (Get-Process "TSLGame").Id).LocalPort
    $pubips=@()
    foreach ($port in $udpPorts) {
        if ($port -eq 27015) {continue}
        $args = ("-i", $interfaceId, "-c", 1, "-a", "duration:1", "-f", "src port $port", "-n", "-T", "fields", "-e", "ip.dst")
        $ip = & "C:\Program Files\Wireshark\tshark.exe" $args 2> Out-Null
        if($ip -ne $null){
            $ipinfo=invoke-webrequest "http://ip-api.com/json/$ip" | ConvertFrom-Json
            $formattedRegion="{0}, {1} [{2}]" -f $ipinfo.city, $ipinfo.region, $ipinfo.country
            Write-Output "$ip - $formattedRegion"
        }
    }
}