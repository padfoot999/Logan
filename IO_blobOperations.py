from time import gmtime, strftime
import sys
import hexdump
import argparse
import subprocess
from argparse import RawTextHelpFormatter
import os
import fnmatch
import plistlib
import biplist
import pandas as pd
import numpy as np
import ccl_bplist
import re
from config import CONFIG
import IO_databaseOperations as db
import logging
logger = logging.getLogger('root')
import datetime
from openpyxl import Workbook, load_workbook
from struct import unpack
import time
import IO_blobOperations

def convert_mac_timestamp(value):
    mac_date = time.strftime('%Y-%m-%d %H:%M:%S', time.localtime(value + 978307200))
    return mac_date

def extract_creationdate(bookmark_data):
    content_offset, = unpack('I', bookmark_data[12:16])
    first_TOC, = unpack('I', bookmark_data[content_offset:content_offset+4])
    first_TOC += content_offset
    TOC_len, rec_type, level, next_TOC, record_count = unpack('IIIII', bookmark_data[first_TOC:first_TOC+20])
    TOC_cursor = first_TOC + 20
    record_offsets = {}
    for i in range(record_count):
        record_id, offset = unpack('<IQ', bookmark_data[TOC_cursor:TOC_cursor+12])
        record_offsets[record_id] = offset + content_offset
        TOC_cursor += 12
    mount_record = record_offsets.get(0x1040, None)
    # Check to see if we actually had a volMountURL record
    if mount_record is not None:
        mount_length, rec_type = unpack('II', bookmark_data[mount_record:mount_record+8])
        mount_record += 8
        creation_date, = unpack('>d', bookmark_data[mount_record:mount_record+mount_length])
        if creation_date == -978307200.0:
            creation_date = "Not Set"
        else:
            creation_date = convert_mac_timestamp(int(creation_date))
            #mount_URL = (bookmark_1102881220data[mount_record:mount_record+mount_length]).decode('utf-8')
        return creation_date
    else:
        return "Not set"

def extract_volume(bookmark_data):
    try:
        content_offset, = unpack('I', bookmark_data[12:16])
        first_TOC, = unpack('I', bookmark_data[content_offset:content_offset+4])
        first_TOC += content_offset
        TOC_len, rec_type, level, next_TOC, record_count = unpack('IIIII', bookmark_data[first_TOC:first_TOC+20])
        TOC_cursor = first_TOC + 20
        record_offsets = {}
        for i in range(record_count):
            record_id, offset = unpack('<IQ', bookmark_data[TOC_cursor:TOC_cursor+12])
            record_offsets[record_id] = offset + content_offset
            TOC_cursor += 12
        mount_record = record_offsets.get(0x2010, None)
        # Check to see if we actually had a volMountURL record
        if mount_record is not None:
            mount_length, rec_type = unpack('II', bookmark_data[mount_record:mount_record+8])
            mount_record += 8
            voluuid = (bookmark_data[mount_record:mount_record+mount_length]).decode('utf-8')
            print voluuid
            return voluuid
        else:
            return "Not set"
    except Exception as e:
        return "Not set"

def extract_voluuid(bookmark_data):
    try:
        content_offset, = unpack('I', bookmark_data[12:16])
        first_TOC, = unpack('I', bookmark_data[content_offset:content_offset+4])
        first_TOC += content_offset
        TOC_len, rec_type, level, next_TOC, record_count = unpack('IIIII', bookmark_data[first_TOC:first_TOC+20])
        TOC_cursor = first_TOC + 20
        record_offsets = {}
        for i in range(record_count):
            record_id, offset = unpack('<IQ', bookmark_data[TOC_cursor:TOC_cursor+12])
            record_offsets[record_id] = offset + content_offset
            TOC_cursor += 12
        mount_record = record_offsets.get(0x2011, None)
        # Check to see if we actually had a volMountURL record
        if mount_record is not None:
            mount_length, rec_type = unpack('II', bookmark_data[mount_record:mount_record+8])
            mount_record += 8
            voluuid = (bookmark_data[mount_record:mount_record+mount_length]).decode('utf-8')
            return voluuid
        else:
            return "Not set"
    except Exception as e:
        return "Not set"