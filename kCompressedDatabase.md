---
layout: software
title: "The kCompressed Database for kCARTA"
date: 2012-12-29 13:30
comments: false
sharing: true
author: Sergio De Souza-Machado
footer: true
---
The kCompressed database is available in little endian (PC Linux boxes)
or big endian versions (Sun,SGI). The database is built using the HITRAN
releases; we started with H1998 and currently use the H2008 line
parameters 
 
 In late 2000, the database was generated for all atmospheric gases and
cross section gases using HITRAN98 parameters (with Toth water vapor
line parameters, and our CO$$_2$$ line-mixing). This is the v20 database. 
 
 After AIRS was launched, we updated the CO2 linemixing parameters, and
added on a v24 database the user needs for CO2 (instead of the v20
obtained above). 
 
In 2008 we updated some gases such as H$$_2$$O, HNO$$_3$$, SO$$_2$$, O$$_3$$ using
parameters from the H2008 database 
 
 In 2010 we updated all gases using the H2008 database.

|  Year made |  HITRAN version |  Big/Little Endian |  Comment    | Link |
|------------|:----------------|:-------------------|:------------|:-----|
|  2000      |  H1998          |  be                |  all gases   |                     [v20.ieee-be.tar](http://asl.umbc.edu/pub/packages/v20.ieee-be.tar) |
|            |                 |  le                |  all gases   |                     [v20.ieee-le.tar](http://asl.umbc.edu/pub/packages/v20.ieee-le.tar) |
|  2004      |  H2000          |  be                |  improved CO2 |                     [v24.ieee-be.tar](http://asl.umbc.edu/pub/packages/v24.ieee-be.tar) |
|            |                 |  le                |  improved CO2 |                     [v24.ieee-le.tar](http://asl.umbc.edu/pub/packages/v24.ieee-le.tar) |
|  2008      |  H2000/H2008    |  le                |  H2008 for some gases eg H$$_2$$O,HNO$$_3$$,O$$_3$$ |  [v07.ieee-le.tar](http://asl.umbc.edu/pub/packages/v07.ieee-le.tar) |
|  2010      |  H2008          |  le                |  H2008 for all gases, H2000 CO$$_2$$     | [water\_hdo\_etc\_H2008\_IR\_v1.ieee-le.tar for 605-2830 cm-1](http://asl.umbc.edu/pub/packages/water_hdo_etc_H2008_IR_v1.ieee-le.tar) |
|            |                 |                    |  reference gas profile              |  [refgasH2008.tar](http://asl.umbc.edu/pub/packages/refgasH2008.tar) |

