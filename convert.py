#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import json
import struct
import index_pb2
import collections

if __name__ == "__main__":
    filename = sys.argv[1]
    obj = open(filename,'rb').read()
    out = open(filename.replace('.json','.pbf'),'wb')
    data = json.loads(obj,object_pairs_hook=collections.OrderedDict);
    message = index_pb2.object()
    for key in data.keys():
        vals = data[key]
        item = message.items.add()
        item.key = long(key)
        for val in vals:
            array = item.arrays.add()
            for arr in val:
                i = array.val.append(arr)
    #print message #.SerializeToString()
    out.write(message.SerializeToString())
    out.close()


