#!/usr/local/microsoft/powershell/6/pwsh
"hello"

<# New-Item -Path './test' -ItemType Directory
#>
function addUsers{
    param (
        $path,
        $ou,
        $dc,
        $fulDomainName
    )
    $OU=$ou
    $DC=$dc
    if (Get-ADOrganizationalUnit  -F {Name -eq "$OU"}) {Write-Warning "ou has already exist!" } 
    else {
        Write-Log "create ou $OU"
        New-ADOrganizationalUnit  -Name  $OU  -Path  $DC
    }
    $users=Import-Csv  -Path $path
    foreach ($user in $users)
    {
        $Name = $user.$FullName
        $SamAccountName = $user.NetAccount
        $GiveName = $user.$Firstname
        $Surname    = $user.Lastname
        $Department = $user.Depart
        $Title  = $user.$Title

        #Check if the user account already exists in AD
        if (Get-ADUser -F {SamAccountName -eq $SamAccountName})
        {
            Write-Warning "The user $Name has already exist in Active Directory."
        }else
        {
            New-ADUser -SamAccountName $SamAccountName -Name $Name -GivenName $GiveName `
            -Surname $Surname -Name $Name -Title $Title -Department $Department `
            -Path $OU 
        }
    }
    #create home &put full control permissions
        $homeDir="C:\home"
        $name="$Name"

    if(Test-Path $path -PathType Container){
        Write-Warning "$path has already exist"
    }else{
        $NewFolder = New-Item -Path $homeDir -Name $name -ItemType "Directory"
        $Rights = [System.Security.AccessControl.FileSystemRights]"FullControl,Modify,ReadAndExecute,ListDirectory,Read,Write"
        $InheritanceFlag = @([System.Security.AccessControl.InheritanceFlags]::ContainerInherit,[System.Security.AccessControl.InheritanceFlags]::ObjectInherit)
        $PropagationFlag = [System.Security.AccessControl.PropagationFlags]::None
        $objType =[System.Security.AccessControl.AccessControlType]::Allow
        $objUser = New-Object System.Security.Principal.NTAccount "$fullDomainName\$Name"
        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule  ($objUser, $Rights, $InheritanceFlag, $PropagationFlag, $objType)
        $ACL = Get-Acl -Path $NewFolder
        $ACL.AddAccessRule($objACE)
        Set-ACL -Path $NewFolder.FullName -AclObject $ACL
    }
}

addUsers "C:\name" "myUsers" "DC:scylhy,DC:github,DC:io" "scylhy.github.io"