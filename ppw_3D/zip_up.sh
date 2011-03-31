#!/bin/tcsh

set name = "ppw_3D"

foreach os( linux macosx windows )
   set dir = "app_"$name"_"$os
   set zipfile = "app_"$name"_"$os".zip"
   mv application.$os $dir
   cp -r data $dir
   zip -r $zipfile $dir
end
