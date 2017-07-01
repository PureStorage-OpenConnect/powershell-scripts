# -*- coding: utf-8 -*-

#
## Overview
#
# This short Python example illustrates how to build a simple PRTG custom sendor to monitor
# Pure Storage FlashArrays. The Pure Storage Python REST Client is used to query the FlashArray 
# to get the basic performance counters.
#
## Installation
# 
# The script should be copied into the appropriate folder on the Windows machine hosting the PRTG master
# server or the proxy agent. This location is usually C:\Program Files (x86)\PRTG Network Monitor\Custom Sensors\python
#
## Dependencies
#
#  purestorage       Pure Storage Python REST Client (https://github.com/purestorage/rest-client)
#

import sys
import json
import purestorage
import urllib3


# get CustomSensorResult from paepy package
from paepy.ChannelDefinition import CustomSensorResult

if __name__ == "__main__":
	# interpret first command line parameter as json object
	data = json.loads(sys.argv[1])

    # create sensor result
	params = json.loads(data['params'])
	result = CustomSensorResult("Pure Storage performance info")
	urllib3.disable_warnings()
	fa = purestorage.FlashArray(params['addr'], api_token=params['api_token'])
	fainfo = fa.get(action='monitor')
	fa.invalidate_cookie()
	
    # add primary channel
	result.add_channel(channel_name="wr sec", unit="IOPS write", value=fainfo[0]['writes_per_sec'], primary_channel=True)
	# add additional channels
	result.add_channel(channel_name="rd sec", unit="IOPS read", value=fainfo[0]['reads_per_sec'])
	result.add_channel(channel_name="wr latency", unit="usec", value=fainfo[0]['usec_per_write_op'])
	result.add_channel(channel_name="rd latency", unit="usec", value=fainfo[0]['usec_per_read_op'])
	result.add_channel(channel_name="in sec", unit="BytesBandwidth", value=fainfo[0]['input_per_sec'])
	result.add_channel(channel_name="out sec", unit="BytesBandwidth", value=fainfo[0]['output_per_sec'])
	result.add_channel(channel_name="q depth", unit="avg queued", value=fainfo[0]['queue_depth'])
	# print sensor result to std
	print(result.get_json_result())
