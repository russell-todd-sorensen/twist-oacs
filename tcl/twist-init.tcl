# dumb, but this code should not execute unless twist is installed, meaning
# before-install has run.
# initialize
::twist::install::init

# Runs during upgrade to create links
namespace eval ::twist::install {
    if {$upgradeNow} {
        after-install
        if {$installed} {
            parameter::set_from_package_key -package_key $package -parameter upgradeNow -value "0"
        }
    }
}

# Runs each time OpenACS is restarted. If version is changed, may download new files first.
namespace eval ::twist::install {
    ns_log Notice "::twist::install installed = '$installed' versionDirectory = '$versionDirectory'"
    if {$installed} {
	if {[file exists [file join $versionDirectory init.tcl]]} {
            ns_log Notice "::twist::install sourcing '[file join $versionDirectory init.tcl]'"
            source [file join $versionDirectory init.tcl]
        } else { 
            ns_log Notice "::twist::install upgrading to version $version"
            upgrade-version
            after-install
            source [file join $versionDirectory init.tcl]
        }
    }

}



