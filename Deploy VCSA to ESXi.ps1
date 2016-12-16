<#
.SYNOPSIS
   The script creates and configures a complete vSphere environment based on setting in a multi-tab excel file.
.DESCRIPTION
   Functionality:
   1. Deploy multiple vcsa from ovf.
	  a. Deployments can be any supported e.g. PSC, vCenter, Stand alone, Combined, etc.
	  b. Can be deployed to different networks and different hosts.
	  c. Supports different disk modes e.g. thin, thick, thick eager zero.
   2. Configurations
	  a. Join to a windows domain.
	  b. Set windows domain as primary identity source.
	  c. Add windows group as Administrative group to PSC.
	  d. Create Datacenters.
	  e. Create Folders.
	  f. Create Roles.
	  g. Create Permissions.
	  h. Create vdSwitches.
	  i. Create Port Groups/VLANs
	  j. Create OS customizations.
	  k. Create and Replace Certs from an external windows CA for:
		 i.   VCSA Machine Cert.
		 ii.  vmdir Cert.
		 iii. Solution User Certs.
	  i. Configure Services for Autdeploy, Network Dump, and TFTP.
	  j. Add licenses and assign licenses.
	  k. Import VMHost Profile and set VMHost Profile Root Password.
	  l. Configure Autodeploy Rules.
	  
	To be done:
	1. Resolve correctly closing Excel so that it does not stay in memory.
	2. Reconfigure vdswitch creation for full flexibility.
	3. Test and add functionality for multi part certificate replacement.
	4. Create certificates for Load Balancers.
	5. Test VMCA certificate deployment.
	6. Test various other configurations of deployment.
	7. Add prompt for credentials instead of reading from Excel.
   
.PARAMETER
   None.
.EXAMPLE
   <An example of using the script>
.REQUIREMENTS
	Programs:
		1. OpenSSL 1.0.2h x64 - C:\OpenSSL-Win64
		2. Ovftool 4.0.1
		3. Excel 2010+
		4. Powershell 3+
		5. PowerCli 5.8+
		
	Other:
		1. The Certificate templates for VMWare must be created on the Windows CA before running the script.
		2. vsphere-config.xlsx file.
		3. vmware-vcsa file from the vcsa iso.
		4. DNS entries for the vcsas must be added before runing the script.
		
.SOURCES
	http://www.derekseaman.com/2015/02/vsphere-6-0-install-pt-1-introduction.html
	http://orchestration.io/2014/05/19/using-powercli-and-ovftool-to-move-vms-between-vcenters/
	https://community.whatsupgold.com/library/powershellscripts/http_status_code_check_with_powershell
	http://huddledmasses.org/blog/validating-self-signed-certificates-properly-from-powershell/
	http://www.lazywinadmin.com/2014/03/powershell-read-excel-file-using-com.html
	https://github.com/lamw/vghetto-scripts/blob/master/shell/deploy_vcsa6_replicated_psc_to_vc.sh
	http://www.kanap.net/2014/12/vcsa-vcenter-server-appliance-part-4-deploy-ca-signed-certificates/
	https://myvirtualife.net/2015/01/21/vsphere-6-certificate-lifecycle-management/
	http://www.definit.co.uk/2015/07/vsphere-6-ha-sso-psc-with-netscaler-vpx-load-balancer-for-vrealize-automation/
	http://wojcieh.net/vcenter-server-6-replacing-ssl-certificates-with-custom-vmca/
	https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2111219
	http://blog.cloudinfra.info/vmware/vsphere-6-0-install-12-psc-machine-certificate/
	https://haveyoutriedreinstalling.com/2016/03/25/caution-solution-user-certificates-in-vsphere-6-0/
	http://www.vhersey.com/2011/11/powercli-to-check-for-vmware-toolsok/
	https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2116018
	http://grokthecloud.com/vcsa-tftp-server/
	http://www.vmwarebits.com/content/enable-tftp-service-and-firewall-rules-vcenter-6-appliance-autodeploy-and-make-them
	https://communities.vmware.com/thread/545899?sr=inbox
	http://www.lucd.info/2012/01/15/change-theroot-password-in-hosts-and-host-profiles/
	http://www.vtagion.com/adding-license-keys-vcenter-powercli/
	https://virtualhobbit.com/2015/07/17/building-an-advanced-lab-using-vmware-vrealize-automation-part-6-deploy-and-configure-the-vcenter-server-appliance/
	https://blogs.vmware.com/vsphere/2016/11/getting-started-new-image-builder-gui-vsphere-6-5.html
	
	
.ACKNOWLEDGEMENTS
	I'd like to thank the following people who's blogs/scripts/help/moral support/etc. I used in to create this script.
	
	1.  Derek Seamans			- www.derekseaman.com
	2.  William Lam				- www.virtuallyghetto.com
	3.  Chris Greene			- orchestration.io
	4.  RJ Davis				- community.whatsupgold.com
	5.  Joel "Jaykul" Bennett 	- huddledmasses.org/
	6.  Francois-Xavier Cat 	- www.lazywinadmin.com/
	7.  Friedrich Eva			- www.kanap.net/
	8.  Andrea Casin			- myvirtualife.net
	9.  Sam McGeown				- www.definit.co.uk
	10. Wojciech Marusiak		- wojcieh.net
	11. blog.cloudinfra.info
	12. F�idhlim O'Leary		- haveyoutriedreinstalling.com
	13. Alan Renouf				- www.virtu-al.net
	14. Jeramiah Dooley			- Netapp
	15. Aaron Patten			- Netapp
	16. VMWare Support
	17. John Dwyer				- grokthecloud.com
	18. Rob Bastiaansen 		- www.vmwarebits.com
	19.	Luc Deneks				- communities.vmware.com/people/LucD and www.lucd.info
	20. Brian Graf				- www.vtagion.com
	21. Mark Brookfield			- vitualhobbit.com
	22. Eric Gray				- blogs.vmware.com
	
	
Functions start at line 139
Main program starts at line 1000
	
.AUTHOR
	Michael van Blijdesteijn - Highbridge Capital Management LLC.
	michael.vanblijdestein@highbridge.com
#>

# Clear the screen.
cls

<# Functions Lines 156 - 1159
List:							Used:	function Dependency:
1.  Available					  Y
2. 	ConfigureAutoDeploy			  Y		ExecuteScript
3.	ConfigureAutoDeployRules	  Y		Set-VMHostProfileExtended
4. 	ConfigureIdentity			  Y		ExecuteScript
5. 	ConfigureLicensing			  Y
6. 	ConfigureNetdumpster		  Y		ExecuteScript
7. 	ConfigureTFTP				  Y		ExecuteScript
8.  Deploy						  Y
9.  CreateFolders				  Y		Separatorline
10. CreateRoles					  Y		Separatorline
11. CreatePermissions			  Y		Separatorline
12. ExecuteScript				  Y		Separatorline
13. CopyFiletoServer			  Y		Separatorline
14. Separatorline				  Y
15. ChainCAs					  Y
16. CheckOpenSSL				  Y
17. CreatePEMFiles				  Y
18. CreateCSR					  Y
19. CreateSolutionCSR			  Y
20. CreateVMCACSR				  Y
21. DisplayVMDir				  Y
22. DownloadRoots				  Y
23. MoveUserCerts				  Y
24. OnlineMint					  Y
25. OnlineMintResume			  N
26.	Set-VMHostProfileExtended	  Y
27. TransferCertToNode			  Y		ExecuteScript, CopyFiletoServer
28. UserPEMFiles				  Y		CreatePEMFiles
29. VMCAMint					  N
30. CDDir						  Y
31. CreateVCSolutionCert		  Y		CreateSolutionCSR, OnlineMint, CreatePEMFiles
32. CreatePscSolutionCert		  Y		CreateSolutionCSR, OnlineMint, CreatePEMFiles


#>

# Check to see if the url is available.
function Available ($url) {
	$error.clear()
	$output = $null
	
	Write-Host "`r`n Waiting on $url to resolve.`r`n" -foregroundcolor yellow
	$web = New-Object Net.WebClient
	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true} 
	
	while (!$output) {
		try {$output = $web.DownloadString($url)}
		catch {Start-Sleep -s 30}
	}

	[System.Net.ServicePointManager]::ServerCertificateValidationCallback = $null
	while ((invoke-webrequest -uri $url -UseBasicParsing -TimeoutSec 20).statuscode -ne 200) {
		Write-Host "`r`n $url not ready, sleeping for 60sec.`r`n" -foregroundcolor cyan
		Start-Sleep -s 60
	}
}

# Configure the Autodeploy Service - set certificate, set auto start, register vCenter, and start service.
function ConfigureAutoDeploy ($IP,$hostname,$username,$password,$domain,$vihandle,$vcversion) {
	$commandlist = $null
	$commandlist = @()
	
    # Apply certificate to Autodeploy and Register Autodeploy to vCenter.
	$commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
	$commandlist += "export VMWARE_LOG_DIR=/var/log"
	$commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
	$commandlist += "export VMWARE_DATA_DIR=/storage"
	$commandlist += "/usr/bin/autodeploy-register -R -a $($IP) -u administrator@$($domain) -w `'$password`' -p 80"

	ExecuteScript $commandlist $hostname $username $password $vihandle

	If ($vcversion -eq 6.5) {
		# Set Autodeploy (rbd) startype to Automatic and restart service.
		$commandlist = $null
		$commandlist = @()
		$commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
		$commandlist += "export VMWARE_LOG_DIR=/var/log"
		$commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
		$commandlist += "export VMWARE_DATA_DIR=/storage"
		$commandlist += "/usr/lib/vmware-vmon/vmon-cli --update rbd --starttype AUTOMATIC"
 		$commandlist += "/usr/lib/vmware-vmon/vmon-cli --restart rbd"
        
		# imagebuilder set startype to Automatic and restart service.
		$commandlist += "/usr/lib/vmware-vmon/vmon-cli --update imagebuilder --starttype AUTOMATIC"
 		$commandlist += "/usr/lib/vmware-vmon/vmon-cli --restart imagebuilder"
	}
	Else {
           # Set Autodeploy to Autostart (rbd) and start service, vmware 6.0.
		   $commandlist = $null
		   $commandlist = @()
   		   $commandlist += "/sbin/chkconfig vmware-rbd-watchdog on"
		   $commandlist += "/etc/init.d/vmware-rbd-watchdog start"
	}

	# Service update
	ExecuteScript $commandlist $hostname $username $password $vihandle
}

function ConfigureAutoDeployRules ($rules, $path, $vihandle) {

	Import-Module VMware.DeployAutomation

	echo $rules | Out-String

	# Turn off signature check - needed to avoid errors from unsigned packages/profiles.
	$DeployNoSignatureCheck = $true

	foreach ($rule in $rules) {
		$hpExport = $path + "\" + $rule.ProfileImport
		
		$si = Get-View -Server $vihandle ServiceInstance
		$hpMgr = Get-View -Server $vihandle -Id $si.Content.HostProfileManager
		
		$spec = New-Object VMware.Vim.HostProfileSerializedHostProfileSpec
		$spec.Name = $rule.ProfileName
		$spec.Enabled = $true
		$spec.Annotation = $rule.ProfileAnnotation
		$spec.Validating = $false
		$spec.profileConfigString = (Get-Content -Path $hpExport)
		
		$hpMgr.CreateProfile($spec)
		
		echo $hpMgr | Out-String

		$prof = Get-VMHostProfile -Name $rule.ProfileName -Server $vihandle
		Set-VMHostProfileExtended -Profile $prof -AdminPassword $rule.ProfileRootPassword $vihandle
	
		# Add offline bundles to depot
		$Depotpath = $path + "\" + $rule.SoftwareDepot
		Add-EsxSoftwareDepot $Depotpath

		# Create a new deploy rule.
		$img = Get-EsxImageProfile | ?{$rule.SoftwareDepot.substring(0,$rule.SoftwareDepot.Indexof(".zip"))}
		if ($img.count -gt 1) {$img = $img[1]}
		$img | Out-String
		$pro = Get-VMHostProfile -Server $vihandle | ?{$_.Name -ieq $rule.ProfileName}
		$pro | Out-String
		$clu = Get-Cluster -Server $vihandle | ?{$_.Name -ieq $rule.Cluster}
		$clu | Out-String

		New-DeployRule -Name $rule.RuleName -Item $img, $pro, $clu -Pattern $rule.Pattern
		
		# Activate the deploy rule.
		Add-DeployRule -DeployRule $rule.RuleName

	}

}

# Configure Identity Source - Add AD domain as Native for SSO, Add AD group to Administrator permissions on SSO.
function ConfigureIdentity ($domain,$vcsa_fqdn,$vcsa_root_password,$ad_domain,$ad_group,$vihandle) {
			$sub_domain		= $domain.split(".")[0]
			$domain_ext		= $domain.split(".")[1]
			$commandlist 	= $null
			$commandlist 	= @()
			
			# Active Directory variables
			$AD_admins_group_sid	= (Get-ADgroup -Identity $ad_group).sid.value
			
			# Add AD domain as Native Identity Source
			$commandlist += "/usr/lib/vmidentity/tools/scripts/sso-add-native-ad-idp.sh $ad_domain"
			
			# Set Default SSO Identity Source Domain
			$commandlist += "echo -e `"dn: cn=$domain,cn=Tenants,cn=IdentityManager,cn=Services,dc=$sub_domain,dc=$domain_ext`" >> defaultdomain.ldif"
			$commandlist += "echo -e `"changetype: modify`" >> defaultdomain.ldif"
			$commandlist += "echo -e `"replace: vmwSTSDefaultIdentityProvider`" >> defaultdomain.ldif"
			$commandlist += "echo -e `"vmwSTSDefaultIdentityProvider: $ad_domain`" >> defaultdomain.ldif"
			$commandlist += "echo -e `"-`" >> defaultdomain.ldif"
			$commandlist += "/opt/likewise/bin/ldapmodify -f /root/defaultdomain.ldif -h localhost -p 11711 -D `"cn=Administrator,cn=Users,dc=$sub_domain,dc=$domain_ext`" -w `'$vcsa_root_password`'"
			
			# Add AD vCenter Admins to Component Administrators SSO Group.
			$commandlist += "echo -e `"dn: cn=ComponentManager.Administrators,dc=$sub_domain,dc=$domain_ext`" >> groupadd_cma.ldif"
			$commandlist += "echo -e `"changetype: modify`" >> groupadd_cma.ldif"
			$commandlist += "echo -e `"add: member`" >> groupadd_cma.ldif"
			$commandlist += "echo -e `"member: externalObjectId=$AD_admins_group_sid`" >> groupadd_cma.ldif"
			$commandlist += "echo -e `"-`" >> groupadd_cma.ldif"
			$commandlist += "/opt/likewise/bin/ldapmodify -f /root/groupadd_cma.ldif -h localhost -p 11711 -D `"cn=Administrator,cn=Users,dc=$sub_domain,dc=$domain_ext`" -w `'$vcsa_root_password`'"
			
			# Add AD vCenter Admins to License Administrators SSO Group.
			$commandlist += "echo -e `"dn: cn=LicenseService.Administrators,dc=$sub_domain,dc=$domain_ext`" >> groupadd_la.ldif"
			$commandlist += "echo -e `"changetype: modify`" >> groupadd_la.ldif"
			$commandlist += "echo -e `"add: member`" >> groupadd_la.ldif"
			$commandlist += "echo -e `"member: externalObjectId=$AD_admins_group_sid`" >> groupadd_la.ldif"
			$commandlist += "echo -e `"-`" >> groupadd_la.ldif"
			$commandlist += "/opt/likewise/bin/ldapmodify -f /root/groupadd_la.ldif -h localhost -p 11711 -D `"cn=Administrator,cn=Users,dc=$sub_domain,dc=$domain_ext`" -w `'$vcsa_root_password`'"
			
			# Add AD vCenter Admins to Administrators SSO Group.
			$commandlist += "echo -e `"dn: cn=Administrators,cn=Builtin,dc=$sub_domain,dc=$domain_ext`" >> groupadd_adm.ldif"
			$commandlist += "echo -e `"changetype: modify`" >> groupadd_adm.ldif"
			$commandlist += "echo -e `"add: member`" >> groupadd_adm.ldif"
			$commandlist += "echo -e `"member: externalObjectId=$AD_admins_group_sid`" >> groupadd_adm.ldif"
			$commandlist += "echo -e `"-`" >> groupadd_adm.ldif"
			$commandlist += "/opt/likewise/bin/ldapmodify -f /root/groupadd_adm.ldif -h localhost -p 11711 -D `"cn=Administrator,cn=Users,dc=$sub_domain,dc=$domain_ext`" -w `'$vcsa_root_password`'"
			
			# Add AD vCenter Admins to Certificate Authority Administrators SSO Group.
			$commandlist += "echo -e `"dn: cn=CAAdmins,cn=Builtin,dc=$sub_domain,dc=$domain_ext`" >> groupadd_caa.ldif"
			$commandlist += "echo -e `"changetype: modify`" >> groupadd_caa.ldif"
			$commandlist += "echo -e `"add: member`" >> groupadd_caa.ldif"
			$commandlist += "echo -e `"member: externalObjectId=$AD_admins_group_sid`" >> groupadd_caa.ldif"
			$commandlist += "echo -e `"-`" >> groupadd_caa.ldif"
			$commandlist += "/opt/likewise/bin/ldapmodify -f /root/groupadd_caa.ldif -h localhost -p 11711 -D `"cn=Administrator,cn=Users,dc=$sub_domain,dc=$domain_ext`" -w `'$vcsa_root_password`'"
			
			# Add AD vCenter Admins to Users SSO Group.
			$commandlist += "echo -e `"dn: cn=Users,cn=Builtin,dc=$sub_domain,dc=$domain_ext`" >> groupadd_usr.ldif"
			$commandlist += "echo -e `"changetype: modify`" >> groupadd_usr.ldif"
			$commandlist += "echo -e `"add: member`" >> groupadd_usr.ldif"
			$commandlist += "echo -e `"member: externalObjectId=$AD_admins_group_sid`" >> groupadd_usr.ldif"
			$commandlist += "echo -e `"-`" >> groupadd_usr.ldif"
			$commandlist += "/opt/likewise/bin/ldapmodify -f /root/groupadd_usr.ldif -h localhost -p 11711 -D `"cn=Administrator,cn=Users,dc=$sub_domain,dc=$domain_ext`" -w `'$vcsa_root_password`'"
			
			# Add AD vCenter Admins to System Configuration Administrators SSO Group.
			$commandlist += "echo -e `"dn: cn=SystemConfiguration.Administrators,dc=$sub_domain,dc=$domain_ext`" >> groupadd_sca.ldif"
			$commandlist += "echo -e `"changetype: modify`" >> groupadd_sca.ldif"
			$commandlist += "echo -e `"add: member`" >> groupadd_sca.ldif"
			$commandlist += "echo -e `"member: externalObjectId=$AD_admins_group_sid`" >> groupadd_sca.ldif"
			$commandlist += "echo -e `"-`" >> groupadd_sca.ldif"
			$commandlist += "/opt/likewise/bin/ldapmodify -f /root/groupadd_sca.ldif -h localhost -p 11711 -D `"cn=Administrator,cn=Users,dc=$sub_domain,dc=$domain_ext`" -w `'$vcsa_root_password`'"
			
			# Excute the commands in $commandlist on the vcsa.
			ExecuteScript $commandlist $vcsa_fqdn "root" $vcsa_root_password $vihandle
}

function ConfigureLicensing ($Licenses, $vihandle) {
# http://vniklas.djungeln.se/2012/03/29/a-powercli-function-to-manage-vmware-vsphere-licenses/
	echo $Licenses | Out-String
	Foreach ($License in $Licenses) {
		$LicMgr		= $null
		$AddLic		= $null
		$LicType	= $null
		# Add License Key
		$LicMgr  = Get-View -Server $vihandle ServiceInstance
		$AddLic  = Get-View -Server $vihandle $LicMgr.Content.LicenseManager
		If (!($Addlic.Licenses.LicenseKey | ?{$_ -ieq $license.LicKey})) {
			$LicType = $AddLic.AddLicense($License.LicKey,$null)
		}
		
		If ($LicType.Name -ilike "*vcenter*") {
			# Assign vCenter License
			$vcUuid 		= $LicMgr.Content.About.InstanceUuid
			$vcDisplayName	= $LicMgr.Content.About.Name
			$licAssignMgr	= Get-View -Server $vihandle $AddLic.licenseAssignmentManager
			If ($licAssignMgr) { 
				$licAssignMgr.UpdateAssignedLicense($vcUuid, $License.LicKey, $vcDisplayName)
			}
		}
		Else {
			  # Assign Esxi License
			  $licDataMgr = Get-LicenseDataManager -Server $vihandle
			  for ($i=0;$i -lt $License.ApplyType.Split(",").count;$i++) {
				   switch ($License.ApplyType.Split(",")[$i]) {
					 CL {$viContainer = Get-Cluster -Server $vihandle -Name $License.ApplyTo.Split(",")[$i]}
					 DC {$viContainer = Get-Datacenter -Server $vihandle -Name $License.ApplyTo.Split(",")[$i]}
					 VH {$viContainer = Get-VMHost -Server $vihandle -Name $License.ApplyTo.Split(",")[$i]}
				   }
				   If ($viContainer) {
				   	   $LicData					= New-Object VMware.VimAutomation.License.Types.LicenseData
				   	   $LicKeyEntry				= New-Object Vmware.VimAutomation.License.Types.LicenseKeyEntry
				       $LicKeyEntry.TypeId 		= "vmware-vsphere"
				       $LicKeyEntry.LicenseKey	= $License.LicKey
				       $LicData.LicenseKeys 	+= $LicKeyEntry
				       $LicDataMgr.UpdateAssociatedLicenseData($viContainer.Uid, $LicData)
				       $LicDataMgr.QueryAssociatedLicenseData($viContainer.Uid)
				   }
			  }
		}
	}
}

# Configure Network Dumpster to Auto Start and start service.
function ConfigureNetdumpster ($hostname,$username,$password,$vihandle,$vcversion) {
	$commandlist = $null
	$commandlist = @()

	If ($vcversion -eq 6.5) {
		$commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
		$commandlist += "export VMWARE_LOG_DIR=/var/log"
		$commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
		$commandlist += "export VMWARE_DATA_DIR=/storage"
		$commandlist += "/usr/lib/vmware-vmon/vmon-cli --update netdumper --starttype AUTOMATIC"
		$commandlist += "/usr/lib/vmware-vmon/vmon-cli --start netdumper"
	}
	Else {
		   $commandlist += "/sbin/chkconfig vmware-netdumper on"
		   $commandlist += "/etc/init.d/vmware-netdumper start"
	}
	# Service update
	ExecuteScript $commandlist $hostname $username $password $vihandle
}

# Configure TFTP, set firewall exemption, set service to auto start, start service.
function ConfigureTFTP ($hostname,$username,$password,$vihandle) {
	$commandlist = $null
	$commandlist = @()

	# Set Permanent Firewall Exception
	$commandlist += 'echo -e "{" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "  	\"firewall\": {" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "    	\"enable\": true," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "    	\"rules\": [" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "      	{" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"direction\": \"inbound\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"protocol\": \"tcp\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"porttype\": \"dst\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"port\": \"69\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"portoffset\": 0" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "      	}," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "      {" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"direction\": \"inbound\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"protocol\": \"udp\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"porttype\": \"dst\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"port\": \"69\"," >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "        	\"portoffset\": 0" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "      }" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "    ]" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "  }" >> /etc/vmware/appliance/firewall/tftp'
	$commandlist += 'echo -e "}" >> /etc/vmware/appliance/firewall/tftp'
	# Change all single quotes to double quotes using:
	# sed -i "s/'/\"/g" /etc/vmware/appliance/firewall/tftp
	$commandlist += "echo `"#!/bin/bash`" > /tmp/tftpcmd"
	$commandlist += "echo -n `"sed -i `" >> /tmp/tftpcmd"
	$commandlist += "echo -n `'`"s/`' >> /tmp/tftpcmd"
	$commandlist += "echo -n \`'/ >> /tmp/tftpcmd"
	$commandlist += "echo -n `'\`' >> /tmp/tftpcmd"
	$commandlist += "echo -n `'`"/g`' >> /tmp/tftpcmd"
	$commandlist += "echo -n `'`"`' >> /tmp/tftpcmd"
	$commandlist += "echo -n `" /etc/vmware/appliance/firewall/tftp`" >> /tmp/tftpcmd"
	$commandlist += "chmod a+x /tmp/tftpcmd"
	$commandlist += "/tmp/tftpcmd"
	$commandlist += "rm /tmp/tftpcmd"

	$commandlist += "more /etc/vmware/appliance/firewall/tftp"
	# Enable TFTP service.
	$commandlist += "/sbin/chkconfig atftpd on"
	# Start TFTP service.
	$commandlist += "/etc/init.d/atftpd start"
	$commandlist += "/usr/lib/applmgmt/networking/bin/firewall-reload"
	# Set Firewall Exception until reboot.
	$commandlist += "iptables -A port_filter -p udp -m udp --dport 69 -j ACCEPT"
	
	# Service update
	ExecuteScript $commandlist $hostname $username $password $vihandle
}
				
# Deploy a VCSA.
function Deploy ($parameterlist, $ovftoolpath) {
	$pscs			= @("tiny","small","large","infrastructure")

	$argumentlist	= @()
	$ovftool		= "$ovftoolpath\ovftool.exe"
	
	if ($parameterlist.Action -ine "--version") {
		$argumentlist += "--X:logFile=upload.log"
		$argumentlist += "--X:logLevel=verbose"
		$argumentlist += "--acceptAllEulas"
		$argumentlist += "--skipManifestCheck"
		$argumentlist += "--noSSLVerify"
		$argumentlist += "--X:injectOvfEnv"
		$argumentlist += "--allowExtraConfig"
		$argumentlist += "--X:enableHiddenProperties"
		$argumentlist += "--X:waitForIp"
		$argumentlist += "--sourceType=OVA"
		$argumentlist += "--powerOn"
		$argumentlist += "--net:Network 1=$($parameterlist.esxiNet)"
		$argumentlist += "--datastore=$($parameterlist.esxiDatastore)"
		$argumentlist += "--diskMode=$($parameterlist.DiskMode)"
		$argumentlist += "--name=$($parameterlist.vmName)"
		$argumentlist += "--deploymentOption=$($parameterlist.DeployType)"
		if ($parameterlist.DeployType -inotlike "*infrastructure*") {
			$argumentlist += "--prop:guestinfo.cis.system.vm0.hostname=$($parameterlist.Parent)"}
		$argumentlist += "--prop:guestinfo.cis.vmdir.domain-name=$($parameterlist.SSODomainName)"
		$argumentlist += "--prop:guestinfo.cis.vmdir.site-name=$($parameterlist.SSOSiteName)"
		$argumentlist += "--prop:guestinfo.cis.vmdir.password=$($parameterlist.SSOAdminPass)"
		if ($parameterlist.Action -eq "first" -and $pscs -contains $parameterlist.DeployType) {
			$argumentlist += "--prop:guestinfo.cis.vmdir.first-instance=True"}
		else {
			  $argumentlist += "--prop:guestinfo.cis.vmdir.first-instance=False"
			  $argumentlist += "--prop:guestinfo.cis.vmdir.replication-partner-hostname=$($parameterlist.Parent)"
		}
		$argumentlist += "--prop:guestinfo.cis.appliance.net.addr.family=$($parameterlist.NetFamily)"
		$argumentlist += "--prop:guestinfo.cis.appliance.net.addr=$($parameterlist.IP)"
		$argumentlist += "--prop:guestinfo.cis.appliance.net.pnid=$($parameterlist.Hostname)"
		$argumentlist += "--prop:guestinfo.cis.appliance.net.prefix=$($parameterlist.NetPrefix)"
		$argumentlist += "--prop:guestinfo.cis.appliance.net.mode=$($parameterlist.NetMode)"
		$argumentlist += "--prop:guestinfo.cis.appliance.net.dns.servers=$($parameterlist.DNS)"
		$argumentlist += "--prop:guestinfo.cis.appliance.net.gateway=$($parameterlist.Gateway)"
		$argumentlist += "--prop:guestinfo.cis.appliance.root.passwd=$($parameterlist.VCSARootPass)"
		$argumentlist += "--prop:guestinfo.cis.appliance.ssh.enabled=$($parameterlist.EnableSSH)"
		$argumentlist += "--prop:guestinfo.cis.appliance.ntp.servers=$($parameterlist.NTP)"
		$argumentlist += "--prop:guestinfo.cis.deployment.autoconfig=True"
		$argumentlist += "--prop:guestinfo.cis.ceip_enabled=False"
		$argumentlist += "$($parameterlist.OVA)"
		$argumentlist += "vi://$($parameterlist.esxiRootUser)`:$($parameterlist.esxiRootPass)@$($parameterlist.esxiHost)"
	}
	
	echo $argumentlist | Out-String
	
	return & $ovftool $argumentlist	
}

# Create Folders
function CreateFolders ($folders, $vihandle) {
	Separatorline
	
foreach ($folder in $folders) {
	echo $folder.Name | Out-String
	foreach ($datacenter in get-datacenter -Server $vihandle) {
		if ($folder.datacenter -ieq "all" -or $datacenter.name -ieq $folder.datacenter) {	
			$location = $datacenter | get-folder -name $folder.Location | ?{$_.Parentid -inotlike "*ha*"}
			echo $location | Out-String
			New-Folder -Server $vihandle -Name $folder.Name -Location $location -Confirm:$false
		}
	}	
}
	   
	Separatorline
}

# Create Roles
function CreateRoles ($Roles, $vihandle) {
	Separatorline

	$Names = $Roles | Select Name -Unique
	foreach ($Name in $Names) {
		$vPrivilege = $Roles | ?{$_.Name -ilike $Name.Name} | Select Privilege
		
		echo $vPrivilege | Out-String
		
		New-VIRole -Server $vihandle -Name $Name.Name -Privilege (Get-VIPrivilege -Server $vihandle | ?{$vPrivilege.Privilege -ilike $_.id})
	}

	Separatorline
}

# Set Permissions
function CreatePermissions ($vPermissions, $vihandle) {
	Separatorline

	echo  "Permissions:" $vPermissions  | Out-String
	
	foreach ($Permission in $vPermissions) {
		$Entity = Get-Inventory -Name $Permission.Entity
		New-VIPermission -Server $vihandle -Entity $Entity -Principal $Permission.Principal -Role $Permission.Role -Propagate $([System.Convert]::ToBoolean($Permission.Propagate))
		
	}
	
	Separatorline
}

# Execute a script via Invoke-VMScript.
function ExecuteScript ($script, $hostname, $username, $password, $vihandle) {

	Separatorline
	
	$script | %{echo $_} | Out-String
	
	Separatorline
	
	$output = Invoke-VMScript -ScriptText $(if ($script.count -gt 1) {$script -join(";")} else {$script}) -vm $hostname -GuestUser $username -GuestPassword $password -Server $vihandle

	return $output
}

# Copy a file to a VM.
function CopyFiletoServer ($locations, $hostname, $username, $password, $vihandle) {
	
	Separatorline
	
	for ($i=0; $i -le ($locations.count/2)-1;$i++) {
		Write-Host "Sources: `n"
		echo $locations[$i*2] | Out-String
		Write-Host "Destinations: `n"
		echo $locations[($i*2)+1] | Out-String
		Copy-VMGuestFile -VM $hostname -LocalToGuest -Source $($locations[$i*2]) -Destination $($locations[($i*2)+1]) -guestuser $username -GuestPassword $password -Server $vihandle -force
	}

	Separatorline
}

function JoinADDomain ($Deployment, $ADInfo, $vihandle) {
			$pscdeployments	= @("tiny","small","large","infrastructure")

			echo "== Joining $($Deployment.vmName) to the windows domain ==" | Out-String

			Separatorline
		
			$commandlist = $null
			$commandlist = @()
			$commandlist += 'export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages'
			$commandlist += 'export VMWARE_LOG_DIR=/var/log'
			$commandlist += 'export VMWARE_DATA_DIR=/storage'
			$commandlist += 'export VMWARE_CFG_DIR=/etc/vmware'
			$commandlist += '/usr/bin/service-control --start --all --ignore'
			$commandlist += "/opt/likewise/bin/domainjoin-cli join $($ADInfo.ADDomain) $($ADInfo.ADJoinUser) $($ADInfo.ADJoinPass)"
	
			# Excute the commands in $commandlist on the vcsa.
			ExecuteScript $commandlist $Deployment.vmName "root" $Deployment.VCSARootPass $vihandle

			# ExecuteScript "reboot" $Deployment.vmName "root" $Deployment.VCSARootPass $esxihandle
			Restart-VMGuest -VM $Deployment.vmName -Server $vihandle -Confirm:$false

			# Write separator line to transcript.
			Separatorline
			
			# Wait 60 seconds before checking availability to make sure the vcsa is booting up and not in the process of shutting down.
			Start-Sleep -s 60
			
			# Wait until the vcsa is available.
			Available "https://$($Deployment.Hostname)"
			
			# Write separator line to transcript.
			Separatorline

			# if the vcsa is the first PSC in the vsphere domain, set the default identity source to the windows domain,
			# add the windows AD group to the admin groups of the PSC.
			if ($Deployment.Action -ieq "first" -and $pscdeployments -contains $Deployment.DeployType) {
				ConfigureIdentity $Deployment.SSODomainName $Deployment.Hostname $Deployment.VCSARootPass $ADInfo.ADDomain $ADInfo.ADvCenterAdmins $vihandle
			}

		Separatorline
}


# Print a dated line to standard output.
function Separatorline {
	$date = Get-Date
	echo "`n---------------------------- $date ----------------------------`r`n" | Out-String
}

#
# Certificate functions
#

function ChainCAs ($Cert_Dir, $rootcer, $intermcer, $interm2cer) {
# Chains CA files together in a PEM encoded file. Supports root CA and two subordinates.
# Skip if we have pending cert requests
	if ($Script:CertsWaitingForApproval) {return}
	# Prompt for Root cert if it's not there yet
	if (Test-Path $intermcer) {
		cmd /c copy $intermcer+$rootcer $Cert_Dir\chain.cer
	}
	if (Test-Path $interm2cer) {
		cmd /c copy $interm2cer+$intermcer+$rootcer $Cert_Dir\chain.cer
	}
}

function CheckOpenSSL ($openssl) {
   if (!(Test-Path $openssl)) {throw "Openssl required, unable to download, please install manually. Use latest OpenSSL 1.0.2."; Exit}
}

function CreatePEMFiles ($SVCDir, $CertFile, $CerFile, $Cert_Dir, $InstanceCertDir) {
	# Create PEM file for supplied certificate
	# Skip if we have pending cert requests
	if ($Script:CertsWaitingForApproval) {return;}
	if (Test-Path $Cert_Dir\chain.cer) {$chaincer = "$Cert_Dir\chain.cer"}
	else {$chaincer = "$Cert_Dir\root64.cer"}
	
	if (!(Test-Path $InstanceCertDir\$SVCDir\$CertFile)) {
		Write-Host "$InstanceCertDir\$SVCDir\$CertFile file not found. Skipping PEM creation. Please correct and re-run." -ForegroundColor Red
	}
	else {$RUI = get-content $InstanceCertDir\$SVCDir\$CertFile
		  $ChainCont = get-content $chaincer -encoding default
		  $RUI + $ChainCont | out-file  $InstanceCertDir\$SVCDir\$CerFile -Encoding default
		  Write-Host "PEM file $InstanceCertDir\$SVCDir\$CerFile succesfully created" -ForegroundColor Yellow
	}
	Set-Location $Cert_Dir	
}

#
# CSR Functions
#

function CreateCSR ($SVCDir, $CSRName, $CFGName, $PrivFile, $Flag, $Cert_Dir, $Certinfo) {
# Create RSA private key and CSR for vSphere 6.0 SSL templates
	if (!(Test-Path $Cert_Dir\$SVCDir)) {New-Item $Cert_Dir\$SVCDir -Type Directory}
	# vSphere 5 and 6 CSR Options are different. Set according to flag type
	# VUM 6.0 needs vSphere 5 template type
	if ($Flag -eq 5) {$CSROption1 = "dataEncipherment"}
	if ($Flag -eq 6) {$CSROption1 = "nonRepudiation"}
	$DEFFQDN = $Certinfo.CompanyName
	$CommonName = $CSRName.Split(".")[0] + " " + $Certinfo.CompanyName
	$MachineShort = $DEFFQDN.split(".")[0] 
	$MachineIP = [System.Net.Dns]::GetHostAddresses("$DEFFQDN").IPAddressToString
	$RequestTemplate = "[ req ]
	default_md = sha512
	default_bits = 2048
	default_keyfile = rui.key
	distinguished_name = req_distinguished_name
	encrypt_key = no
	prompt = no
	string_mask = nombstr
	req_extensions = v3_req
	
	[ v3_req ]
	basicConstraints = CA:FALSE
	keyUsage = digitalSignature, keyEncipherment, $CSROption1
	subjectAltName = IP:$MachineIP,DNS:$DEFFQDN,DNS:$MachineShort
	
	[ req_distinguished_name ]
	countryName = $($Certinfo.Country)
	stateOrProvinceName = $($Certinfo.State)
	localityName = $($Certinfo.Locality)
	0.organizationName = $($Certinfo.OrgName)
	organizationalUnitName = $($Certinfo.OrgUnit)
	commonName = $CommonName
	"
	Set-Location $Cert_Dir
    if (!(Test-Path $SVCDir)) {new-Item Machine -Type Directory}
	# Create CSR and private key
    $Out = $RequestTemplate | Out-File "$Cert_Dir\$SVCDir\$CFGName" -Encoding Default -Force 
    Use-OpenSSL "req -new -nodes -out `"$Cert_Dir\$SVCDir\$CSRName`" -keyout `"$Cert_Dir\$SVCDir\machine-org.key`" -config  `"$Cert_Dir\$SVCDir\$CFGName`""
    Use-OpenSSL "rsa -in `"$Cert_Dir\$SVCDir\machine-org.key`" -out `"$Cert_Dir\$SVCDir\$PrivFile`""
    Remove-Item $SVCDir\machine-org.key
    Write-Host "CSR is located at $Cert_Dir\$SVCDir\$CSRName" -ForegroundColor Yellow
}

function CreateSolutionCSR ($SVCDir, $CSRName, $CFGName, $PrivFile, $Flag, $SolutionUser, $Cert_Dir, $Certinfo) {
# Create RSA private key and CSR for vSphere 6.0 SSL templates
	if (!(Test-Path $Cert_Dir\$SVCDir)) {New-Item $Cert_Dir\$SVCDir -Type Directory}
	# vSphere 5 and 6 CSR Options are different. Set according to flag type
	# VUM 6.0 needs vSphere 5 template type
	$CommonName = $CSRName.Split(".")[0] + " " + $Certinfo.CompanyName
	if ($Flag -eq 5) {$CSROption1 = "dataEncipherment"}
	if ($Flag -eq 6) {$CSROption1 = "nonRepudiation"}
	$DEFFQDN = $Certinfo.CompanyName
	$MachineShort = $DEFFQDN.split(".")[0] 
	$MachineIP = [System.Net.Dns]::GetHostAddresses("$DEFFQDN").IPAddressToString
	$RequestTemplate = "[ req ]
	default_md = sha512
	default_bits = 2048
	default_keyfile = rui.key
	distinguished_name = req_distinguished_name
	encrypt_key = no
	prompt = no
	string_mask = nombstr
	req_extensions = v3_req

	[ v3_req ]
	basicConstraints = CA:FALSE
	keyUsage = digitalSignature, keyEncipherment, $CSROption1
	subjectAltName = IP:$MachineIP,DNS:$DEFFQDN,DNS:$MachineShort

	[ req_distinguished_name ]
	countryName = $($Certinfo.Country)
	stateOrProvinceName = $($Certinfo.State)
	localityName = $($Certinfo.Locality)
	0.organizationName = $($Certinfo.OrgName)
	organizationalUnitName = $($Certinfo.OrgUnit)
	commonName = $CommonName
	"
	Set-Location $Cert_Dir
	if (!(Test-Path $SVCDir)) { new-Item Machine -Type Directory }
	# Create CSR and private key
	$Out = $RequestTemplate | Out-File "$Cert_Dir\$SVCDir\$CFGName" -Encoding Default -Force 
	Use-OpenSSL "req -new -nodes -out `"$Cert_Dir\$SVCDir\$CSRName`" -keyout `"$Cert_Dir\$SVCDir\machine-org.key`" -config  `"$Cert_Dir\$SVCDir\$CFGName`""
	Use-OpenSSL "rsa -in `"$Cert_Dir\$SVCDir\machine-org.key`" -out `"$Cert_Dir\$SVCDir\$PrivFile`""
	Remove-Item $SVCDir\machine-org.key
    Write-Host "CSR is located at $Cert_Dir\$SVCDir\$CSRName" -ForegroundColor Yellow
}

function CreateVMCACSR {
# Create RSA private key and CSR
	$Computername = get-wmiobject win32_computersystem
	$DEFFQDN = "$($computername.name).$($computername.domain)".ToLower() 
	$VPSCFQDN = $(
		Write-Host "Is the vCenter Platform Services Controller FQDN $DEFFQDN ?"
		$InputFQDN = Read-Host "Press ENTER to accept or input a new PSC FQDN"
		if ($inputFQDN) {$inputFQDN} else {$DEFFQDN}
	)
	$RequestTemplate = "[ req ]
	default_md = sha512
	default_bits = 2048
	default_keyfile = rui.key
	distinguished_name = req_distinguished_name
	encrypt_key = no
	prompt = no
	string_mask = nombstr
	req_extensions = v3_req
	
	[ v3_req ]
	basicConstraints = CA:TRUE
	
	[ req_distinguished_name ]
	countryName = $Country
	stateOrProvinceName = $State
	localityName = $Locality
	0.organizationName = $OrgUnit
	commonName = $VPSCFQDN
	"
	Set-Location $Cert_Dir
    if (!(Test-Path VMCA)) {new-Item VMCA -Type Directory}
	# Create CSR and private key
    $Out = $RequestTemplate | Out-File "$Cert_Dir\VMCA\root_signing_cert.cfg" -Encoding Default -Force
    Use-OpenSSL "req -new -nodes -out `"$Cert_Dir\VMCA\root_signing_cert.csr`" -keyout `"$Cert_Dir\VMCA\vmca-org.key`" -config `"$Cert_Dir\VMCA\root_signing_cert.cfg`""
    Use-OpenSSL "rsa -in `"$Cert_Dir\VMCA\vmca-org.key`" -out `"$Cert_Dir\VMCA\root_signing_cert.key`""
    Remove-Item VMCA\vmca-org.key
    Write-Host "CSR is located at $Cert_Dir\VMCA\root_signing_cert.csr" -ForegroundColor Yellow
}

function DisplayVMDir {
	# Displays the currently used VMDir certificate via OpenSSL
	$Computername = get-wmiobject win32_computersystem
	$DEFFQDN = "$($computername.name).$($computername.domain)".ToLower() 
	$VMDirHost = $(
		Write-Host "Do you want to dispaly the VMDir SSL certificate of $DEFFQDN ?"
		$InputFQDN = Read-Host "Press ENTER to accept or input a new FQDN"
		if ($InputFQDN) {$InputFQDN} else {$DEFFQDN})
	Use-OpenSSL "s_client -servername $VMDirHost -connect `"${VMDirHost}:636`""
}

function DownloadRoots ($Cert_Dir,$RootCA,$rootcer,$SubCA,$intermcer,$SubCA2,$interm2cer,$CADownload) {
# Download Root CA public certificate, if defined
# if the certificate exists (root64.cer) then it won't attempt to download
	if ($RootCA) {
		if (!(Test-Path -Path $rootcer)) {
			Write-Host "Downloading root certificate from $rootca ..."
			$url = "$CADownload"+"://$rootCA/certsrv/certnew.cer?ReqID=CACert&$RootRenewal&Enc=b64"
			$wc.DownloadFile($url,$rootcer)
			if (!(Test-Path -Path $rootcer)) {
				Write-Host "Root64.cer did not download. Check root CA variable, CA web services, or manually download root cert and copy to $Cert_Dir\root64.cer. See vExpert.me/Derek60 Part 8 for more details." -foregroundcolor red;exit}
			Write-Host "Root CA download successful." -foregroundcolor yellow
		}
		else {Write-Host "Root CA file found, will not download." -ForegroundColor yellow} 
	}
	$Validation = select-string -simple CERTIFICATE----- $rootcer
	if (!$Validation) {
		Write-Host "Invalid Root certificate format. Validate BASE64 encoding and try again. Also try decrementing RootRenewal value by 1." -foregroundcolor red; exit}
	# Download Subordinate CA public certificate, if defined
	# if the certificate exists (interm64.cer) then it won't attempt to download
	if ($SubCA) {
		if (!(Test-Path -Path $intermcer)) {
			Write-Host "Downloading subordinate certificate from $subca ..."
			$url = "$CADownload"+"://$SubCA/certsrv/certnew.cer?ReqID=CACert&$SubRenewal&Enc=b64"
			$wc.DownloadFile($url,$intermcer)
			if (!(Test-Path -Path $intermcer)) {
				Write-Host "Interm64.cer did not download. Check subordinate variable, CA web services, or manually download intermediate cert and copy to $Cert_Dir\interm64.cer. See vExpert.me/Derek60 Part 8 for more details." -foregroundcolor red;exit}
			Write-Host "Intermediate CA download successful." -foregroundcolor yellow
		}
		else { Write-Host "Intermediate CA file found, will not download." -ForegroundColor yellow} 
		
		$Validation = select-string -simple CERTIFICATE----- $intermcer
		if (!$Validation) {
			Write-Host "Invalid subordinate certificate format. Validate BASE64 encoding and try again. Also try decrementing SubRenewal value by 1." -foregroundcolor red; exit}
	}
	# Download second-level Subordinate CA public certificate, if defined
	# if the certificate exists (interm264.cer) then it won't attempt to download
	if ($SubCA2) {
		if (!(Test-Path -Path $interm2cer)) {
			Write-Host "Downloading second subordinate certificate from $subca2 ..."
			$url = "$CADownload"+"://$SubCA2/certsrv/certnew.cer?ReqID=CACert&$Sub2Renewal&Enc=b64"
			$wc.DownloadFile($url,$interm2cer)
			if (!(Test-Path -Path $interm2cer)) {
				Write-Host "Interm264.cer did not download. Check subordinate 2 CA variable, CA web services, or manually download intermediate cert and copy to $Cert_Dir\interm264.cer. See vExpert.me/Derek60 Part 8 for more details." -foregroundcolor red;exit}
			Write-Host "Second Intermediate CA download successful." -foregroundcolor yellow
		}
		else { Write-Host "Second Intermediate CA file found, will not download." -ForegroundColor yellow} 
		
		$Validation = select-string -simple CERTIFICATE----- $intermcer
		if (!$Validation) {
			Write-Host "Invalid second subordinate certificate format. Validate BASE64 encoding and try again. Also try decrementing Sub2Renewal value by 1." -foregroundcolor red; exit}
	}
}

function MoveUserCerts {
	Get-ChildItem -Path $Cert_Dir -filter "*.crt" | foreach {
		$Dir = $_.basename
		if (!(Test-Path $Cert_Dir\$Dir)) {New-Item $Cert_Dir\$Dir -Type Directory}
		move-Item -Path $_.FullName -Destination $Cert_Dir\$Dir -Force
	}
	Get-ChildItem -Path $Cert_Dir -filter "*.key" | foreach {
		$Dir = $_.basename
		move-Item -Path $_.FullName -Destination $Cert_Dir\$Dir -Force
	}
}

function OnlineMint ($SVCDir, $CSRFile, $CertFile, $Template, $Cert_Dir, $ISSUING_CA) { 
# Mint certificates from online Microsoft CA
    # initialize objects to use for external processes
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $Script:certsWaitingForApproval = $false
        # submit the CSR to the CA
        $psi.FileName = "certreq.exe"
        $psi.Arguments = @("-submit -attrib `"$Template`" -config `"$ISSUING_CA`" -f `"$Cert_Dir\$SVCDir\$CSRFile`" `"$Cert_Dir\$SVCDir\$CertFile`"")
    Write-Host ""
        Write-Host "Submitting certificate request for $SVCDir..." -ForegroundColor Yellow
        [void]$process.Start()
        $cmdOut = $process.StandardOutput.ReadToEnd()
        if ($cmdOut.Trim() -like "*request is pending*")
        {
            # Output indicates the request requires approval before we can download the signed cert.
            $Script:CertsWaitingForApproval = $true
            # So we need to save the request ID to use later once they're approved.
            $reqID = ([regex]"RequestId: (\d+)").Match($cmdOut).Groups[1].Value
            if ($reqID.Trim() -eq [String]::Empty)
            {
                Write-Error "Unable to parse RequestId from output."
                Write-Debug $cmdOut
                Exit
            }
            Write-Host "RequestId: $reqID is pending" -ForegroundColor Yellow
            # Save the request ID to a file that OnlineMintResume can read back in later
            $reqID | out-file "$Cert_Dir\$SVCDir\requestid.txt"
        }
        else
        {
            # Output doesn't indicate a pending request, so check for a signed cert file
            if (!(Test-Path $Cert_Dir\$SVCDir\$CertFile)) {
                Write-Error "Certificate request failed or was unable to download the signed certificate."
                Write-Error "Verify that the ISSUING_CA variable is set correctly." 
                Write-Debug $cmdOut
                Exit
            }
            else { Write-Host "Certificate successfully downloaded." -ForegroundColor Yellow}
        }
    if ($Script:CertsWaitingForApproval) {
        Write-Host
        Write-Host "One or more certificate requests require manual approval before they can be downloaded." -ForegroundColor Yellow
        Write-Host "Contact your CA administrator to approve the request ID(s) listed above." -ForegroundColor Yellow
        Write-Host "To resume use the appropriate option from the menu." -ForegroundColor Yellow
    }
}

function OnlineMintResume ($SVCDir, $CertFile) {
#Resume the minting process for certificates from online Microsoft CA that required approval
    # initialize objects to use for external processes
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.CreateNoWindow = $true
    $psi.UseShellExecute = $false
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi
    $Script:CertsWaitingForApproval = $false
    # skip if there's no requestid.txt file
    if (!(Test-Path "$Cert_Dir\$SVCDir\requestid.txt")) {continue}
    $reqID = Get-Content "$Cert_Dir\$SVCDir\requestid.txt"
    Write-Verbose "Found RequestId: $reqID for $SVCDir"
    # retrieve the signed certificate
    $psi.FileName = "certreq.exe"
    $psi.Arguments = @("-retrieve -f -config `"$ISSUING_CA`" $reqID `"$Cert_Dir\$SVCDir\$CertFile`"")
    Write-Host "Downloading the signed $SVCDir certificate..." -ForegroundColor Yellow
    [void]$process.Start()
    $cmdOut = $process.StandardOutput.ReadToEnd()
    if (!(Test-Path "$Cert_Dir\$SVCDir\$CertFile")) {
        # it's not there, so check if the request is still pending
        if ($cmdOut.Trim() -like "*request is pending*") {
            $Script:CertsWaitingForApproval = $true
            Write-Host "RequestId: $reqID is pending" -ForegroundColor Yellow
        }
        else
        {
			Write-Warning "There was a problem downloading the signed certificate" -foregroundcolor red
			Write-Warning $cmdOut
			continue
        }
    }
    if ($Script:CertsWaitingForApproval) {
        Write-Host
        Write-Host "One or more certificate requests require manual approval before they can be downloaded." -ForegroundColor Yellow
        Write-Host "Contact your CA administrator to approve the request IDs listed above." -ForegroundColor Yellow
    }
    $Script:CertsWaitingForApproval = $false
}

function Use-Openssl ($OpenSSLArgs) {
	$OpensslInfo = $null
	$o			 = $null
	$OpensslInfo = New-Object System.Diagnostics.ProcessStartInfo
	$OpensslInfo.FileName = $openssl
	$OpensslInfo.RedirectStandardError = $true
	$OpensslInfo.RedirectStandardOutput = $true
	$OpensslInfo.UseShellExecute = $false
	$OpensslInfo.Arguments = $OpenSSLArgs
	$o = New-Object System.Diagnostics.Process
	$o.StartInfo = $OpensslInfo
	$o.Start() | Out-Null
	$o.WaitForExit()
	$stdout = $o.StandardOutput.ReadToEnd()
	$stderr = $o.StandardError.ReadToEnd()
	Write-Host "stdout: $stdout"
	Write-Host "stderr: $stderr"
	Write-Host "exit code: " + $o.ExitCode
}

function Set-VMHostProfileExtended {
<#
.SYNOPSIS  Update the root password in a Host Profile
.DESCRIPTION The function will update the root password in
  a Host Profile.
.NOTES  Author:  Luc Dekens
.PARAMETER Profile
  The Host Profile for which you want to change the root
  password. You can pass the name of the Host Profile
  or the VMHostProfile object
.PARAMETER AdminPassword
  The new root password.
.EXAMPLE
  PS> $prof = Get-VMHostProfile -Name MyProfile
  PS> Set-VMHostProfileExtended -Profile $prof -AdminPassword "abc"
#>
 
  param(
  [CmdletBinding()]
  [parameter(Mandatory = $true, ValueFromPipeline = $true)]
  [PSObject]$Profile,
  [string]$AdminPassword,
  $vihandle
  )
 
  begin{
    function Copy-Property ($From, $To, $PropertyName ="*")
    {
      foreach ($p in Get-Member -In $From -MemberType Property -Name $propertyName)
      {        trap {
          Add-Member -In $To -MemberType NoteProperty -Name $p.Name -Value $From.$($p.Name) -Force
          continue
        }
        $To.$($P.Name) = $From.$($P.Name)
      }
    }
  }
 
  process{
    if($Profile.GetType().Name -eq "string"){
      $Profile = Get-VMHostProfile -Name $Profile -Server $vihandle
    }
 
    $spec = New-Object VMware.Vim.HostProfileCompleteConfigSpec
 
    Copy-Property -From $Profile.ExtensionData.Config -To $spec
 
    $secpol = New-Object VMware.Vim.ProfilePolicy
    $secpol.Id = "AdminPasswordPolicy"
    $secpol.PolicyOption = New-Object VMware.Vim.PolicyOption
    $secpol.PolicyOption.Id = "FixedAdminPasswordOption"
    $secpol.PolicyOption.Parameter += New-Object VMware.Vim.KeyAnyValue
    $secpol.PolicyOption.Parameter[0].Key = "password"
    $secpol.PolicyOption.Parameter[0].Value = New-Object VMware.Vim.PasswordField
    $secpol.PolicyOption.Parameter[0].Value.Value = $AdminPassword
    $spec.ApplyProfile.Security.Policy = @($secpol)
 
    $Profile.ExtensionData.UpdateHostProfile($spec)
     
    Get-VMHostProfile -Name $Profile.Name -Server $vihandle
  }
}

function TransferCertToNode ($Cert_Dir,$servertype,$hostname,$username,$password,$vihandle) {
# http://pubs.vmware.com/vsphere-60/index.jsp#com.vmware.vsphere.security.doc/GUID-BD70615E-BCAA-4906-8E13-67D0DBF715E4.html
# Copy SSL certificates to a VCSA and replace the existing ones.

	$date 			= get-date
	
	$certpath 		= "$Cert_Dir\$hostname"
	$SslPath		= "/root/ssl"
	$SolutionPath	= "/root/solutioncerts"
	$script 		= "mkdir $SslPath;mkdir $SolutionPath"
	$pscdeployments	= @("tiny","small","large","infrastructure")
	
	ExecuteScript $script $hostname $username $password $vihandle

	$commandlist = $null
	$commandlist = @()
	$commandlist += "echo `'$password`' | appliancesh 'com.vmware.appliance.version1.system.version.get'"

	echo $commandlist | Out-String

	$viversion = $(ExecuteScript $commandlist $hostname $username $password $vihandle).Scriptoutput.Split("`n")[5]

	echo $viversion

	$filelocations = $null
	$filelocations = @()
	$filelocations += "$certpath\machine\new_machine.cer"
	$filelocations += "$SslPath/new_machine.cer"
	$filelocations += "$certpath\machine\ssl_key.priv"
	$filelocations += "$SslPath/ssl_key.priv"
	if ($servertype -ieq "Infrastructure"){
		$filelocations += "$Cert_Dir\chain.cer"
		$filelocations += "$SslPath/chain.cer"}
	if ($pscdeployments -contains $servertype) {
		$filelocations += "$Cert_Dir\root64.cer"
		$filelocations += "$SslPath/root64.cer"
		$filelocations += "$Cert_Dir\interm64.cer"
		$filelocations += "$SslPath/interm64.cer"
		$filelocations += "$Cert_Dir\interm264.cer"
		$filelocations += "$SslPath/interm264.cer"}
	
	If ($viversion -inotlike "*6.5*") {
		$filelocations += "$certpath\vmdir\vmdircert.pem"
		$filelocations += "/usr/lib/vmware-vmdir/share/config/vmdircert.pem"
		$filelocations += "$certpath\vmdir\vmdirkey.pem"
		$filelocations += "/usr/lib/vmware-vmdir/share/config/vmdirkey.pem"}

	$filelocations += "$certpath\solution\machine.cer"
	$filelocations += "$SolutionPath/machine.cer"
	$filelocations += "$certpath\solution\machine.priv"
	$filelocations += "$SolutionPath/machine.priv"
	$filelocations += "$certpath\solution\vsphere-webclient.cer"
	$filelocations += "$SolutionPath/vsphere-webclient.cer"
	$filelocations += "$certpath\solution\vsphere-webclient.priv"
	$filelocations += "$SolutionPath/vsphere-webclient.priv"
	if ($servertype -ine "Infrastructure"){
		$filelocations += "$certpath\solution\vpxd.cer"
		$filelocations += "$SolutionPath/vpxd.cer"
		$filelocations += "$certpath\solution\vpxd.priv"
		$filelocations += "$SolutionPath/vpxd.priv"
		$filelocations += "$certpath\solution\vpxd-extension.cer"
		$filelocations += "$SolutionPath/vpxd-extension.cer"
		$filelocations += "$certpath\solution\vpxd-extension.priv"
		$filelocations += "$SolutionPath/vpxd-extension.priv"}
	
	CopyFiletoServer $filelocations $hostname $username $password $vihandle
	
	$commandlist = $null
	$commandlist = @()
	$commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
	$commandlist += "export VMWARE_LOG_DIR=/var/log"	
	$commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
	$commandlist += "export VMWARE_DATA_DIR=/storage"
	$commandlist += "service-control --stop --all"
	$commandlist += "service-control --start vmafdd"
	$commandlist += "service-control --start vmdird"
	$commandlist += "service-control --start vmca"

	# Replace the root cert.
	if ($pscdeployments -contains $servertype) {
		$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli trustedcert publish --cert $SslPath/root64.cer"
		$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli trustedcert publish --cert $SslPath/interm64.cer"
		$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli trustedcert publish --cert $SslPath/interm264.cer"}

    # Replace the Machine Cert.
	$commandlist += "echo Y | /usr/lib/vmware-vmafd/bin/vecs-cli entry delete --store MACHINE_SSL_CERT --alias __MACHINE_CERT"
	$commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry create --store MACHINE_SSL_CERT --alias __MACHINE_CERT --cert $SslPath/new_machine.cer --key $SslPath/ssl_key.priv"

	
	ExecuteScript $commandlist $hostname $username $password $vihandle

	$commandlist = $null
	$commandlist = @()
	$commandlist += "echo Y | /usr/lib/vmware-vmafd/bin/vecs-cli entry delete --store machine --alias machine" 
	$commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry create --store machine --alias machine --cert $SolutionPath/machine.cer --key $SolutionPath/machine.priv"
	$commandlist += "echo Y | /usr/lib/vmware-vmafd/bin/vecs-cli entry delete --store vsphere-webclient --alias vsphere-webclient"
	$commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry create --store vsphere-webclient --alias vsphere-webclient --cert $SolutionPath/vsphere-webclient.cer --key $SolutionPath/vsphere-webclient.priv"
	# Skip if server is an External PSC.
	if ($servertype -ine "Infrastructure"){
		$commandlist += "echo Y | /usr/lib/vmware-vmafd/bin/vecs-cli entry delete --store vpxd --alias vpxd"
		$commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry create --store vpxd --alias vpxd --cert $SolutionPath/vpxd.cer --key $SolutionPath/vpxd.priv"
		$commandlist += "echo Y | /usr/lib/vmware-vmafd/bin/vecs-cli entry delete --store vpxd-extension --alias vpxd-extension"	
		$commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry create --store vpxd-extension --alias vpxd-extension --cert $SolutionPath/vpxd-extension.cer --key $SolutionPath/vpxd-extension.priv"

	}

	ExecuteScript $commandlist $hostname $username $password $vihandle
	
	$commandlist = $null
	$commandlist = @()
	$commandlist += "/usr/lib/vmware-vmafd/bin/vmafd-cli get-machine-id --server-name localhost"
	$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli service list"
	
	$UniqueID = Invoke-VMScript -ScriptText $commandlist[0] -vm $hostname -GuestUser $username -GuestPassword $password -Server $vihandle
	$CertList = Invoke-VMScript -ScriptText $commandlist[1] -vm $hostname -GuestUser $username -GuestPassword $password -Server $vihandle
	
	# Retrieve unique key list relevant to the server.
	$SolutionUsers = ($Certlist.ScriptOutput.split(".").Split("`n")|%{if($_[0] -eq " "){$_}} | ?{$_.ToString() -ilike "*$($UniqueID.ScriptOutput.split("`n")[0])*"}).Trim(" ")

	$commandlist = $null
	$commandlist = @()

	$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli service update --name $($SolutionUsers[0]) --cert $SolutionPath/machine.cer"
	$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli service update --name $($SolutionUsers[1]) --cert $SolutionPath/vsphere-webclient.cer"
	if ($servertype -ine "Infrastructure") {
		$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli service update --name $($SolutionUsers[2]) --cert $SolutionPath/vpxd.cer"
		$commandlist += "echo `'$password`' | /usr/lib/vmware-vmafd/bin/dir-cli service update --name $($SolutionUsers[3]) --cert $SolutionPath/vpxd-extension.cer"}
		
	$commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
	$commandlist += "export VMWARE_LOG_DIR=/var/log"	
	$commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
	$commandlist += "export VMWARE_DATA_DIR=/storage"
	$commandlist += "service-control --start --all --ignore"
	
	# Service update
	ExecuteScript $commandlist $hostname $username $password $vihandle

    # Refresh Update Manager Certificates.
	if ($servertype -ine "Infrastructure") {
    	$commandlist = $null
		$commandlist = @()
		$commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
		$commandlist += "export VMWARE_LOG_DIR=/var/log"	
		$commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
		$commandlist += "export VMWARE_DATA_DIR=/storage"
		$commandlist += "export VMWARE_RUNTIME_DATA_DIR=/var"
		#$commandlist += "service-control --stop vmware-updatemgr"
    	$commandlist += "/usr/lib/vmware-updatemgr/bin/updatemgr-util refresh-certs"
    	$commandlist += "/usr/lib/vmware-updatemgr/bin/updatemgr-util register-vc"		
		#$commandlist += "service-control --start vmware-updatemgr"

    	# Service update
		ExecuteScript $commandlist $hostname $username $password $vihandle
	}
}

function UserPEMFiles {
	# Creates PEM files for all solution user certificates
	Get-ChildItem -Path $Cert_Dir -filter "*.csr" | foreach {
		$Dir = $_.basename
		CreatePEMFiles $Dir "$Dir.crt" "$Dir.cer"
	}
  
}

function VMDirRename ($Cert_Dir) {
	# Renames SSL certificate files to those used by VCSA
	Rename-Item $Cert_Dir\VMDir\VMDir.cer vmdircert.pem
	Rename-Item $Cert_Dir\VMDir\VMDir.priv vmdirkey.pem
	Write-Host "Certificate files renamed. Upload \VMDir\vmdircert.pem and \VMDir\vmdirkey.pem" -ForegroundColor Yellow
	Write-Host "to VCSA at /usr/lib/vmware-dir/share/config" -ForegroundColor Yellow
}

function VMCAMint ($SVCDir, $CFGFile, $CertFile, $PrivFile) {
	# This function issues a new SSL certificate from the VMCA.
	if(!(Test-Path $Cert_Dir\$SVCDir)) {New-Item $Cert_Dir\$SVCDir -Type Directory}
	$Computername = get-wmiobject win32_computersystem
	$DEFFQDN = "$($computername.name).$($computername.domain)".ToLower() 
	$MachineFQDN = $(
		Write-Host "Do you want to replace the SSL certificate on $DEFFQDN ?"
		$InputFQDN = Read-Host "Press ENTER to accept or input a new FQDN"
		if ($InputFQDN) {$InputFQDN} else {$DEFFQDN}
	)
	$PSCFQDN = $(
		Write-Host "Is the PSC $DEFFQDN ?"
		$InputFQDN = Read-Host "Press ENTER to accept or input the correct PSC FQDN"
		if ($InputFQDN) {$InputFQDN} else {$DEFFQDN}
	)
	$MachineIP = [System.Net.Dns]::GetHostAddresses("$MachineFQDN").IPAddressToString -like '*.*'
	Write-Host $MachineIP
	$VMWTemplate = "
	#
	# Template file for a CSR request
	#
	# Country is needed and has to be 2 characters
	Country = $Country
	Name = $CompanyName
	Organization = $OrgName
	OrgUnit = $OrgUnit
	State = $State
	Locality = $Locality
	IPAddress = $MachineIP
	Email = $email
	Hostname = $MachineFQDN
	"
	$Out = $VMWTemplate | Out-File "$Cert_Dir\$SVCDir\$CFGFile" -Encoding Default -Force
	# Mint certificate from VMCA and save to disk
	cd "C:\Program Files\VMware\vCenter Server\vmcad"
	.\certool --genkey --privkey=$Cert_Dir\$SVCDir\$PrivFile --pubkey=$Cert_Dir\$SVCDir\$SVCDir.pub
	.\certool --gencert --cert=$Cert_Dir\$SVCDir\$CertFile --privkey=$Cert_Dir\$SVCDir\$PrivFile --config=$Cert_Dir\$SVCDir\$CFGFile --server=$PSCFQDN
	if (Test-Path $Cert_Dir\$SVCDir\$CertFile) {Write-Host "PEM file located at $Cert_Dir\$SVCDir\new_machine.cer" -ForegroundColor Yellow n}
}

function CDDir ($PSScriptRoot) {
	# CDs into the directory the Toolkit script was run
	cd $PSScriptRoot
}

function CreateVCSolutionCert ($Cert_Dir, $InstanceCertDir, $Certinfo) {
	CreateSolutionCSR Solution vpxd.csr vpxd.cfg vpxd.priv 6 vpxd $InstanceCertDir $Certinfo
	CreateSolutionCSR Solution vpxd-extension.csr vpxd-extension.cfg vpxd-extension.priv 6 vpxd-extension $InstanceCertDir $Certinfo
	CreateSolutionCSR Solution machine.csr machine.cfg machine.priv 6 machine $InstanceCertDir $Certinfo
	CreateSolutionCSR Solution vsphere-webclient.csr vsphere-webclient.cfg vsphere-webclient.priv 6 vsphere-webclient $InstanceCertDir $Certinfo
	
	OnlineMint Solution vpxd.csr vpxd.crt $Certinfo.V6Template $InstanceCertDir $Certinfo.IssuingCA
	OnlineMint Solution vpxd-extension.csr vpxd-extension.crt $Certinfo.V6Template $InstanceCertDir $Certinfo.IssuingCA
	OnlineMint Solution machine.csr machine.crt $Certinfo.V6Template $InstanceCertDir $Certinfo.IssuingCA
	OnlineMint Solution vsphere-webclient.csr vsphere-webclient.crt $Certinfo.V6Template $InstanceCertDir $Certinfo.IssuingCA
	
	CreatePEMFiles Solution vpxd.crt vpxd.cer $Cert_Dir $InstanceCertDir
	CreatePEMFiles Solution vpxd-extension.crt vpxd-extension.cer $Cert_Dir $InstanceCertDir
	CreatePEMFiles Solution machine.crt machine.cer $Cert_Dir $InstanceCertDir
	CreatePEMFiles Solution vsphere-webclient.crt vsphere-webclient.cer $Cert_Dir $InstanceCertDir
}

function CreatePscSolutionCert ($Cert_Dir, $InstanceCertDir, $Certinfo) {
	CreateSolutionCSR Solution machine.csr machine.cfg machine.priv 6 machine $InstanceCertDir $Certinfo
	CreateSolutionCSR Solution vsphere-webclient.csr vsphere-webclient.cfg vsphere-webclient.priv 6 vsphere-webclient $InstanceCertDir $Certinfo

	OnlineMint Solution machine.csr machine.crt $Certinfo.V6Template $InstanceCertDir $Certinfo.IssuingCA
	OnlineMint Solution vsphere-webclient.csr vsphere-webclient.crt $Certinfo.V6Template $InstanceCertDir $Certinfo.IssuingCA
	
	CreatePEMFiles Solution machine.crt machine.cer $Cert_Dir $InstanceCertDir
	CreatePEMFiles Solution vsphere-webclient.crt vsphere-webclient.cer $Cert_Dir $InstanceCertDir
}

# End Functions

# PSScriptRoot does not have a trailing "\"
echo $PSScriptRoot | Out-String

# Start New Transcript
$ErrorActionPreference = "SilentlyContinue"
Stop-Transcript | Out-Null
$ErrorActionPreference = "Continue"
$OutputPath = "$PSScriptRoot\DeployLog_" + $(Get-date -format "dd-MM-yyyy_HH-mm") + ".txt"
Start-Transcript -path $OutputPath -append

Separatorline

# Check to see if Powershell is at least version 3.0
$PSpath = "HKLM:\SOFTWARE\Microsoft\PowerShell\3"
if (!(Test-Path $PSpath)) {
	Write-Host "PowerShell 3.0 or higher required. Please install"; exit 
}

# Load Powercli Modules
& $Profile

Separatorline

# Check the version of Ovftool and get it's path. Search C:\program files\ and C:\Program Files (x86)\ subfolders for vmware and find the
# Ovftool folders. Then check the version and return the first one that is version 4 or higher.
$ovftoolpath = (gci (gci $env:ProgramFiles, ${env:ProgramFiles(x86)} -filter vmware).fullname -recurse -filter ovftool.exe | %{if(!((& $($_.DirectoryName+"\ovftool.exe") --version).split(" ")[2] -lt 4.0.0)){$_}} | Select -first 1).DirectoryName

# Check ovftool version
if (!$ovftoolpath) 
	{Write-Host "Script requires installation of ovftool 4.0.0 or newer";
	 Exit} 
else
	{Write-Host "ovftool version OK `r`n"}
	
# Get list of installed Applications
$InstalledApps = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*, HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |?{$_.DisplayName} | Sort
	
# Download OpenSSL if it's not already installed
if (!($InstalledApps | ?{$_.DisplayName -ilike "*openssl*"})) {
Write-Host -Foreground "DarkBlue" -Background "White" "Downloading OpenSSL $OpenSSLVersion ..."
$null = New-Item -Type Directory $openssldir -erroraction silentlycontinue
$sslurl = "http://slproweb.com/download/$OpenSSLVersion"
$sslexe = "$env:temp\openssl.exe"
$wc.DownloadFile($sslurl,$sslexe)
$env:path = $env:path + ";$openssldir"
    if (!(test-Path($sslexe))) { Write-Host -Foreground "red" -Background "white" "Could not download or find OpenSSL. Please install the latest OpenSSL 0.9.8 manually or update download name."; exit}
Write-Host -Foreground "DarkBlue" -Background "White" "Installing OpenSSL..."
    cmd /c $sslexe /silent /verysilent /sp- /suppressmsgboxes
Remove-Item $sslexe
}

$openssl = ($InstalledApps | ?{$_.DisplayName -ilike "*openssl*"}).InstallLocation + "bin\openssl.exe"

# Check for openssl
CheckOpenSSL $openssl

Separatorline

# ---------------------  Load Parameters from Excel ------------------------------

# Global variables
$ExcelFilePath = "$PSScriptRoot\vsphere-configs.xlsx"

# Create an Object Excel.Application using Com interface
$objExcel = New-Object -ComObject Excel.Application

# Disable the 'visible' property so the document won't open in excel
$objExcel.Visible = $false

# Open the Excel file and save it in $WorkBook
$workBook = $objExcel.Workbooks.Open($ExcelFilePath)

# get ad info
$workSheet	= $WorkBook.sheets.item("adinfo")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data		= $Worksheet.Range("B2","B$rows").Value().split("`n")

$s_adinfo = New-Object System.Object
$s_adinfo | Add-Member -type NoteProperty -name ADDomain -value $data[0]
$s_adinfo | Add-Member -type NoteProperty -name ADJoinUser -value $data[1]
$s_adinfo | Add-Member -type NoteProperty -name ADJoinPass -value $data[2]		
$s_adinfo | Add-Member -type NoteProperty -name ADvCenterAdmins -value $data[3]

echo $s_adinfo | Out-String

Separatorline

# get autodeploy rules
$workSheet	= $WorkBook.sheets.item("autodeploy")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data 		= $Worksheet.Range("A2","J$rows").Value()
$s_arules = @()

for ($i=1;$i -lt $rows;$i++){
		$s_arule = New-Object System.Object
		$s_arule | Add-Member -type NoteProperty -name vCenter -value $data[$i,1]
		$s_arule | Add-Member -type NoteProperty -name RuleName -value $data[$i,2]			
		$s_arule | Add-Member -type NoteProperty -name ProfileImport -value $data[$i,3]		
		$s_arule | Add-Member -type NoteProperty -name ProfileName -value $data[$i,4]
		$s_arule | Add-Member -type NoteProperty -name ProfileRootPassword -value $data[$i,5]		
		$s_arule | Add-Member -type NoteProperty -name ProfileAnnotation -value $data[$i,6]		
		$s_arule | Add-Member -type NoteProperty -name Cluster -value $data[$i,7]
		$s_arule | Add-Member -type NoteProperty -name SoftwareDepot -value $data[$i,8]
		$s_arule | Add-Member -type NoteProperty -name Pattern -value $data[$i,9]
		$s_arule | Add-Member -type NoteProperty -name Activate -value $data[$i,10]
		$s_arules += $s_arule
}

echo $s_arules | Out-String

Separatorline

# get certificate info
$workSheet	= $WorkBook.sheets.item("certs")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data		= $Worksheet.Range("B2","B$rows").Value().split("`n")

$s_Certinfo = New-Object System.Object
$s_Certinfo | Add-Member -type NoteProperty -name sslVersion -value $data[0]
$s_Certinfo | Add-Member -type NoteProperty -name RootCA -value $data[1]
$s_Certinfo | Add-Member -type NoteProperty -name SubCA1 -value $data[2]		
$s_Certinfo | Add-Member -type NoteProperty -name SubCA2 -value $data[3]
$s_Certinfo | Add-Member -type NoteProperty -name CompanyName -value $data[4]
$s_Certinfo | Add-Member -type NoteProperty -name OrgName -value $data[5]
$s_Certinfo | Add-Member -type NoteProperty -name OrgUnit -value $data[6]
$s_Certinfo | Add-Member -type NoteProperty -name State -value $data[7]
$s_Certinfo | Add-Member -type NoteProperty -name Locality -value $data[8]
$s_Certinfo | Add-Member -type NoteProperty -name Country -value $data[9]
$s_Certinfo | Add-Member -type NoteProperty -name Email -value $data[10]
$s_Certinfo | Add-Member -type NoteProperty -name CADownload -value $data[11]
$s_Certinfo | Add-Member -type NoteProperty -name IssuingCA -value $data[12]
$s_Certinfo | Add-Member -type NoteProperty -name VUMTemplate -value $data[13]
$s_Certinfo | Add-Member -type NoteProperty -name V6Template -value $data[14]
$s_Certinfo | Add-Member -type NoteProperty -name SubTemplate -value $data[15]
$s_Certinfo | Add-Member -type NoteProperty -name RootRenewal -value $data[16]
$s_Certinfo | Add-Member -type NoteProperty -name SubRenewal1 -value $data[17]
$s_Certinfo | Add-Member -type NoteProperty -name SubRenewal2 -value $data[18]

echo $s_certinfo | Out-String

Separatorline

# get clusters
$workSheet	= $WorkBook.sheets.item("clusters")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data 		= $Worksheet.Range("A2","C$rows").Value()
$s_clusters = @()

for ($i=1;$i -lt $rows;$i++){
		$s_cluster = New-Object System.Object
		$s_cluster | Add-Member -type NoteProperty -name ClusterName -value $data[$i,1]
		$s_cluster | Add-Member -type NoteProperty -name Datacenter -value $data[$i,2]
		$s_cluster | Add-Member -type NoteProperty -name vCenter -value $data[$i,3]
		$s_clusters += $s_cluster
}

echo $s_clusters | Out-String

Separatorline

# get folders
$workSheet	= $WorkBook.sheets.item("folders")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data		= $Worksheet.Range("A2","E$rows").Value()
$s_folders	= @()

for ($i=1;$i -lt $rows;$i++){
		$s_folder = New-Object System.Object
		$s_folder | Add-Member -type NoteProperty -name Name -value $data[$i,1]
		$s_folder | Add-Member -type NoteProperty -name Location -value $data[$i,2]
		$s_folder | Add-Member -type NoteProperty -name Type -value $data[$i,3]
		$s_folder | Add-Member -type NoteProperty -name Datacenter -value $data[$i,4]
		$s_folder | Add-Member -type NoteProperty -name vCenter -value $data[$i,5]
		$s_folders += $s_folder
}

echo $s_folders | Out-String

Separatorline

# get Permissions
$workSheet		= $WorkBook.sheets.item("permissions")
$rows			= $WorkSheet.UsedRange.Rows.Count
$data			= $Worksheet.Range("A2","E$rows").Value()
$s_Permissions	= @()

for ($i=1;$i -lt $rows;$i++){
		$s_Permission = New-Object System.Object
		$s_Permission | Add-Member -type NoteProperty -name Entity -value $data[$i,1]
		$s_Permission | Add-Member -type NoteProperty -name Principal -value $data[$i,2]	
		$s_Permission | Add-Member -type NoteProperty -name Propagate -value $data[$i,3]	
		$s_Permission | Add-Member -type NoteProperty -name Role -value $data[$i,4]
		$s_Permission | Add-Member -type NoteProperty -name vCenter -value $data[$i,5]
		$s_Permissions += $s_Permission
}

echo $s_Permissions | Out-String

Separatorline

# get OS Customizations
$workSheet			= $WorkBook.sheets.item("OS")
$rows				= $WorkSheet.UsedRange.Rows.Count
$data				= $Worksheet.Range("A2","AA$rows").Value()
$s_Customizations	= @()

for ($i=1;$i -lt $rows;$i++){
		$s_Customization = New-Object System.Object
		$s_Customization = ""
		if ($data[$i,1]) {$s_Customization = $s_Customization.insert($s_Customization.length," -OSType `"$($data[$i,1])`"")}
		if ($data[$i,2]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Server `"$($data[$i,2])`"")}
		if ($data[$i,3]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Name `"$($data[$i,3])`"")}
		if ($data[$i,4]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Type $($data[$i,4])")}
		if ($data[$i,5]) {$s_Customization = $s_Customization.insert($s_Customization.length," -DnsServer `"$($data[$i,5])`"")}
		if ($data[$i,6]) {$s_Customization = $s_Customization.insert($s_Customization.length," -DnsSuffix `"$($data[$i,6])`"")}
		if ($data[$i,7]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Domain `"$($data[$i,7])`"")}
		if ($data[$i,8]) {$s_Customization = $s_Customization.insert($s_Customization.length," -NamingScheme `"$($data[$i,8])`"")}
		if ($data[$i,9]) {$s_Customization = $s_Customization.insert($s_Customization.length," -NamingPrefix `"$($data[$i,9])`"")}
		if ($data[$i,10]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Description `"$($data[$i,10])`"")}
		if ($data[$i,11]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Spec `"$($data[$i,11])`"")}
		if ($data[$i,12]) {$s_Customization = $s_Customization.insert($s_Customization.length," -FullName `"$($data[$i,12])`"")}
		if ($data[$i,13]) {$s_Customization = $s_Customization.insert($s_Customization.length," -OrgName `"$($data[$i,13])`"")}
		if ($data[$i,14] -ilike "true") {$s_Customization = $s_Customization.insert($s_Customization.length," -ChangeSid")}
		if ($data[$i,15] -ilike "true") {$s_Customization = $s_Customization.insert($s_Customization.length," -DeleteAccounts")}
		if ($data[$i,16]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Gui `"$($data[$i,16])`"")}
		if ($data[$i,17]) {$s_Customization = $s_Customization.insert($s_Customization.length," -RunOnce `"$($data[$i,17])`"")}
		if ($data[$i,18]) {$s_Customization = $s_Customization.insert($s_Customization.length," -AdminPassword `"$($data[$i,18])`"")}
		if ($data[$i,19]) {$s_Customization = $s_Customization.insert($s_Customization.length," -TimeZone `"$($data[$i,19])`"")}
		if ($data[$i,20]) {$s_Customization = $s_Customization.insert($s_Customization.length," -AutoLogonCount $($data[$i,20])")}
		if ($data[$i,21]) {$s_Customization = $s_Customization.insert($s_Customization.length," -Workgroup `"$($data[$i,21])`"")}
		if ($data[$i,22]) {$s_Customization = $s_Customization.insert($s_Customization.length," -DomainUsername `"$($data[$i,22])`"")}
		if ($data[$i,23]) {$s_Customization = $s_Customization.insert($s_Customization.length," -DomainPassword `"$($data[$i,23])`"")}
		if ($data[$i,24]) {$s_Customization = $s_Customization.insert($s_Customization.length," -ProductKey `"$($data[$i,24])`"")}
		if ($data[$i,25]) {$s_Customization = $s_Customization.insert($s_Customization.length," -LicenseMode $($data[$i,25])")}
		if ($data[$i,26]) {$s_Customization = $s_Customization.insert($s_Customization.length," -LicenseMaxConnections $($data[$i,26])")}
		$s_Customizations += $s_Customization.insert(0,"New-OSCustomizationSpec")
}

echo $s_Customizations | Out-String

Separatorline

# get Deployments
$s_Deployments	= @()
$dataqueue		= New-Object System.Collections.Queue
$workSheet		= $WorkBook.sheets.item("vcsa")
$rows			= $WorkSheet.UsedRange.Rows.Count
$Worksheet.Range("B1","B$rows").Value() | %{$dataqueue.Enqueue($_)}

for ($i=1;$i -lt $rows;$i += 24){
	$s_Deployment = New-Object System.Object
	$s_Deployment | Add-Member -type NoteProperty -name Action -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name vmName -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name Hostname -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name VCSARootPass -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name NetMode -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name NetFamily -value $dataqueue.Dequeue()	
	$s_Deployment | Add-Member -type NoteProperty -name NetPrefix -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name IP -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name Gateway -value $dataqueue.Dequeue()	
	$s_Deployment | Add-Member -type NoteProperty -name DNS -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name NTP -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name EnableSSH -value $dataqueue.Dequeue()	
	$s_Deployment | Add-Member -type NoteProperty -name DiskMode -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name DeployType -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name esxiHost -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name esxiNet -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name esxiDatastore -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name esxiRootUser -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name esxiRootPass -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name Parent -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name SSODomainName -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name SSOSiteName -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name SSOAdminPass -value $dataqueue.Dequeue()
	$s_Deployment | Add-Member -type NoteProperty -name OVA -value "$PSScriptRoot\$($dataqueue.Dequeue())"
	$s_Deployments += $s_Deployment
}

echo $s_Deployments | Out-String

Separatorline

# get Licenses
$workSheet	= $WorkBook.sheets.item("licenses")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data		= $Worksheet.Range("A2","D$rows").Value()
$s_Licenses	= @()

for ($i=1;$i -lt $rows;$i++){
		$s_License = New-Object System.Object
		$s_License | Add-Member -type NoteProperty -name vCenter -value $data[$i,1]
		$s_License | Add-Member -type NoteProperty -name LicKey -value $data[$i,2]
		$s_License | Add-Member -type NoteProperty -name ApplyTo -value $data[$i,3]
		$s_License | Add-Member -type NoteProperty -name ApplyType -value $data[$i,4]
		$s_Licenses += $s_License
}

echo $s_Licenses | Out-String

Separatorline

# get Roles
$workSheet	= $WorkBook.sheets.item("roles")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data		= $Worksheet.Range("A2","C$rows").Value()
$s_Roles	= @()

for ($i=1;$i -lt $rows;$i++){
		$s_Role = New-Object System.Object
		$s_Role | Add-Member -type NoteProperty -name Name -value $data[$i,1]
		$s_Role | Add-Member -type NoteProperty -name Privilege -value $data[$i,2]
		$s_Role | Add-Member -type NoteProperty -name vCenter -value $data[$i,3]
		$s_Roles += $s_Role
}

echo $s_Roles | Out-String

Separatorline

# get Services
$workSheet	= $WorkBook.sheets.item("services")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data		= $Worksheet.Range("A2","B$rows").Value()
$s_Services	= @()

for ($i=1;$i -lt $rows;$i++){
		$s_Service = New-Object System.Object
		$s_Service | Add-Member -type NoteProperty -name Node -value $data[$i,1]
		$s_Service | Add-Member -type NoteProperty -name Service -value $data[$i,2]
		$s_Services += $s_Service
}

echo $s_Services | Out-String

Separatorline

# get sites
$workSheet	= $WorkBook.sheets.item("sites")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data 		= $Worksheet.Range("A2","E$rows").Value()
$s_sites	= @()
	
for ($i=1;$i -lt $rows;$i++){
	$s_site = New-Object System.Object
	$s_site | Add-Member -type NoteProperty -name Datacenter -value $data[$i,1]
	$s_site | Add-Member -type NoteProperty -name oct1 -value $data[$i,2]
	$s_site | Add-Member -type NoteProperty -name oct2 -value $data[$i,3]
	$s_site | Add-Member -type NoteProperty -name oct3 -value $data[$i,4]
	$s_site | Add-Member -type NoteProperty -name vCenter -value $data[$i,5]
	$s_sites += $s_site
	}
	
echo $s_sites | Out-String

Separatorline

# get vdswitches
$workSheet		= $WorkBook.sheets.item("vdswitches")
$rows			= $WorkSheet.UsedRange.Rows.Count
$data 			= $Worksheet.Range("A2","D$rows").Value()
$s_vdswitches	= @()

for ($i=1;$i -lt $rows;$i++){
	$s_vdswitch = New-Object System.Object
	$s_vdswitch | Add-Member -type NoteProperty -name vDSwitchName -value $($data[$i,1].ToString() + " " + $data[$i,2].ToString())
	$s_vdswitch | Add-Member -type NoteProperty -name Location -value $data[$i,3]
	$s_vdswitch | Add-Member -type NoteProperty -name vCenter -value $data[$i,4]
	$s_vdswitches += $s_vdswitch
	}

echo $s_vdswitches | Out-String
	
Separatorline

# get vlans
$workSheet	= $WorkBook.sheets.item("vlans")
$rows		= $WorkSheet.UsedRange.Rows.Count
$data		= $Worksheet.Range("A2","E$rows").Value()
$s_vlans 	= @()

for ($i=1;$i -lt $rows;$i++){
		$s_vlan = New-Object System.Object
		$s_vlan | Add-Member -type NoteProperty -name vlan -value $($data[$i,1].padright(8," ") +`
																	$data[$i,2].padright(8," ") + "- " +`
																	$data[$i,3].padright(19," ") + "- " +`
																	$data[$i,4])
		$s_vlan | Add-Member -type NoteProperty -name vCenter -value $data[$i,5]
		$s_vlans += $s_vlan
}

echo $s_vlans | Out-String

Separatorline

$workbook.Close($false)

# ---------------------  END Load Parameters from Excel ------------------------------

# https://blogs.technet.microsoft.com/bshukla/2010/04/12/ignoring-ssl-trust-in-powershell-system-net-webclient/
$netAssembly = [Reflection.Assembly]::GetAssembly([System.Net.Configuration.SettingsSection])

if($netAssembly)
{
    $bindingFlags = [Reflection.BindingFlags] "Static,GetProperty,NonPublic"
    $settingsType = $netAssembly.GetType("System.Net.Configuration.SettingsSectionInternal")

    $instance = $settingsType.InvokeMember("Section", $bindingFlags, $null, $null, @())

    if($instance)
    {
        $bindingFlags = "NonPublic","Instance"
        $useUnsafeHeaderParsingField = $settingsType.GetField("useUnsafeHeaderParsing", $bindingFlags)

        if($useUnsafeHeaderParsingField)
        {
          $useUnsafeHeaderParsingField.SetValue($instance, $true)
        }
    }
}

# Global variables
[regex]$regex				= '\d{2,4}'
$pscdeployments				= @("tiny","small","large","infrastructure")
$mtu						= "9000"

# Certificate variables	
# Create the RANDFILE environmental parameter for openssl to fuction properly.
$env:RANDFILE 					= "$PSScriptRoot\Certs\.rnd"
$rootcer						= "$PSScriptRoot\Certs\root64.cer"
$intermcer 						= "$PSScriptRoot\Certs\interm64.cer" 
$interm2cer 					= "$PSScriptRoot\Certs\interm264.cer" 
$wc 							= New-Object System.Net.WebClient
$wc.UseDefaultCredentials 		= $true
$Script:CertsWaitingForApproval = $false
New-Alias -Name OpenSSL $openssl

# Create certificate directory if it does not exist
$Cert_Dir = $PSScriptRoot + "\Certs"
if (!(Test-Path $Cert_Dir)) { New-Item $Cert_Dir -Type Directory | Out-Null }

# Deploy the VCSA servers.

foreach ($Deployment in $s_Deployments | ?{$_.Action -ine "null"}) {
	# Skip deployment if set to null.

		Write-Host "`r`n Deploying $($Deployment.Hostname) now.`r`n" -foregroundcolor cyan
	
		# Deploy the vcsa
		Deploy $Deployment $ovftoolpath

		# Write separator line to transcript.
		Separatorline
	
		# Create esxi credentials.
		$esxi_secpasswd		= $null
		$esxi_creds			= $null
		$esxi_secpasswd		= ConvertTo-SecureString $Deployment.esxiRootPass -AsPlainText -Force
		$esxi_creds			= New-Object System.Management.Automation.PSCredential ($Deployment.esxiRootUser, $esxi_secpasswd)
	
		# Connect to esxi host of the deployed vcsa.
		$esxihandle = connect-viserver -server $Deployment.esxiHost -credential $esxi_creds
		
		Separatorline

		$commandlist = $null
		$commandlist = @()
		$commandlist += 'test -e "/var/log/firstboot/succeeded"'
		$commandlist += 'echo $?'
		
		while ((ExecuteScript $commandlist $Deployment.vmName "root" $($Deployment.VCSARootPass) $esxihandle).ScriptOutput[0] -eq "1") {
			echo "== waiting 30 seconds while firstboot for $($Deployment.vmName) finishes ==" | Out-String
			Start-Sleep -s 30
		}
	
		echo "`r`n The VCSA $($Deployment.Hostname) has been deployed and is available.`r`n" | Out-String

		# Disconnect from the vcsa deployed esxi server.
		Disconnect-viserver -Server $esxihandle -Confirm:$false

		# Write separator line to transcript.
		Separatorline	
}

foreach ($Deployment in $s_Deployments | ?{$_.Action -ine "null"}) {
	
		echo "== Starting configuration of $($Deployment.vmName) ==" | Out-String

		Separatorline
	
		# Create esxi credentials.
        $esxi_secpasswd		= $null
		$esxi_creds			= $null
		$esxi_secpasswd		= ConvertTo-SecureString $Deployment.esxiRootPass -AsPlainText -Force
		$esxi_creds			= New-Object System.Management.Automation.PSCredential ($Deployment.esxiRootUser, $esxi_secpasswd)
	
		# Connect to esxi host of the deployed vcsa.
		$esxihandle = connect-viserver -server $Deployment.esxiHost -credential $esxi_creds

		Separatorline
		
		# if the vcsa is a PSC, join it to the windows domain.
		if ($pscdeployments -contains $Deployment.DeployType) {
			JoinADDomain $Deployment $s_adinfo $esxihandle
		}
		
		# if the vcsa is not a stand alone PSC, configure the vCenter.
		if ($Deployment.DeployType -ine "infrastructure" ) {

			echo "== vCenter $($Deployment.vmName) configuration ==" | Out-String

			Separatorline

			$Datacenters	= $s_sites | ?{$_.vCenter -ieq "all" -or $_.vCenter -ilike $Deployment.Hostname}
			$sso_secpasswd	= ConvertTo-SecureString $($Deployment.SSOAdminPass) -AsPlainText -Force
			$sso_creds		= New-Object System.Management.Automation.PSCredential ("Administrator@$($Deployment.SSODomainName)", $sso_secpasswd)

			# Connect to the vCenter
			$vchandle = Connect-viserver $Deployment.Hostname -Credential $sso_creds
			
			# Create Datacenter
			$Datacenters.Datacenter.ToUpper() | %{New-Datacenter -Location Datacenters -Name $_}
				
			# Create Folders, Roles, and Permissions.
			$folders = $s_folders | ?{$_.vCenter -ieq "all" -or $_.vCenter -ilike $Deployment.Hostname}
			echo "Folders:" $folders
			CreateFolders $folders $vchandle

			# if this is the first vCenter, create custom Roles.
			if ($Deployment.Action -ieq "first" ) {
				$roles = $s_roles | ?{$_.vCenter -ieq "all" -or $_.vCenter -ilike $Deployment.Hostname}
				echo  "Roles:" $roles
				CreateRoles $roles $vchandle	
			}
			
			# Create OS Customizations for the vCenter.
			$s_Customizations | ?{$_ -ilike "*$($Deployment.Hostname)*"} | %{Invoke-Expression $_; echo $_}
			
			# Create Clusters
			foreach ($Datacenter in $Datacenters) {
				# Define IP Octets
				$oct1 = $Datacenter.oct1
				$oct2 = $Datacenter.oct2
				$oct3 = $Datacenter.oct3
			
				# Create the cluster if it is defined for all vCenters or the current vCenter and the current Datacenter.
				($s_clusters | ?{@("all",$Deployment.Hostname) -ieq $_.vCenter`
					-and $Datacenter.Datacenter -ieq $_.Datacenter}).Clustername |`
					%{if ($_) {New-Cluster -Location (Get-Datacenter -Server $vchandle -Name $Datacenter.Datacenter) -Name $_}}
						
				# Create New vDSwitch
				# Select vdswitches if definded for all vCenters or the current vCentere and the current Datacenter.
				$vdswitches = $s_vdswitches | ?{@("all",$Deployment.Hostname) -ieq $_.vCenter -and $_.Location -ieq $Datacenter.Datacenter}
				foreach ($vdswitch in $vdswitches) {
				
					$SwitchLocation = Get-Inventory -Name $vdswitch.location
				
					# Create new vdswitch.
					New-VDSwitch -Server $vchandle -Name $vdswitch.vDSwitchName -Location $SwitchLocation -Mtu $mtu -NumUplinkPorts 2
					
					# Enable NIOC
					(get-vdswitch -Server $vchandle -Name $vdswitch.vDSwitchName | get-view).EnableNetworkResourceManagement($true)
				
					# Create Portgroups
					foreach ($vlan in $($s_vlans.vlan | ?{$_.StartsWith($vdswitch.vDSwitchName.split(" ")[0])})) {
					
						$vlan = $vlan -replace "oct1", $oct1
						$vlan = $vlan -replace "oct2", $oct2
						$vlan = $vlan -replace "oct2", $oct3
						
						New-VDPortgroup -Server $vchandle -VDSwitch $vdswitch.vDSwitchName -Name $vlan -Notes $vlan.split("-")[0] -VlanId $regex.matches($vlan)[0].value
						
						# Set Portgroup Team policies
						if ($vlan -ilike "*vmotion-1*") {
							Get-vdportgroup -Server $vchandle | ?{$_.Name.split('%')[0] -ilike $vlan.split('/')[0]} | Get-VDUplinkTeamingPolicy -Server $vchandle | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy LoadBalanceSrcId -EnableFailback $true -ActiveUplinkPort "dvUplink1" -StandbyUplinkPort "dvUplink2"
						}
						if ($vlan -ilike "*vmotion-2*") {
							Get-vdportgroup -Server $vchandle | ?{$_.Name.split('%')[0] -ilike $vlan.split('/')[0]} | Get-VDUplinkTeamingPolicy -Server $vchandle | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy LoadBalanceSrcId -EnableFailback $true -ActiveUplinkPort "dvUplink2" -StandbyUplinkPort "dvUplink1"
						}
						if ($vlan -inotlike "*vmotion*") {
							Get-vdportgroup -Server $vchandle | ?{$_.Name.split('%')[0] -ilike $vlan.split('/')[0]} | Get-VDUplinkTeamingPolicy -Server $vchandle | Set-VDUplinkTeamingPolicy -LoadBalancingPolicy LoadBalanceLoadBased -EnableFailback $false
						}
						else
						{
						#Set Traffic Shaping on vmotion portgroups for egress traffic
						Get-VDPortgroup -Server $vchandle -VDSwitch $vdswitch.vDSwitchName | ?{$_.Name.split('%')[0] -ilike $vlan.split('/')[0]} | Get-VDTrafficShapingPolicy -Server $vchandle -Direction Out| Set-VDTrafficShapingPolicy -Enabled:$true -AverageBandwidth 8589934592 -PeakBandwidth 8589934592 -BurstSize 1
						}
					}
				}
			}

			# Add Licenses to vCenter.
			if ($s_Licenses | ?{$_.vCenter -eq $Deployment.Hostname}) { ConfigureLicensing $($s_Licenses | ?{$_.vCenter -eq $Deployment.Hostname}) $vchandle}

			# Select permissions for all vCenters or the current vCenter.
			# Create the permissions.
			CreatePermissions $($s_Permissions | ?{$_.vCenter -ieq "all" -or $_.vCenter -ilike $Deployment.Hostname}) $vchandle
			
			# Configure Additional Services (Network Dump, Autodeploy, TFTP)
			foreach ($serv in $s_Services) {
				echo $serv | Out-String
				if ($serv.Node -eq $Deployment.Hostname) {
					switch ($serv.Service) {
						AutoDeploy	{ ConfigureAutoDeploy $Deployment.IP $Deployment.Hostname "root" $Deployment.VCSARootPass $($Deployment.SSODomainName) $esxihandle $vchandle.version
									  If ($s_arules | ?{$_.vCenter -eq $Deployment.Hostname}) { ConfigureAutoDeployRules $($s_arules | ?{$_.vCenter -eq $Deployment.Hostname}) $PSScriptRoot $vchandle}
						}
						Netdumpster	{ ConfigureNetdumpster $Deployment.Hostname "root" $Deployment.VCSARootPass $esxihandle $vchandle.version}
						TFTP		{ ConfigureTFTP $Deployment.Hostname "root" $Deployment.VCSARootPass $esxihandle}
					}
				}
			}

			# Disconnect from the vCenter.
			Disconnect-viserver -server $vchandle -Confirm:$false

			Separatorline
		}

		# Disconnect from the vcsa deployed esxi server.
		Disconnect-viserver -Server $esxihandle -Confirm:$false
}

foreach ($Deployment in $s_Deployments | ?{$_.Action -ine "null"}) {

		# Create esxi credentials.
        $esxi_secpasswd		= $null
		$esxi_creds			= $null
		$esxi_secpasswd		= ConvertTo-SecureString $Deployment.esxiRootPass -AsPlainText -Force
		$esxi_creds			= New-Object System.Management.Automation.PSCredential ($Deployment.esxiRootUser, $esxi_secpasswd)
	
		# Connect to esxi host of the deployed vcsa.
		$esxihandle = connect-viserver -server $Deployment.esxiHost -credential $esxi_creds

		# Change the Placeholder (FQDN) from the certs tab to the FQDN of the vcsa.
		$s_certinfo.CompanyName = $Deployment.Hostname
		
		# $InstanceCertDir is the script location plus cert folder and hostname eg. C:\Script\Certs\vm-host1.companyname.com\
		$InstanceCertDir = $Cert_Dir + "\" + $Deployment.Hostname
		
		# Check for or download root certificates.
		DownloadRoots $Cert_Dir	$s_certinfo.RootCA $rootcer $s_certinfo.SubCA1 $intermcer $s_certinfo.SubCA2 $interm2cer $s_certinfo.CADownload
		
		# Check for or create certificate chain.
		ChainCAs $Cert_Dir $rootcer $intermcer $interm2cer
		
		# Create the Machine cert.
		CreateCSR machine machine_ssl.csr machine_ssl.cfg ssl_key.priv 6 $InstanceCertDir $s_certinfo
		OnlineMint machine machine_ssl.csr new_machine.crt $s_certinfo.V6Template $InstanceCertDir $s_certinfo.IssuingCA
		CreatePEMFiles machine new_machine.crt new_machine.cer $Cert_Dir $InstanceCertDir
		
		# Change back to the script root folder.
		CDDir $PSScriptRoot

		# Create the VMDir cert.
		CreateCSR VMDir VMDir.csr VMDir.cfg VMDir.priv 6 $InstanceCertDir $s_certinfo
		OnlineMint VMDir VMDir.csr VMDir.crt $s_certinfo.V6Template $InstanceCertDir $s_certinfo.IssuingCA
		CreatePEMFiles VMDir VMDir.crt VMdir.cer $Cert_Dir $InstanceCertDir
		
		# Rename the VMDir cert for use on a VMSA.
		VMDirRename $InstanceCertDir
		
		# Change back to the script root folder.		
		CDDir $PSScriptRoot

		# Create the Solution User Certs - 2 for External PSC, 4 for all other deployments.
		if ($Deployment.DeployType -ieq "infrastructure" ) {
			CreatePscSolutionCert $Cert_Dir $InstanceCertDir $s_certinfo
			Separatorline
            # Copy Cert files to vcsa Node and deploy them.
		    TransferCerttoNode $Cert_Dir $Deployment.DeployType $Deployment.Hostname "root" $Deployment.VCSARootPass
		}
		else {CreateVCSolutionCert $Cert_Dir $InstanceCertDir $s_certinfo
			  Separatorline
              # Copy Cert files to vcsa Node and deploy them.
		      TransferCerttoNode $Cert_Dir $Deployment.DeployType $Deployment.Hostname "root" $Deployment.VCSARootPass

              $newservices = $s_arules | ?{$_.vCenter -eq $Deployment.Hostname}
              If ($newservices) {
                  Foreach ($newservice in $newservices) {
                      switch ($newservice) {
                            AutoDeploy  {$commandlist = $null
                                         $commandlist = @()
                                         $commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
                                         $commandlist += "export VMWARE_LOG_DIR=/var/log"
                                         $commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
                                         $commandlist += "export VMWARE_DATA_DIR=/storage"
										 $commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry getcert --store vpxd-extension --alias vpxd-extension --output /root/solutioncerts/vpxd-extension.crt"
										 $commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry getkey --store vpxd-extension --alias vpxd-extension --output /root/solutioncerts/vpxd-extension.key"
                                         $commandlist += "/usr/bin/python /usr/lib/vmware-vpx/scripts/updateExtensionCertInVC.py -e com.vmware.rbd -c /root/solutioncerts/vpxd-extension.crt -k /root/solutioncerts/vpxd-extension.key -s $($Deployment.hostname) -u administrator@$($Deployment.SSODomainName) -p `'$Deployment.VCSARootPass`'"
                                        
                                         ExecuteScript $commandlist $Deployment.Hostname "root" $Deployment.VCSARootPass $esxihandle}
                            Netdumpster {$commandlist = $null
                                         $commandlist = @()
                                         $commandlist += "export VMWARE_PYTHON_PATH=/usr/lib/vmware/site-packages"
                                         $commandlist += "export VMWARE_LOG_DIR=/var/log"
                                         $commandlist += "export VMWARE_CFG_DIR=/etc/vmware"
                                         $commandlist += "export VMWARE_DATA_DIR=/storage"
										 $commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry getcert --store vpxd-extension --alias vpxd-extension --output /root/solutioncerts/vpxd-extension.crt"
										 $commandlist += "/usr/lib/vmware-vmafd/bin/vecs-cli entry getkey --store vpxd-extension --alias vpxd-extension --output /root/solutioncerts/vpxd-extension.key"
                                         $commandlist += "/usr/bin/python /usr/lib/vmware-vpx/scripts/updateExtensionCertInVC.py -e com.vmware.imagebuilder -c /root/solutioncerts/vpxd-extension.crt -k /root/solutioncerts/vpxd-extension.key -s $($Deployment.hostname) -u administrator@$($Deployment.SSODomainName) -p `'$Deployment.VCSARootPass`'"
                                        
                                         ExecuteScript $commandlist $Deployment.Hostname "root" $Deployment.VCSARootPass $esxihandle}
                      }
                  }
              }
        }
		
		# Write separator line to transcript.
		Separatorline
		
		write-host "=============== Restarting $($Deployment.vmName) ===============" | Out-String
		Restart-VMGuest -VM $Deployment.vmName -Server $esxihandle -Confirm:$false

		# Wait until the vcsa is available.
		Available "https://$($Deployment.Hostname)"
	
		# Disconnect from the vcsa deployed esxi server.
		Disconnect-viserver -Server $esxihandle -Confirm:$false
}

Separatorline

echo "<=============== Deployment Complete ===============>" | Out-String

# Stop the transcript.
Stop-Transcript