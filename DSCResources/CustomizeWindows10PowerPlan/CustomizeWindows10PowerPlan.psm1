# Variables to use everywhere
$powerNameSpace = 'root\cimv2\power'
$powerPlan = @{'Namespace'=$powerNameSpace;'ClassName'='win32_powerplan'}
$powerSetting = @{'Namespace'=$powerNameSpace;'ClassName'='Win32_PowerSetting'}
$powerSettingDataIndex = @{'Namespace'=$powerNameSpace;'ClassName'='Win32_PowerSettingDataIndex'}

function Remove-ParentInstanceString
{
	<#
		.SYNOPSIS
		Removes the string from the beginning of the InstanceID returned from a Get-CimInstance command.
	#>
	
	[CmdletBinding()]
	[OutputType([string])]
	Param
	(
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		[string]$InstanceID
	)
	$InstanceID -replace '^Microsoft:[A-Za-z]*\\'
}

function Get-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Collections.Hashtable])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Balanced","High performance","Power saver")]
		[System.String]$ActivePowerPlan
	)

	# Active Power Plan
	$ActivePowerPlanObject = Get-CimInstance @powerPlan -Filter "IsActive = 'True'"
	$ActivePowerPlanId = (Get-CimInstance @powerPlan -Filter "IsActive = 'True'").InstanceID | Remove-ParentInstanceString

	# Sleep After
	$SleepAfterSettingId = (Get-CimInstance @powerSetting -Filter "Elementname = 'Sleep After'").InstanceID | Remove-ParentInstanceString
	$SleepAfterOnACValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%ac%$SleepAfterSettingId'"
	$SleepAfterOnDCValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%dc%$SleepAfterSettingId'"

	# Turn off display after
	$TurnOffDisplayAfterSettingId = (Get-CimInstance @powerSetting -Filter "Elementname = 'Turn Off Display After'").InstanceID | Remove-ParentInstanceString
	$TurnOffDisplayAfterSettingOnACValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%ac%$TurnOffDisplayAfterSettingId'"
	$TurnOffDisplayAfterSettingOnDCValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%dc%$TurnOffDisplayAfterSettingId'"

	# Hibernate after
	$HibernateAfterSettingId = (Get-CimInstance @powerSetting -Filter "Elementname = 'Hibernate After'").InstanceID | Remove-ParentInstanceString
	$HibernateAfterOnACValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%ac%$HibernateAfterSettingId'"
	$HibernateAfterOnDCValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%dc%$HibernateAfterSettingId'"

	$returnValue = @{
		ActivePowerPlan = $ActivePowerPlanObject.ElementName
		SleepAfterOnAC = ($SleepAfterOnACValue.SettingIndexValue/60)
		SleepAfterOnDC = ($SleepAfterOnDCValue.SettingIndexValue/60)
		TurnOffDisplayAfterOnAC = ($TurnOffDisplayAfterSettingOnACValue.SettingIndexValue/60)
		TurnOffDisplayAfterOnDC = ($TurnOffDisplayAfterSettingOnDCValue.SettingIndexValue/60)
		HibernateAfterOnAC = ($HibernateAfterOnACValue.SettingIndexValue/60)
		HibernateAfterOnDC = ($HibernateAfterOnDCValue.SettingIndexValue/60)
	}

	$returnValue
	
}


function Set-TargetResource
{
	[CmdletBinding()]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Balanced","High performance","Power saver")]
		[System.String]
		$ActivePowerPlan,

		[System.String]
		$SleepAfterOnAC,

		[System.String]
		$SleepAfterOnDC,

		[System.String]
		$TurnOffDisplayAfterOnAC,

		[System.String]
		$TurnOffDisplayAfterOnDC,

		[System.String]
		$HibernateAfterOnAC,

		[System.String]
		$HibernateAfterOnDC
	)

	#region PowerPlan
	$ActivePowerPlanObject = Get-CimInstance @powerPlan -Filter "IsActive = 'True'"

	if ($ActivePowerPlanObject.ElementName -ne $ActivePowerPlan)
	{
		$null = Get-CimInstance @powerPlan -Filter "ELementName = '$ActivePowerPlan'" | Invoke-CimMethod -MethodName Activate
	}
	
	$ActivePowerPlanId = (Get-CimInstance @powerPlan -Filter "IsActive = 'True'").InstanceID | Remove-ParentInstanceString
	#endregion 

	#region Sleep After
	$SleepAfterSettingId = (Get-CimInstance @powerSetting -Filter "Elementname = 'Sleep After'").InstanceID | Remove-ParentInstanceString
	$SleepAfterOnACValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%ac%$SleepAfterSettingId'"
	$SleepAfterOnDCValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%dc%$SleepAfterSettingId'"

	if (($SleepAfterOnACValue.SettingIndexValue / 60) -ne $SleepAfterOnAC) 
	{
		$SleepAfterOnACValue  | Set-CimInstance -Property @{SettingIndexValue = ([int]$SleepAfterOnAC * 60)}
	}

	if (($SleepAfterOnDCValue.SettingIndexValue / 60) -ne $SleepAfterOnDC) 
	{
		$SleepAfterOnDCValue  | Set-CimInstance -Property @{SettingIndexValue = ([int]$SleepAfterOnDC * 60)}
	}
	#endregion
	
	#region Turn off display after
	$TurnOffDisplayAfterSettingId = (Get-CimInstance @powerSetting -Filter "Elementname = 'Turn Off Display After'").InstanceID | Remove-ParentInstanceString
	$TurnOffDisplayAfterSettingOnACValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%ac%$TurnOffDisplayAfterSettingId'"
	$TurnOffDisplayAfterSettingOnDCValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%dc%$TurnOffDisplayAfterSettingId'"

	if (($TurnOffDisplayAfterSettingOnACValue.SettingIndexValue / 60) -ne $TurnOffDisplayAfterOnAC) 
	{
		$TurnOffDisplayAfterSettingOnACValue  | Set-CimInstance -Property @{SettingIndexValue = ([int]$TurnOffDisplayAfterOnAC * 60)}	
	}

	if (($TurnOffDisplayAfterSettingOnDCValue.SettingIndexValue / 60) -ne $TurnOffDisplayAfterOnDC) 
	{
		$TurnOffDisplayAfterSettingOnDCValue  | Set-CimInstance -Property @{SettingIndexValue = ([int]$TurnOffDisplayAfterOnDC * 60)}
	}
	#endregion

	#region Hibernate After
	$HibernateAfterSettingId = (Get-CimInstance @powerSetting -Filter "Elementname = 'Hibernate After'").InstanceID | Remove-ParentInstanceString
	$HibernateAfterOnACValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%ac%$HibernateAfterSettingId'"
	$HibernateAfterOnDCValue = Get-CimInstance @powerSettingDataIndex -Filter "InstanceID like '%$ActivePowerPlanId%dc%$HibernateAfterSettingId'"

	if (($HibernateAfterOnACValue.SettingIndexValue / 60) -ne $HibernateAfterOnAC) 
	{
		$HibernateAfterOnACValue  | Set-CimInstance -Property @{SettingIndexValue = ([int]$HibernateAfterOnAC * 60)}	
	}

	if (($HibernateAfterOnDCValue.SettingIndexValue / 60) -ne $TurnOffDisplayAfterOnDC) 
	{
		$HibernateAfterOnDCValue  | Set-CimInstance -Property @{SettingIndexValue = ([int]$HibernateAfterOnDC * 60)}
	}
	#endregion
}


function Test-TargetResource
{
	[CmdletBinding()]
	[OutputType([System.Boolean])]
	param
	(
		[parameter(Mandatory = $true)]
		[ValidateSet("Balanced","High performance","Power saver")]
		[System.String]
		$ActivePowerPlan,

		[System.String]
		$SleepAfterOnAC,

		[System.String]
		$SleepAfterOnDC,

		[System.String]
		$TurnOffDisplayAfterOnAC,

		[System.String]
		$TurnOffDisplayAfterOnDC,

		[System.String]
		$HibernateAfterOnAC,

		[System.String]
		$HibernateAfterOnDC
	)

	$PowerPlanSettings = Get-TargetResource -ActivePowerPlan $ActivePowerPlan

	if ($PowerPlanSettings.ActivePowerPlan -eq $ActivePowerPlan)
	{
		$valid = $true
	}
	else 
	{
		$valid = $false
	}

	if ($SleepAfterOnAC) 
	{
		if ($PowerPlanSettings.SleepAfterOnAC -eq $SleepAfterOnAC)
		{
			$valid = $true -and $valid
		}
		else
		{
			$valid = $false -and $valid
		}
	}

	if ($SleepAfterOnDC) 
	{
		if ($PowerPlanSettings.SleepAfterOnDC -eq $SleepAfterOnDC)
		{
			$valid = $true -and $valid
		}
		else 
		{
			$valid = $false -and $valid
		}
	}

	if ($TurnOffDisplayAfterOnAC) 
	{
		if ($PowerPlanSettings.TurnOffDisplayAfterOnAC -eq $TurnOffDisplayAfterOnAC)
		{
			$valid = $true -and $valid
		}
		else
		{
			$valid = $false -and $valid
		}
	}

	if ($TurnOffDisplayAfterOnDC) 
	{
		if ($PowerPlanSettings.TurnOffDisplayAfterOnDC -eq $TurnOffDisplayAfterOnDC)
		{
			$valid = $true -and $valid
		}
		else
		{
			$valid = $false -and $valid
		}
	}

	if ($HibernateAfterOnAC) 
	{
		if ($PowerPlanSettings.HibernateAfterOnAC -eq $HibernateAfterOnAC)
		{
			$valid = $true -and $valid
		}
		else
		{
			$valid = $false -and $valid
		}
	}

	if ($HibernateAfterOnDC) 
	{
		if ($PowerPlanSettings.HibernateAfterOnDC -eq $HibernateAfterOnDC)
		{
			$valid = $true -and $valid
		}
		else
		{
			$valid = $false -and $valid
		}
	}

	$valid
}


Export-ModuleMember -Function *-TargetResource

