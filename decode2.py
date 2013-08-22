#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import struct
import index_pb2

def print_message_type(pb):
    for item in pb.items:
        print item.key, [i.val for i in item.arrays]
        

if __name__ == "__main__":
    filename = sys.argv[1]
    data = open(filename,'rb').read()
    pb = index_pb2.object()
    pb.ParseFromString(data)
    print_message_type(pb)
