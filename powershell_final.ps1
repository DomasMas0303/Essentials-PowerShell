param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({
        try {
            [System.Net.IPAddress]::Parse($_)
            $true
        } catch {
            Throw "Invalid IP address format for 'ip_address_1'. Please provide a valid IP address."
        }
    })]
    [string]$ip_address_1,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateScript({
        try {
            [System.Net.IPAddress]::Parse($_)
            $true
        } catch {
            Throw "Invalid IP address format for 'ip_address_2'. Please provide a valid IP address."
        }
    })]
    [string]$ip_address_2,

    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateScript({
        if ($_ -match '^\d{1,2}$') {
            $true
        } else {
            try {
                [System.Net.IPAddress]::Parse($_)
                $true
            } catch {
                Throw "Invalid network mask format. Please provide a valid subnet mask."
            }
        }
    })]
    [string]$network_mask
)

# Function to convert subnet mask from single/double-digit format to standard format
function Convert-SubnetMask {
    param (
        [int]$networkBits
    )

    $bitArray = [System.Collections.BitArray]::new(32, $false)
    for ($i = 0; $i -lt $networkBits; $i++) {
        $bitArray.Set($i, $true)
    }

    $maskBytes = [System.Byte[]]::new(4)
    $bitArray.CopyTo($maskBytes, 0)
    $network_mask = [System.Net.IPAddress]::new($maskBytes)
    return $network_mask.ToString()
}

# Check if the subnet mask is in single or double-digit format and convert if necessary
if ($network_mask -match '^\d{1,2}$') {
    $network_mask = Convert-SubnetMask -networkBits $network_mask
} else {
    try {
        $network_mask = [System.Net.IPAddress]::Parse($network_mask)
    } catch {
        Write-Error "Invalid subnet mask format. Please provide a valid subnet mask."
        return
    }
}

# Function to compare IP addresses on the same network
function Compare-IPsOnSameNetwork {
    param (
        [string]$ip_address_1,
        [string]$ip_address_2,
        [string]$network_mask
    )

    # Convert IP addresses and subnet mask to integers
    $ip1 = [System.Net.IPAddress]::Parse($ip_address_1).GetAddressBytes()
    $ip2 = [System.Net.IPAddress]::Parse($ip_address_2).GetAddressBytes()
    $subnet = [System.Net.IPAddress]::Parse($network_mask).GetAddressBytes()

    # Calculate the network address using bitwise AND operation
    $network1 = @()
    $network2 = @()
    for ($i = 0; $i -lt 4; $i++) {
        $network1 += $ip1[$i] -band $subnet[$i]
        $network2 += $ip2[$i] -band $subnet[$i]
    }

    # Convert network addresses back to strings
    $networkAddress1 = [string]::Join(".", $network1)
    $networkAddress2 = [string]::Join(".", $network2)

    # Compare the network portions and return the result
    return $networkAddress1 -eq $networkAddress2
}

# Call the function to check if the IP addresses are on the same network
try {
    if (Compare-IPsOnSameNetwork -ip_address_1 $ip_address_1 -ip_address_2 $ip_address_2 -network_mask $network_mask) {
        Write-Host "yes"
        exit 0
    } else {
        Write-Host "no"
    }
} catch {
    Write-Error $_
    exit 1
}
