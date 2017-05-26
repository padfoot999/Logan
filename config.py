#!/usr/bin/python -tt
__description__ = 'Configuration file to store all "global" variables and setup logging'
# Usage:
# from config import CONFIG
# list_of_vt_api_keys = CONFIG['VTCHECKER']['VT_API2_KEYS']
# proxies = CONFIG['ONLINE']['PROXIES']
# is_mitm_proxy = CONFIG['ONLINE']['MITMPROXY']


import logging
import os
import OUTPUT_log
OUTPUT_log.setupLogger('root')

# Install tor browser when VT has blocked your IP address. Use socks5 proxy for tor.
# URL: https://www.torproject.org/download/download-easy.html.en
#NAME: isMitmProxy
#OUTPUT: TRUE or FALSE
#DESCRIPTION: To determine if we want to disable SSL cert verification if we are using a proxy (as MITM cert injection is most likely present)
# Usage E.g:
# import requests
# req = requests.get(
#             url, 
#             params={'resource': query, 'apikey': self.vt_api2_key}, 
#             proxies=getProxies(),
#             verify=(not isMitmProxy()))
def isMitmProxy():
    #return PROXIES["http"].count('proxy.sg.kworld.kpmg.com:8080/') or PROXIES["https"].count('proxy.sg.kworld.kpmg.com:8080/')
    return PROXIES["http"].count('socks5://127.0.0.1:9150') or PROXIES["https"].count('socks5://127.0.0.1:9150')

#NAME: PROXIES
#OUTPUT: N/A
#DESCRIPTION: Proxy config for use in Requests library 
#Refer to http://requests.readthedocs.org/en/master/user/advanced/#proxies
PROXIES = {
    # take from these examples and mod as per necessary
    "http": "",
    #"http": "socks5://127.0.0.1:9150", 
    #"http": "http://proxy.sg.kworld.kpmg.com:8080/",
    # "http": "http://10.10.1.10:3128",
    "https": "",    
    #"https": "socks5://127.0.0.1:9150",
    # "https": "http://proxy.sg.kworld.kpmg.com:8080/",
    # "https": "http://10.10.1.10:1080",    
}

#NAME: PROXIES
#OUTPUT: N/A
#DESCRIPTION: Proxy config for use in Requests library 
VT_API2_KEYS = []
try:
    with open('config_vtKeys.txt') as f:
        for line in f:
            #Copy to all virustotal API keys to memory... ...
            VT_API2_KEYS.append(line.strip())
except:
    pass
# finally:
#     print "%s keys in VT keypool loaded" % len(VT_API2_KEYS)

#NAME: CONFIG
#OUTPUT: N/A
#DESCRIPTION: Main Configuration parameters
CONFIG = {

    'DATABASE': {
        'DATABASENAME': "'logan'",
        'HOST': "'127.0.0.1'",
        'USER': "'postgres'",
        'PASSWORD': "'kpmg@123'",
    },

    'ONLINE': {
        'PROXIES': PROXIES,
        'MITMPROXY': isMitmProxy(),
    },

    'USB': {
        'CACHE': 'Resources',
    },
}