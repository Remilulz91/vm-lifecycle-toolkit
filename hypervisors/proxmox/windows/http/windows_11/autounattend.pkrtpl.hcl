<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        
        <component name="Microsoft-Windows-PnpCustomizationsWinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <DriverPaths>
                <PathAndCredentials wcm:action="add" wcm:keyValue="1"><Path>D:\vioscsi\w11\amd64</Path></PathAndCredentials>
                <PathAndCredentials wcm:action="add" wcm:keyValue="2"><Path>D:\viostor\w11\amd64</Path></PathAndCredentials>
                <PathAndCredentials wcm:action="add" wcm:keyValue="3"><Path>D:\NetKVM\w11\amd64</Path></PathAndCredentials>
                
                <PathAndCredentials wcm:action="add" wcm:keyValue="4"><Path>E:\vioscsi\w11\amd64</Path></PathAndCredentials>
                <PathAndCredentials wcm:action="add" wcm:keyValue="5"><Path>E:\viostor\w11\amd64</Path></PathAndCredentials>
                <PathAndCredentials wcm:action="add" wcm:keyValue="6"><Path>E:\NetKVM\w11\amd64</Path></PathAndCredentials>
                
                <PathAndCredentials wcm:action="add" wcm:keyValue="7"><Path>F:\vioscsi\w11\amd64</Path></PathAndCredentials>
                <PathAndCredentials wcm:action="add" wcm:keyValue="8"><Path>F:\viostor\w11\amd64</Path></PathAndCredentials>
                <PathAndCredentials wcm:action="add" wcm:keyValue="9"><Path>F:\NetKVM\w11\amd64</Path></PathAndCredentials>
            </DriverPaths>
        </component>

        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Path>cmd /c reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <Path>cmd /c reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <Path>cmd /c reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <Path>cmd /c reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassStorageCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
                <RunSynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <Path>cmd /c reg add "HKLM\SYSTEM\Setup\LabConfig" /v BypassCPUCheck /t REG_DWORD /d 1 /f</Path>
                </RunSynchronousCommand>
            </RunSynchronous>

            <UserData>
                <ProductKey>
                    <Key>VK7JG-NPHTM-C97JM-9MPGT-3V66T</Key>
                    <WillShowUI>OnError</WillShowUI>
                </ProductKey>
                <AcceptEula>true</AcceptEula>
                <FullName>${admin_username}</FullName>
                <Organization>Packer</Organization>
            </UserData>

            <DiskConfiguration>
                <Disk wcm:action="add">
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                    <CreatePartitions>
                        <CreatePartition wcm:action="add"><Order>1</Order><Type>Primary</Type><Size>500</Size></CreatePartition>
                        <CreatePartition wcm:action="add"><Order>2</Order><Type>EFI</Type><Size>100</Size></CreatePartition>
                        <CreatePartition wcm:action="add"><Order>3</Order><Type>MSR</Type><Size>16</Size></CreatePartition>
                        <CreatePartition wcm:action="add"><Order>4</Order><Type>Primary</Type><Extend>true</Extend></CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add"><Order>1</Order><PartitionID>1</PartitionID><Format>NTFS</Format><Label>WINRE</Label><TypeID>DE94BBA4-06D1-4D40-A16A-BFD50179D6AC</TypeID></ModifyPartition>
                        <ModifyPartition wcm:action="add"><Order>2</Order><PartitionID>2</PartitionID><Format>FAT32</Format><Label>System</Label></ModifyPartition>
                        <ModifyPartition wcm:action="add"><Order>3</Order><PartitionID>4</PartitionID><Format>NTFS</Format><Label>Windows</Label></ModifyPartition>
                    </ModifyPartitions>
                </Disk>
                <WillShowUI>OnError</WillShowUI>
            </DiskConfiguration>

            <ImageInstall>
                <OSImage>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>4</PartitionID>
                    </InstallTo>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/INDEX</Key>
                            <Value>1</Value>
                        </MetaData>
                    </InstallFrom>
                    <WillShowUI>OnError</WillShowUI>
                </OSImage>
            </ImageInstall>
        </component>

        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <SetupUILanguage><UILanguage>fr-FR</UILanguage></SetupUILanguage>
            <InputLocale>040c:0000040c</InputLocale>
            <SystemLocale>fr-FR</SystemLocale>
            <UILanguage>fr-FR</UILanguage>
            <UserLocale>fr-FR</UserLocale>
        </component>
    </settings>

    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            <ComputerName>${hostname}</ComputerName>
            <TimeZone>Romance Standard Time</TimeZone>
        </component>
    </settings>

    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State">
            
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <ProtectYourPC>1</ProtectYourPC>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
            
            <UserAccounts>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>${admin_password}</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Description>Local Administrator</Description>
                        <DisplayName>${admin_username}</DisplayName>
                        <Group>Administrators</Group>
                        <Name>${admin_username}</Name>
                    </LocalAccount>

                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>${user_password}</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Description>Standard User</Description>
                        <DisplayName>${user_username}</DisplayName>
                        <Group>Users</Group>
                        <Name>${user_username}</Name>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>

            <AutoLogon>
                <Password>
                    <Value>${admin_password}</Value>
                    <PlainText>true</PlainText>
                </Password>
                <Username>${admin_username}</Username>
                <Enabled>true</Enabled>
                <LogonCount>1</LogonCount>
            </AutoLogon>

            <FirstLogonCommands>
                <SynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <CommandLine>cmd.exe /c powercfg.exe /change standby-timeout-ac 0 &amp; powercfg.exe /change monitor-timeout-ac 0 &amp; powercfg.exe /change disk-timeout-ac 0</CommandLine>
                </SynchronousCommand>

                <SynchronousCommand wcm:action="add">
                    <Order>2</Order>
                    <CommandLine>cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"</CommandLine>
                </SynchronousCommand>
                
                <SynchronousCommand wcm:action="add">
                    <Order>3</Order>
                    <CommandLine>cmd.exe /c powershell -Command "$drive = (Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 5 | Where-Object { Test-Path ($_.DeviceID + '\virtio-win-guest-tools.exe') }).DeviceID; if ($drive) { Start-Process ($drive + '\virtio-win-guest-tools.exe') -ArgumentList '/S' -Wait }"</CommandLine>
                </SynchronousCommand>

                <SynchronousCommand wcm:action="add">
                    <Order>4</Order>
                    <CommandLine>cmd.exe /c powershell -Command "Start-Sleep -Seconds 15"</CommandLine>
                </SynchronousCommand>

                <SynchronousCommand wcm:action="add">
                    <Order>5</Order>
                    <CommandLine>cmd.exe /c powershell -Command "$profile = Get-NetConnectionProfile; Set-NetConnectionProfile -Name $profile.Name -NetworkCategory Private"</CommandLine>
                </SynchronousCommand>
                
                <SynchronousCommand wcm:action="add">
                    <Order>6</Order>
                    <CommandLine>cmd.exe /c powershell -Command "$drive = (Get-CimInstance Win32_LogicalDisk | Where-Object DriveType -eq 5 | Where-Object { Test-Path ($_.DeviceID + '\OpenSSH-Win64.msi') }).DeviceID; if ($drive) { Start-Process msiexec.exe -ArgumentList ('/i ' + $drive + '\OpenSSH-Win64.msi /quiet /norestart') -Wait }"</CommandLine>
                </SynchronousCommand>
                
                <SynchronousCommand wcm:action="add">
                    <Order>7</Order>
                    <CommandLine>cmd.exe /c powershell -Command "Set-Service -Name sshd -StartupType 'Automatic'; Start-Service sshd; New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22"</CommandLine>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
