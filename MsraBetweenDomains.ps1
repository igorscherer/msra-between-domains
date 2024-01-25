#Descricao: This script will ask for the credentials on the older Windows domain only once to store it and useit when necessary, it will stays opened so you dont 
# need to insert the credentials every time, this script will help you if you're migrating the domain on a medium-large network and need to use the msra tool from windows
#Creation: 23/01/2024
#Author: Igor Scherer

#Consts for global use
$Server = "ServerName"
$OldDomain = "OLD.DOMAIN"
$NewDomain = "NEW.DOMAIN"
$OuToTest = "Some OU on your older domain" #Change this to some OU inside your older domain

#This function tries to resolve the dns of the computer and obtain the domain name from it
function Resolve-DomainName {
    param (
        [string]$Target
    )

    try {
        #Try to resolve the DNS name by selecting only the first line of the Resolve-DnsName output
        $dnsResult = Resolve-DnsName -Name $Target.ToUpper() -ErrorAction Stop | select name | Select-Object * -first 1

        #Clears the result, leaving only the domain name
        $domainName = "$dnsResult".Replace("@{Name=", "").Replace($Target.ToUpper(),"").Replace("}", "").TrimStart(".").ToUpper()
        return $domainName
    } catch {
          #Displays an error if unable to resolve
          Write-Host "Couldn't resolve the dns name for: $Target"
    }
}
#Function responsible for checking whether the user is valid
function Validate-User(){
    #Request credentials for the old domain, if it is empty, request again
    while($User -eq $null){
        $User = Get-Credential -Message "Insert the password for the old domain" -User "$OldDomain\$($env:USERNAME)"
    }    
    #Validates whether the username entered previously is valid
	try{
        $success = Get-ADGroup -Filter 'Name -eq $OuToTest' -Server $Server -Credential $User -ErrorAction Stop
    }
    catch {
	    Write-Host "ERROR: Incorrect credentials"
        Write-Host "Press enter to exit..."
        Read-Host
        exit
    }
    return $User
}

$OldDomainCredentials = Validate-User

#Main loop of the script, in which it requests the remote computer and then continues with the checks
for(){
	Write-Host "Insert the name of the remote computer: " -NoNewline
	$RemoteComputer = Read-Host

	if($RemoteComputer){
		$RemoteComputer = $RemoteComputer.split('.')[0]
		$RemoteComputerDomain = Resolve-DomainName -Target $RemoteComputer.ToUpper()
		#Tests whether the computer is on the old domain, if it is, it requests the credentials from the old domain and opens the msra with the credentials provided
		if($RemoteComputerDomain -eq $OldDomain){
			Write-Host "Computer is on the older domain: $OldDomain"
			try{
				#Start Remote Assistance(msra.exe /offerra) with the credentials provided through cmd, as it doesn't work starting directly :(
				Start-Process "C:\Windows\System32\cmd.exe" -Credential $OldDomainCredentials -ArgumentList "/C C:\Windows\System32\msra.exe /offerra $RemoteComputer" -WindowStyle Hidden
			}
			catch{
				Write-Host "There was an error executing with: /user:$OldDomain\$($env:USERNAME)"
				Write-Host $_.FullyQualifiedErrorId
			}
		}

		#Test if the computer is on the new domain, if so, it opens the msra normally
		elseif($RemoteComputerDomain -eq "$NewDomain"){
			Write-Host "Computer is already on the newer domain: $NewDomain"
			try{
				#Start Remote Assistance with the credentials provided by Windows
				Start-Process "C:\Windows\System32\msra.exe" -ArgumentList "/offerra $RemoteComputer"
			}
			catch{
				Write-Host "There was an error executing with: /user:$NewDomain\$($env:USERNAME)"
				Write-Host $_.FullyQualifiedErrorId
			}
		}
		else{
			Write-Host "Couldn't find the domain of the computer"
		}
	}
}
