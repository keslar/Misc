# Check if the required module is available
if ( -NOT (Get-Module -ListAvailable -Name "VpnClient") ) {
   throw "The VpnClient module is not available. Please install it to manage VPN connections."
}
# Check if the required module is available
if ( -NOT (Get-Module -ListAvailable -Name "VirtualDesktop") ) {
   throw "The VirtualDesktop module is not available. Please install it to manage virtual desktops."
}


# Import the VpnClient module
Import-Module VpnClient -ErrorAction Stop
Import-Module VirtualDesktop -ErrorAction Stop

# Update these variables for your environment
$vpnName = "<name of the VPN connection to use>"
$desktopName = "<name of the virtual desktop to use>"
$RDPFilePath = "<fully qualified path and filename of the RDP settings file to open>"

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check if the VPN connection exists
function isVPNConnected {
   param (
      [string]$vpnName
   )

   # Check if VPN is running, if not start it
   $vpn = Get-VPNConnection -Name $vpnName -ErrorAction SilentlyContinue
   if (($null -ne $vpn) -AND ($vpn.ConnectionStatus -eq "Connected")) {
      return $true
   }
   else {
      return $false
   }
}

# Create a progress dialog box
# Create the form
$form = New-Object System.Windows.Forms.Form -Property @{
   Text            = "Remote Desktop Connection"
   Size            = New-Object System.Drawing.Size(400, 200)
   StartPosition   = 'CenterScreen'
   FormBorderStyle = 'FixedSingle'
   BackColor       = 'White'
}


# Create the label

$label = New-Object System.Windows.Forms.Label -Property @{
   Text     = "Not started yet . . ."
   AutoSize = $true
   Location = New-Object System.Drawing.Point(10, 20)
   Size     = New-Object System.Drawing.Size(280, 20)
}
$form.Controls.Add($label)


# Switch to HQ Desktop
Write-Host "Switching to $() Desktop . . ."
Switch-Desktop -Desktop $desktopName -ErrorAction Stop

# Focus on the textbox when the form is shown
$form.Show()

Write-Host "Checking VPN connection [$vpnName] . . ."
$label.Text = "Checking VPN connection [$vpnName] . . ."

if ( -NOT (isVPNConnected( $vpnName )) ) {
   Write-Host "Starting VPN connection [($vpnName)] . . ."
   $label.Text = "Starting VPN connection [($vpnName)] . . ."
   try {
      # Connect-VpnConnection -Name $vpnName -PassThru -Force -ErrorAction Stop
      rasdial $vpnName '' ''
      # Wait for a few seconds to ensure the VPN connection is established
      Start-Sleep -Seconds 2
   }
   catch {
      throw "Could not start the VPN connection. Stopping."
   }
}

if ( -NOT (isVPNConnected( $vpnName )) ) {
   throw "Could not establish the VPN connection."
}

# Start the rdp session, do not continue the script until RDP has closed
Write-Host "Starting Remote desktop session . . ."
$label.Text = "Starting Remote desktop session . . ."

Start-Process -Wait -FilePath $RDPFilePath


# Teardwon the VPN Connection, if it is still active
if ( isVPNConnected( $vpnName ) ) {
   Write-Host "Stopping VPN connection [($vpnName)] . . ."
   $label.Text = "Stopping VPN connection [$vpnName] . . ."
   try {
      rasdial $vpnName /DISCONNECT
   }
   catch {
      throw "Could not close the VPN connection."
   }
}

$form.Close()
$form.Dispose()
