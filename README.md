# Logan

### Step by Step Guide to power up LOGAN on Windows

1. Download Logan Files from "https://github.com/padfoot999/Logan"
2. Install Python 2.7 (32 bit)
3. Configure Python Path in Windows System Environment Variables
4. Install PostgreSQL
5. Go to PGAdmin, create server with the following setting
        <br />Name: "magneto"
        <br />Host name/Add: "127.0.0.1"
        <br />User name: postgres
        <br />Password: password
6. After creating server, create database "logan"
7. Install all necessary python modules (i.e. hexdump, biplist) using pip (C:\Python27\Scripts). Refer to requirements.txt for full list of dependencies.

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
