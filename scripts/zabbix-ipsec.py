#!/usr/local/bin/python3.8

import itertools
import re
import sys
import xml.etree.cElementTree as ET

IPSEC_CONF = '/var/etc/ipsec/swanctl.conf'
rtt_time_warn = 200
rtt_time_error = 300

def parseConf():
    reg_conn = re.compile('con[0-9]+')
    reg_local = re.compile('(?<=local_addrs = ).*')
    reg_remote = re.compile('(?<=remote_addrs = ).*')
    reg_descr = re.compile('^\s*# P1 \(ikeid [0-9]+\): (.+)\s*$', re.MULTILINE)
    
    data = {}
    with open(IPSEC_CONF, 'r') as f:
        soubor = f.read()
        groups = re.findall('(con[0-9]+\s*?{.*?)(?=^\s*dpd_action.*?}.*?}.*?})', soubor, flags=re.DOTALL|re.MULTILINE)
        for g in groups:
            conn_tmp = list()
            m = re.search(reg_conn, g)
            m = m.group(0)
            if m:
                conn_tmp.append(m)
            local_tmp = list()
            m1 = re.search(reg_local, g)
            m1 = m1.group(0)
            if m1:
                local_tmp.append(m1)
            remote_tmp = list()
            m2 = re.search(reg_remote, g)
            m2 = m2.group(0)
            if m2:
                remote_tmp.append(m2)
            descr_tmp = list()
            m3 = re.search(reg_descr, g)
            m3 = m3.group(1)
            if m3:
                descr_tmp.append(m3)
            
            if conn_tmp and local_tmp and remote_tmp and descr_tmp:
                    data[conn_tmp[0]] = [local_tmp[0], remote_tmp[0], descr_tmp[0]]
        return data

def getTemplate():
    template = """
        {{ "{{#TUNNEL}}":"{0}","{{#TARGETIP}}":"{1}","{{#SOURCEIP}}":"{2}","{{#DESCRIPTION}}":"{3}" }}"""

    return template

def getPayload():
    final_conf = """{{
    "data":[{0}
    ]
}}"""

    conf = ''
    data = parseConf().items()
    for key,value in data:
        tmp_conf = getTemplate().format(
            key,
            value[1],
            value[0],
            value[2],
            rtt_time_warn,
            rtt_time_error
        )
        if len(data) > 1:
            conf += '%s,' % (tmp_conf)
        else:
            conf = tmp_conf
    if conf[-1] == ',':
        conf=conf[:-1]
    return final_conf.format(conf)

if __name__ == "__main__":
    ret = getPayload()
    sys.exit(ret)
