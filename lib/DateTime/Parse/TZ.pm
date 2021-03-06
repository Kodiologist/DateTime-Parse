module DateTime::Parse::TZ;

# http://en.wikipedia.org/w/index.php?title=List_of_time_zone_abbreviations&oldid=394464318

# /(\S+)\s+(\S.+?)\s*UTC(([+-]\d+)?)((:30)?)/ or die; my ($abb, $d, $h, $m) = ($1, $2, $3, $5); $_ = sprintf "    %-5s   =>   %+6d,   # %s", $abb, (60*60*$h + ($m ? $h/abs($h)*60*30*$m : 0)), $d

# It's important that none of these coincide with the other
# abbreviations defined at the top of Parse.pm. Camelia forbid
# there should be a time zone named "MAY".

our sub zones () {
    ACDT    =>   +36000,   # Australian Central Daylight Time
    ACST    =>   +32400,   # Australian Central Standard Time
    ACT     =>   +28800,   # ASEAN Common Time
    ADT     =>   -10800,   # Atlantic Daylight Time
    AEDT    =>   +39600,   # Australian Eastern Daylight Time
    AEST    =>   +36000,   # Australian Eastern Standard Time
    AFT     =>   +14400,   # Afghanistan Time
    AKDT    =>   -28800,   # Alaska Daylight Time
    AKST    =>   -32400,   # Alaska Standard Time
    AMST    =>   +18000,   # Armenia Summer Time
    AMT     =>   +14400,   # Armenia Time
    ART     =>   -10800,   # Argentina Time
  # AST     =>   +10800,   # Arab Standard Time (Kuwait, Riyadh)
  # AST     =>   +14400,   # Arabian Standard Time (Abu Dhabi, Muscat)
  # AST     =>   +10800,   # Arabic Standard Time (Baghdad)
    AST     =>   -14400,   # Atlantic Standard Time
    AWDT    =>   +32400,   # Australian Western Daylight Time
    AWST    =>   +28800,   # Australian Western Standard Time
    AZOST   =>    -3600,   # Azores Standard Time
    AZT     =>   +14400,   # Azerbaijan Time
    BDT     =>   +28800,   # Brunei Time
    BIOT    =>   +21600,   # British Indian Ocean Time
    BIT     =>   -43200,   # Baker Island Time
    BOT     =>   -14400,   # Bolivia Time
    BRT     =>   -10800,   # Brasilia Time
  # BST     =>   +21600,   # Bangladesh Standard Time
    BST     =>    +3600,   # British Summer Time (British Standard Time from Feb 1968 to Oct 1971)
    BTT     =>   +21600,   # Bhutan Time
    CAT     =>    +7200,   # Central Africa Time
    CCT     =>   +21600,   # Cocos Islands Time
    CDT     =>   -18000,   # Central Daylight Time (North America)
    CEDT    =>    +7200,   # Central European Daylight Time
    CEST    =>    +7200,   # Central European Summer Time
    CET     =>    +3600,   # Central European Time
    CHAST   =>   +43200,   # Chatham Standard Time
    CIST    =>   -28800,   # Clipperton Island Standard Time
    CKT     =>   -36000,   # Cook Island Time
    CLST    =>   -10800,   # Chile Summer Time
    CLT     =>   -14400,   # Chile Standard Time
    COST    =>   -14400,   # Colombia Summer Time
    COT     =>   -18000,   # Colombia Time
    CST     =>   -21600,   # Central Standard Time (North America)
  # CST     =>   +28800,   # China Standard Time
    CVT     =>    -3600,   # Cape Verde Time
    CXT     =>   +25200,   # Christmas Island Time
  # ChST    =>   +36000,   # Chamorro Standard Time
      # No lowercase for now.
    DFT     =>    +3600,   # AIX specific equivalent of Central European Time
    EAST    =>   -21600,   # Easter Island Standard Time
    EAT     =>   +10800,   # East Africa Time
    ECT     =>   -14400,   # Eastern Caribbean Time (does not recognise DST)
  # ECT     =>   -18000,   # Ecuador Time
    EDT     =>   -14400,   # Eastern Daylight Time (North America)
    EEDT    =>   +10800,   # Eastern European Daylight Time
    EEST    =>   +10800,   # Eastern European Summer Time
    EET     =>    +7200,   # Eastern European Time
    EST     =>   -18000,   # Eastern Standard Time (North America)
    FJT     =>   +43200,   # Fiji Time
    FKST    =>   -10800,   # Falkland Islands Summer Time
    FKT     =>   -14400,   # Falkland Islands Time
    GALT    =>   -21600,   # Galapagos Time
    GET     =>   +14400,   # Georgia Standard Time
    GFT     =>   -10800,   # French Guiana Time
    GILT    =>   +43200,   # Gilbert Island Time
    GIT     =>   -32400,   # Gambier Island Time
    GMT     =>       +0,   # Greenwich Mean Time
    GST     =>    -7200,   # South Georgia and the South Sandwich Islands
    GYT     =>   -14400,   # Guyana Time
    HADT    =>   -32400,   # Hawaii-Aleutian Daylight Time
    HAST    =>   -36000,   # Hawaii-Aleutian Standard Time
    HKT     =>   +28800,   # Hong Kong Time
    HMT     =>   +18000,   # Heard and McDonald Islands Time
    HST     =>   -36000,   # Hawaii Standard Time
    IRKT    =>   +28800,   # Irkutsk Time
    IRST    =>   +10800,   # Iran Standard Time
  # IST     =>   +18000,   # Indian Standard Time
    IST     =>    +3600,   # Irish Summer Time
  # IST     =>    +7200,   # Israel Standard Time
    JST     =>   +32400,   # Japan Standard Time
    KRAT    =>   +25200,   # Krasnoyarsk Time
    KST     =>   +32400,   # Korea Standard Time
    LHST    =>   +36000,   # Lord Howe Standard Time
    LINT    =>   +50400,   # Line Islands Time
    MAGT    =>   +39600,   # Magadan Time
    MDT     =>   -21600,   # Mountain Daylight Time (North America)
    MIT     =>   -32400,   # Marquesas Islands Time
    MSD     =>   +14400,   # Moscow Summer Time
    MSK     =>   +10800,   # Moscow Standard Time
  # MST     =>   +28800,   # Malaysian Standard Time
    MST     =>   -25200,   # Mountain Standard Time (North America)
  # MST     =>   +21600,   # Myanmar Standard Time
    MUT     =>   +14400,   # Mauritius Time
    NDT     =>    -7200,   # Newfoundland Daylight Time
    NFT     =>   +39600,   # Norfolk Time[1]
    NPT     =>   +18000,   # Nepal Time
    NST     =>   -10800,   # Newfoundland Standard Time
    NT      =>   -10800,   # Newfoundland Time
    OMST    =>   +21600,   # Omsk Time
    PDT     =>   -25200,   # Pacific Daylight Time (North America)
    PETT    =>   +43200,   # Kamchatka Time
    PHOT    =>   +46800,   # Phoenix Island Time
    PKT     =>   +18000,   # Pakistan Standard Time
    PST     =>   -28800,   # Pacific Standard Time (North America)
  # PST     =>   +28800,   # Philippine Standard Time
    RET     =>   +14400,   # Réunion Time
    SAMT    =>   +14400,   # Samara Time
    SAST    =>    +7200,   # South African Standard Time
    SBT     =>   +39600,   # Solomon Islands Time
    SCT     =>   +14400,   # Seychelles Time
    SLT     =>   +18000,   # Sri Lanka Time
    SST     =>   -39600,   # Samoa Standard Time
  # SST     =>   +28800,   # Singapore Standard Time
    TAHT    =>   -36000,   # Tahiti Time
    THA     =>   +25200,   # Thailand Standard Time
    UTC     =>       +0,   # Coordinated Universal Time
    UYST    =>    -7200,   # Uruguay Summer Time
    UYT     =>   -10800,   # Uruguay Standard Time
    VET     =>   -14400,   # Venezuelan Standard Time
    VLAT    =>   +36000,   # Vladivostok Time
    WAT     =>    +3600,   # West Africa Time
    WEDT    =>    +3600,   # Western European Daylight Time
    WEST    =>    +3600,   # Western European Summer Time
    WET     =>       +0,   # Western European Time
    YAKT    =>   +32400,   # Yakutsk Time
    YEKT    =>   +18000,   # Yekaterinburg Time
    Z       =>       +0,
}
