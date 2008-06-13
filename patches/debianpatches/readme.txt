(submitted by Torsten)

cisco_fw.diff
config_path.diff
daemon_check.diff
daemon_interval.diff
maxinterval.diff
sample_path.diff
smc-barricade-7401bra.patch
smc-barricade-fw-alt.diff
update-new-config.patch

cisco_fw.diff: Not sure what this change was about, have to check my
     change log.
daemon_check.diff: Changes interpretation of the daemon parameter
      to interval (to allow 5m for minutes etc.) when checking for min
       value.
daemon_interval.diff: Changes interpretation of daemon interval during
        input (now that I look at this, those two could probably be merged).
	maxinterval.diff: Increase max interval for updates.
	sample_path.diff: Adjust path in stamples.
	update-new-config.patch: Force update if config has changed (still
	 needed?)
	 smc-*: Support for two more routers.
