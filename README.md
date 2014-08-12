**Author:** Mujihina
**Version:** v 1.20140812

# Widescantool #

- Filters: This addon allows you configure filters for widescan output at a global level, and per area. By default, it will also filter common mob pets from widescan.
- Alerts: This addon allows you to configure alerts for widescan output at a global level, and per area.

Filters/Alerts are stored locally in a config file.

Alerts are simply messages to your chat log to help you in case you missed what you were looking for.


## Syntax ##

Syntax can be obtained by running the command without arguments, or with the subcommand 'help'

Current syntax is:

wst lg: List Global settings
wst la: List settings for current Area
wst laaf: List All Area Filters
wst laaa: List All Area Alerts
wst agf <name or pattern>: Add Global Filter
wst rgf <name or pattern>: Remove Global Filter
wst aga <name or pattern>: Add Global Alert
wst rga <name or pattern>: Remove Global Alert
wst aaf <name or pattern>: Add Area Filter
wst raf <name or pattern>: Remove Area Filter
wst aaa <name or pattern>: Add Area Alert
wst raa <name or pattern>: Remove Area Alert   
wst defaults: Reset to default settings
wst toggle: Enable/Disable all filters/alerts temporarily
wst pet: Enable/Disable filtering of common mob pets

## Patterns ##

Patterns will be converted to lowercase, so when providing a name or pattern to the addon you do not need to worry about case.

Names and patterns can contain spaces, and some special characters like '.
For instance, it is fine to use these as patterns:
goblin tinkerer
gigas's leech

However, it is not advisable to use characters not found in mob names. 


### Examples ###

Adding the pattern goblin as a global filter:

```
wst agf goblin
```

Adding the pattern air elemental as a global alert:

```
wst aga air elemental
```

Adding the pattern emperor to the alerts for your current area:
```
wst aaa emperor
```

Removing the previously added pattern damselfly from the filters for your current area:
```
wst raf damselfly
```

Listing the current global filters/alerts:
```
wst lg
```

##Notes##
Note that if your patterns are too short, they might unintentionally trigger alerts or filters you do not want.

For example, say you were trying to target all orcs, by using the pattern 'orc', it would also match anything with the name 'sorcerer' as 'orc' is in that string.


##TODO##
- add option to automatically set the first (or closest) match as your tracking target.


##Changelog##

### v1.20140812 ###
* Major cleanup to address issues from changes to standard libs.
* .xml file should be more reader-friendly for those who want to 
add filters/alerts directly.

### v1.20140424 ###
* First release.
