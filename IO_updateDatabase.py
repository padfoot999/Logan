#!/usr/bin/python -tt
__author__ = "ZF"
__description__ = 'To import and launch individual parsers to insert into database for Triage and Memory files'

import collections
import IO_databaseOperations as db
import psycopg2
from config import CONFIG
import tempfile
import os
import argparse
import requests
from contextlib import closing
import csv
from bs4 import BeautifulSoup
from pprint import pformat as pf
from collections import deque
import xlrd
from datetime import datetime
import re
import sys
import win_inet_pton
from config import CONFIG
from requests.packages.urllib3.util.retry import Retry
from requests.adapters import HTTPAdapter
from requests.exceptions import ConnectionError
from requests.packages.urllib3.exceptions import InsecureRequestWarning
requests.packages.urllib3.disable_warnings(InsecureRequestWarning)

import logging
logger = logging.getLogger('root')

def getUSBListing(filepath):
	if filepath == '':
		# gimme tmp file
		tmpfd, tmpfpath = tempfile.mkstemp()
		success = False
		while not success:
			try:
				logger.info('Requesting for USB Listing Dump')
				with closing(
					requests.get(
						'http://www.linux-usb.org/usb.ids', 
						stream=True, 
						proxies=CONFIG['ONLINE']['PROXIES'],
						verify=(not CONFIG['ONLINE']['MITMPROXY'])
					)) as r:
					if r.status_code == 200:
						success = True
						logger.info('writing to temp file %s' % tmpfpath)
						with os.fdopen(tmpfd, 'wb+') as tmp:
							for chunk in r:
								tmp.write(chunk)
			except ConnectionError:
				logger.error('Unable to request for USB Listing Dump - network connection error')
		fileloc = tmpfpath
	else:
		fileloc = filepath

	# open the file, seek out header line, pass into CSV DictReader to read the rest of the file
	# check for valid conditions, process into data struct
	data = {
		'vendor_details': {},
		'product_details': [],
		'vendor_product_mapping': {}
	}

	with open(fileloc, 'rb') as f:
		reader = f.read().splitlines()
		for row in reader:
			print row
			# Ignore all commented lines
			if not row.startswith('#'):
				if re.match(r'^\w{4}', row):
					vendor_id = re.match(r'^(\w{4})', row).group(0)
					vendor_name = (re.match(r'^\w{4}(.*)$', row).group(1)).strip()
					data['vendor_details'][vendor_id] = vendor_name
				elif re.match(r'^\s+\w{4}', row):
					productData = {}
					row = row.strip()
					prod_id = re.match(r'^(\w{4})', row).group(0)
					prod_name = re.match(r'^\w{4}(.*)$', row).group(1).strip()
					productData['prodid'] = prod_id
					productData['prodname'] = prod_name
					productData['vid'] = vendor_id
					data['product_details'].append(productData)

	# if 'tmpfpath' in locals():
	#     os.remove(tmpfpath)
	return data

def insertUSBListing(filepath, databaseConnectionHandle):
	#debug(DEBUG_FLAG, "INFO: databaseConnectionHandle is " + str(databaseConnectionHandle) + "\n")
	
	#=========================================================================================#
	#Populating Table vendor_details

	Schema = "usb_id"
	data = getUSBListing(filepath)
	insertVendor = data['vendor_details']
	insertProduct = data['product_details']

	for vid, vname in insertVendor.iteritems():
		Table = "vendor_details"
		insertVendorValue = collections.OrderedDict.fromkeys(['vendorid', 'vendorname'])
		insertVendorValue['vendorid'] = vid
		insertVendorValue['vendorname'] = vname
		db.databaseExistInsert(databaseConnectionHandle, Schema, Table, insertVendorValue)

	for prodDetails in insertProduct:
		Table = "product_details"
		insertProductValue = collections.OrderedDict.fromkeys(['prodid', 'prodname', 'vendorid'])
		insertProductValue['prodid'] = prodDetails['prodid']
		insertProductValue['prodname'] = prodDetails['prodname']
		insertProductValue['vendorid'] = prodDetails['vid']
		db.databaseExistInsert(databaseConnectionHandle, Schema, Table, insertProductValue)

def main():
	
	db.databaseInitiate()
	
	#Image name is obtained from Incident Log.txt AND/OR *-log.txt from memory
	DATABASE = CONFIG['DATABASE']
	dbhandle = db.databaseConnect(DATABASE['HOST'], DATABASE['DATABASENAME'], DATABASE['USER'], DATABASE['PASSWORD'])
	logger.info("dbhandle is " + str(dbhandle))

	parser = argparse.ArgumentParser(description="Process triage, network or memory dump evidence file(s), sorted by projects for correlation")
	parser.add_argument('-source', dest='source', type=str, help="Path to USB-IDs text file")
	args = parser.parse_args()

	if args.source:
		insertUSBListing(args.source, dbhandle)
	else:
		insertUSBListing('', dbhandle)
	
if __name__ == '__main__':
	main()

