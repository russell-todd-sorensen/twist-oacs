namespace eval ::twist {

}

namespace eval ::twist::install {

    variable installed 0
    variable version "0.9.33"
    variable package "twist"
    variable sourceDirectory [ns_server -server [ns_info server] tcllib]
    variable tclLibDirectory [ns_server -server [ns_info server] tcllib]
    variable packageDirectory "$::acs::rootdir/packages"
    variable versionDirectory [file join $packageDirectory $package-$version]
    variable linkWebservices 0
    variable linkDocumentation 0
    variable releaseType "tar.gz"
    variable repositoryUrl "https://github.com/russell-todd-sorensen"
    variable errorFile error-$package-$version.txt
    variable downloadFile ""
}

proc ::twist::install::init { } {

    # Ensure variables are up-to-date with database:
    variable package

    variable installed [parameter::get_from_package_key -package_key $package -parameter installed -default 0]
    variable upgradeNow [parameter::get_from_package_key -package_key $package -parameter upgradeNow -default 0]
    variable version [parameter::get_from_package_key -package_key $package -parameter version -default 0.9.33]
    variable sourceDirectory [parameter::get_from_package_key -package_key $package -parameter sourceDirectory -default ""]

    if {"$sourceDirectory" eq ""} {
        set sourceDirectory [ns_info tcllib]
        if {$installed} {
            parameter::set_from_package_key -package_key $package -parameter sourceDirectory -value $sourceDirectory
        }
    }

    variable versionDirectory [file join $sourceDirectory $package $package-$version]
    variable linkWebservices [parameter::get_from_package_key -package_key $package -parameter linkWebservices -default 1]
    variable linkDocumentation [parameter::get_from_package_key -package_key $package -parameter linkDocumentation -default 1]

    return $installed
}

proc ::twist::install::downloadFile { } {

    variable version
    variable package
    variable versionDirectory
    variable packageDirectory
    variable releaseType
    variable repositoryUrl
    variable errorFile
    variable downloadFile

    # Checkout:
    set downloadFile $packageDirectory/$package-${version}.$releaseType

    exec wget $repositoryUrl/$package/archive/${version}.${releaseType} -O $downloadFile 2> [file join $packageDirectory $errorFile]

}

proc ::twist::install::deleteDownloadFile { } {
    variable downloadFile
    file delete $downloadFile
}

proc ::twist::install::unpackFile { } {

    variable releaseType
    variable downloadFile
    variable packageDirectory
    variable errorFile
    variable owner
    variable group
    variable system

    array set tclLibAttributesArray [file attributes [ns_info tcllib]]
    if {[info exists tclLibAttributesArray(-owner)]} {
      set owner $tclLibAttributesArray(-owner)
      set system unix
    } else {
      set system windows
    }

    if {[info exists tclLibAttributesArray(-group)]} {
      set group $tclLibAttributesArray(-group)
    } else {
      set system windows
    }

    switch -exact -- $releaseType {
	       "tar.gz" {
           if {"$system" eq "windows"} {
             set trimmedPackageDirectory [string range $packageDirectory 14 end]
             exec gzip -d $downloadFile
             exec tar xf [string range $downloadFile 0 end-3]\
                 --directory $trimmedPackageDirectory\
                 2>> [file join $packageDirectory $errorFile]
           } else {
	           exec tar xzf $downloadFile\
		             --directory $packageDirectory\
		             --owner $owner\
		             --group $group\
		             2>> [file join $packageDirectory $errorFile]
          }
	     }
	     "zip" {

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

    if {[file exists $linkName]} {
        if {"[file type $linkName]" eq "link"} {
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
}

proc ::twist::install::after-install { } {

    variable sourceDirectory
    variable tclLibDirectory
    variable packageDirectory
    variable versionDirectory
    variable linkWebservices
    variable linkDocumentation

    # initialize
    init

    # link in web services
    if {$linkWebservices} {
        set linkName [file join $packageDirectory twist-oacs www ws]
        set newTarget [file join $versionDirectory packages wsapi www]
        updateFileLink $linkName $newTarget
    }
    # link documentation
    if {$linkDocumentation} {
        set linkName [file join $packageDirectory twist-oacs www doc]
        set newTarget [file join $versionDirectory packages doc www]
        updateFileLink $linkName $newTarget
    }
    # link TWiST to NaviServer
    set linkName [file join $tclLibDirectory twist]
    set newTarget $versionDirectory
    updateFileLink $linkName $newTarget
}

proc ::twist::install::upgrade-version {  } {

    ::twist::install::before-install

}
