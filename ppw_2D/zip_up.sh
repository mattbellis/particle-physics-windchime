#!/bin/tcsh

set name = "ppw_2D"

foreach os( linux macosx windows )
   set dir = $name"_"$os
   set zipfile = $name"_"$os".zip"
   mkdir $dir
   cp -r data application.$os 
   cp -r application.$os $dir
   zip -r $zipfile $dir
end
