namespace eval ::twist {

}

namespace eval ::twist::install {

    variable installed 0
    variable version "0.9.35"
    variable sourcePackage "twist"
    variable package twist-oacs
    variable sourceDirectory [ns_server -server [ns_info server] tcllib]
    variable tclLibDirectory [ns_server -server [ns_info server] tcllib]
    variable packageDirectory "$::acs::rootdir/packages"
    variable versionDirectory [file join $packageDirectory $sourcePackage $sourcePackage-$version]
    variable linkWebservices 1
    variable linkDocumentation 1
    variable releaseType "tar.gz"
    variable repositoryUrl "https://github.com/russell-todd-sorensen"
    variable errorFile error-$sourcePackage-$version.txt
    variable downloadFile ""
    variable systemType [expr {[string match *.exe [info nameofexecutable]] ? "windows" : "linux"}]
}

proc ::twist::install::init { } {

    # Ensure variables are up-to-date with database:
    variable package
    variable sourcePackage
    variable packageDirectory

    variable installed [parameter::get_from_package_key -package_key $package -parameter installed -default 0]
    variable upgradeNow [parameter::get_from_package_key -package_key $package -parameter upgradeNow -default 0]
    variable version [parameter::get_from_package_key -package_key $package -parameter version -default 0.9.35]
    variable linkWebservices [parameter::get_from_package_key -package_key $package -parameter linkWebservices -default 1]
    variable linkDocumentation [parameter::get_from_package_key -package_key $package -parameter linkDocumentation -default 1]
    variable versionDirectory [file join $packageDirectory $sourcePackage $sourcePackage-$version]

    return $installed
}

proc ::twist::install::downloadFile { } {

    variable version
    variable package
    variable sourcePackage
    variable versionDirectory
    variable packageDirectory
    variable releaseType
    variable repositoryUrl
    variable errorFile
    variable downloadFile

    # Checkout:
    set downloadDirectory [file join $packageDirectory $sourcePackage]
    file mkdir $versionDirectory
    set downloadFile [file join $downloadDirectory $sourcePackage-${version}.$releaseType]

    exec wget $repositoryUrl/$sourcePackage/archive/${version}.${releaseType} -O $downloadFile 2> [file join $versionDirectory $errorFile]
}

proc ::twist::install::deleteDownloadFile { } {
    variable downloadFile
    file delete $downloadFile
}

proc ::twist::install::unpackFile { } {

    variable releaseType
    variable downloadFile
    variable packageDirectory
    variable versionDirectory
    variable sourcePackage
    variable errorFile
    variable package
    variable owner
    variable group
    variable systemType

    array set tclLibAttributesArray [file attributes [ns_server -server [ns_info server] tcllib]]

    switch -exact -- $systemType {
      windows {
        set trimmedTarDirectory [string range [file join $packageDirectory $sourcePackage] 0 end]
        exec gzip -d $downloadFile
        exec tar xf [string range $downloadFile 0 end-3]\
            --directory $trimmedTarDirectory\
            2>> [file join $versionDirectory $errorFile]
      }
      linux {
        set owner $tclLibAttributesArray(-owner)
        set group $tclLibAttributesArray(-group)
        exec tar xzf $downloadFile\
            --directory [file join $packageDirectory $sourcePackage]\
            --owner $owner\
            --group $group\
            2>> [file join $versionDirectory $errorFile]
      }
    }
}

proc ::twist::install::before-install { } {

    # initialize
    init

    # download new version
    downloadFile
    unpackFile
}

proc ::twist::install::deleteFileLink { linkName } {

    variable systemType

    if {[file exists $linkName]} {
        if {"[file type $linkName]" eq "link"} {
            file delete $linkName
        } elseif {"$systemType" eq "windows" && [file type $linkName] eq "file"} {
            file delete $linkName
        } else {
            return -code error "::twist::install::after-install attempt to delete file of type '[file type $linkName]' named '$linkName'"
        }
    } else {
        # May not be able to see links which are bad:
        file delete $linkName
    }
}

proc ::twist::install::updateFileLink {
    linkName
    newTarget
} {
    ns_log Notice "::twist::install::updateFileLink linkName '$linkName' --> '$newTarget'"
    deleteFileLink $linkName
    file link $linkName $newTarget
    ns_log Notice "::twist::install::updateFileLink success."
}

proc ::twist::install::after-install { } {
    variable packageDirectory
    variable versionDirectory
    variable linkWebservices
    variable linkDocumentation
    variable installed
    variable sourcePackage
    variable package

    ns_log Notice "::twist::install::after-install package='$package'"
    # Record the fact the package is installed.
    set package_id [apm_package_id_from_key $package]

    if {"$package_id" eq "0"} {
      ns_log Error "::twist::install::after-install abort due to database sync error. Rerun command by hand."
      return
    }
    parameter::set_from_package_key -package_key $package -parameter installed -value "1"

    # initialize
    init
    
    # link in web services
    if {$linkWebservices} {
        set linkName [file join $packageDirectory $package www ws]
        set newTarget [file join $versionDirectory packages wsapi www]
        updateFileLink $linkName $newTarget
    }
    # link documentation
    if {$linkDocumentation} {
        set linkName [file join $packageDirectory $package www doc]
        set newTarget [file join $versionDirectory packages doc www]
        updateFileLink $linkName $newTarget
    }
}

proc ::twist::install::upgrade-version {  } {

    ::twist::install::before-install

}
