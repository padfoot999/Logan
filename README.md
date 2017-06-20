# Logan

## Collector Scripts
1. presponse_lin.sh
2. presponse_mac.sh
3. osxcollector.sh

## Logan Scripts
* Update database with MAC USB Info (For MAC OS X Only)
```
python IO_updateDatabase.py -source <Path to USB.txt file>
```
* Output lsof & netstat comparison (For Linux and MAC OS X)
```
python OUTPUT_lsofnetstat.py -d <Path to Incident folder> -p <Project Name>
```
* Output Summary File (For MAC OS X Only)
```
python OUTPUT_summary.py -d <Path to Incident folder> -r <Output folder after running PROCESS_postTriage.py> -p <Project Name>
python OUTPUT_summary.py -d "E:\\" -r "F:\\logan\\results\\PROJECT" -p PROJECT
```
