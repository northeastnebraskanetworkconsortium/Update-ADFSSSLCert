Param(
    [string]$CertificateURL,
    [string]$CertificatePath,
    [Security.SecureString]$SecurePassword,
    [String]$PlainPassword
)

function Logging {
    param([string]$Message)
    Write-Host $Message
    $Message >> $LogFile
}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Import-Module ADFS
$LogFile = '.\UpdateADFS.log'
Get-Date | Out-File $LogFile -Append

if($CertificateURL) {
    Invoke-WebRequest -Uri $CertificateURL -UseBasicParsing -OutFile "C:\certificate.pfx"
    $CertificatePath = 'C:\certificate.pfx'
}

if($SecurePassword) {
    $password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PfxPassword))
} elseif($PlainPassword) {
    $password = $PlainPassword
} else {
    $password = ""
}

$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
$cert.Import($CertifiatePath,$password,'DefaultKeySet')

Logging -Message "Importing certificate to Cert:\LocalMachine\My"
Import-PfxCertificate -FilePath $CertificatePath -CertStoreLocation Cert:\LocalMachine\My -Password ($password | ConvertTo-SecureString -AsPlainText -Force)
Logging -Message "Updating ADFS Certificate"
Set-AdfsSslCertificate -Thumbprint $cert.Thumbprint
Set-AdfsCertificate -CertificateType Service-Communications -Thumbprint $cert.Thumbprint
    
Logging -Message "Restarting adfssrv"
Restart-Service adfssrv
