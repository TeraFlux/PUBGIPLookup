# PUBG IP Lookup

Powershell script that finds the IP address your pubg game is connected to, and the corresponding region that's in.

## Getting Started

-Launch PUBG, enter a game, then run the script.
-To run the script, save the .ps1 locally, open a powershell window in that directory, 
then pass the interface name in as a parameter, you can hit [tab] to cycle through your available interfaces until you find the right one

Ex:     

PS C:\getPubgIP.ps1 -InterfaceName 'Aquantia AQtion 10Gbit Network Adapter (NDIS 6.50 Miniport)'
34.201.7.192 - Ashburn, VA [United States]

### Prerequisites

WireShark https://www.wireshark.org/download.html
Powershell 5+

## License

This project is licensed under the MIT License
