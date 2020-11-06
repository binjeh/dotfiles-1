# Copyright (C) 2020 Jef Oliver.
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#
# Authors:
# Jef Oliver <jef@eljef.me>

<#
.SYNOPSIS
    Checks if executable is installed.

.DESCRIPTION
    Checks if executable is installed, printing an error and force exiting if it is not.

.PARAMETER execName
    Name of the executable to look for.

.PARAMETER progName
    Name of the program to print in error statement.

.EXAMPLE
    Confirm-Install python.exe python

.OUTPUTS
    Path to installed executable.
#>
function Confirm-Install {
    Param (
        [string]$execName,
        [string]$progName
    )

    try {
        $execPath = $(Get-Command $execName).Source
        return $execPath
    }
    catch {
        Exit-Error "Requirement not found or not installed: $progName"
    }
}

<#
.SYNOPSIS
    Copies a file into place, halting the script if copying fails.

.DESCRIPTION
    Copies a file into place, halting the script if copying fails. This function
    overwrites the destination file if it exists.

.PARAMETER origFile
    Original file to be copied.

.PARAMETER newFile
    Destination origFile will be copied to.

.EXAMPLE
    Copy-File oldfile.txt newfile.txt
#>
function Copy-File {
    Param (
        [string]$origFile,
        [string]$newFile
    )

    try {
        Copy-Item "$origFile" -Destination "$newFile" -Force
    }
    catch {
        Exit-Error "Could not copy $origFile to $newFile" $Error.Exception.Message
    }
}

<#
.SYNOPSIS
    Writes an error and exits.

.DESCRIPTION
    Prints an error statement to the console, plus a second one if provided,
    then exits.

.PARAMETER errorStringOne
    Required error string to print.

.PARAMETER errorStringTwo
    Optional second error string to print.

.EXAMPLE
    Exit-Error "Some Error" "More Descriptive Error Statement"
#>
function Exit-Error {
    Param (
        [string]$errorStringOne,
        [string]$errorStringTwo = ""
    )

    $HOST.UI.WriteErrorLine($errorStringOne)
    if ($errorStringTwo -ne '') {
        $HOST.UI.WriteErrorLine($errorStringTwo)
    }

    Exit 1
}

<#
.SYNOPSIS
    Downloads a file to a destination.

.DESCRIPTION
    Downloads a file from the provied URI and saves it to the provided location.

.PARAMETER downloadURI
    URI to download file from.

.PARAMETER destinationFile
    Destination to save the downloaded file to.

.PARAMETER errorName
    Name of downloaded file to use in the error statement if an error is encountered.

.EXAMPLE
    Get-Download 'https://some.place/a/file.ext' 'c:\somefile.txt' 'some-file'
#>
function Get-Download {
    Param (
        [string]$downloadURI,
        [string]$destinationFile,
        [string]$errorName
    )
    try {
        (New-Object Net.WebClient).DownloadFile($downloadURI, $destinationFile)
    }
    catch {
        Exit-Error "Could not download $errorName" $Error.Exception.Message
    }
}

<#
.SYNOPSIS
    Runs an executable.

.DESCRIPTION
    Runs an executable, blocking until it exits. If a non-zero return code is encountered,
    the script is stopped with a printed error message.

.PARAMETER execName
    Name of executable to run. (Or path to executable.)

.PARAMETER argList
    List of arguments to pass to executable.

.PARAMETER ShowCommand
    Print the command to be run to the screen before running.

.EXAMPLE
    Invoke-Executable "something.exe" @("/arg1", "/arg2")
#>
function Invoke-Executable {
    Param (
        [string]$execName,
        [string[]]$argList,
        [switch]$ShowCommand
    )

    $outFile = Join-Path -Path "$env:TEMP" -ChildPath "$(New-Guid).Guid"
    $errFile = Join-Path -Path "$env:TEMP" -ChildPath "$(New-Guid).Guid"

    if ($ShowCommand) {
        Write-Host "$execName" $($argList -Join " ")
    }

    $procInfo = Start-Process "$execName" -ArgumentList $argList -wait -NoNewWindow -PassThru `
                    -RedirectStandardError "$errFile" -RedirectStandardOutput "$outFile"

    $errInfo = $(Get-Content "$errFile")
    Remove-FileIfExists "$errFile"
    Remove-FileIfExists "$outFile"

    if ($procInfo.ExitCode -ne 0) {
        Exit-Error $("Failed: $execName " + $argList -Join " ") $errInfo
    }
}

<#
.SYNOPSIS
    Runs an executable without redirects.

.DESCRIPTION
    Runs an executable without redirecting Standard Error and Standard Output. If a
    non-zero return code is encountered, the script is stopped, printing the supplied
    error message.
.PARAMETER execName
    Name of executable to run. (Or path to executable.)

.PARAMETER argList
    List of arguments to pass to executable.

.PARAMETER errorMsg
    Message to print when an error has occured.

.EXAMPLE
    Invoke-ExecutableNoRedirect "something.exe" @("/arg1", "/arg2") "An error occured in something.exe"
#>
function Invoke-ExecutableNoRedirect {
    Param (
        [string]$execName,
        [string[]]$argList,
        [string]$errorMsg
    )

    $procInfo = Start-Process "$execName" -ArgumentList $argList -wait -NoNewWindow -PassThru

    if ($procInfo.ExitCode -ne 0) {
        Exit-Error "$errorMsg"
    }
}

<#
.SYNOPSIS
    Creates a new directory.

.DESCRIPTION
    Creates a new directory specified by $newPath, halting the script if directory creation fails.

.PARAMETER newPath
    Full path to directory to create.

.EXAMPLE
    New-Directory "C:\test"
#>
function New-Directory {
    Param (
        [string]$newPath
    )

    try {
        New-Item -Path "$newPath" -ItemType Directory -Force | Out-Null
    }
    catch {
        Exit-Error "Could not create directory: $newPath" $Error.Exception.Message
    }
}

<#
.SYNOPSIS
    Reads JSON from a file.

.DESCRIPTION
    Reads JSON from a file, and returns it as a Hash Table.

.PARAMETER jsonPath
    Path to JSON file to read.

.EXAMPLE
    Read-JSON 'c:\somefile.json'

.OUTPUTS
    A Hash Table containing parsed JSON.
#>
function Read-JSON {
    Param (
        [string]$jsonPath
    )

    try {
        $jsonData = Get-Content -Raw -Path $jsonPath | ConvertFrom-Json -AsHashtable
        return $jsonData
    }
    catch {
        Exit-Error "Could not read $jsonPath" $Error.Exception.Message
    }
}

<#
.SYNOPSIS
    Deletes a file if it exists.

.DESCRIPTION
    Deletes a file if it exists, exiting the script on any errors.

.PARAMETER filePath
    Path to file to delete.

.EXAMPLE
    Remove-FileIfExists C:\test.txt
#>
function Remove-FileIfExists {
    Param (
        [string]$filePath
    )

    try {
        if (Test-Path $filePath) {
            Remove-Item $filePath -Force
        }
    }
    catch {
        Exit-Error "Could not remove file: $filePath" $Error.Exception.Message
    }
}

<#
.SYNOPSIS
    Finds and validates basic structure of dotfiles directories.

.DESCRIPTION
    Finds and validates the basic structure of dotfiles directories and returns
    full paths to base and dotfiles directories.

.PARAMETER execPath
    Script execution path.

.PARAMETER pathDepth
    String representing the number of directories to return in the path until
    the base git repo is hit.

.EXAMPLE
    Search-Dotfiles "..\.."

.OUTPUTS
    Object with .Base holding location to base directory for dotfiles, and
    .Dotfiles holding location to the dotfiles directory itself.
#>
function Search-Dotfiles {
    Param (
        [string]$execPath,
        [string]$pathDepth
    )

    [hashtable]$Return = @{}
    $Return.Base = Resolve-Path -LiteralPath $(Join-Path -Path $(Split-Path $execPath -Parent) -ChildPath $pathDepth)
    $Return.Dotfiles = Join-Path -Path $Return.Base -ChildPath "dotfiles"
    $base = Split-Path $Return.Base -Leaf

    if ($base -ne 'dotfiles') {
        Exit-Error "Could not determine base dotfiles directory."
    }

    if (!(Test-Path $Return.Dotfiles)) {
        Exit-Error "Could not determine base dotfiles directory."
    }

    return $Return
}

<#
.SYNOPSIS
    Writes JSON to a file.

.DESCRIPTION
    Writes the provided Hash Table as JSON to a file.

.PARAMETER jsonData
    JSON Data, as a hash map.

.PARAMETER jsonPath
    Path to file to write JSON to.

.EXAMPLE
    Write-JSON @{'test'='test'} "C:\somefile.json"
#>
function Write-JSON {
    Param (
        [hashtable]$jsonData,
        [string]$jsonPath
    )

    try {
        $jsonData | ConvertTo-Json -depth 100 | Out-File $jsonPath
    }
    catch {
        Exit-Error "Could not save JSON to $jsonPath" $Error.Exception.Message
    }
}

