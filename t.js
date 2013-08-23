var fs = require('fs');
//var mem = require('./lib/mem.node');
var type = 'grid';
var shard = 0;
var times = 100;

var json = fs.readFileSync(__dirname + '/test/fixtures/' + type + '.' + shard + '.json');
var proto = fs.readFileSync(__dirname + '/test/fixtures/' + type + '.' + shard + '.pbf');

console.time('parse json x' + times);
for (var i = 0; i < times; i++) JSON.parse(json);
console.timeEnd('parse json x' + times);

function Message(name,buffer) {
    this.name = name;
    this.data = buffer;
    this.pos = 0;
    this.end = buffer.length;
    this.value = undefined;
    this.tag = undefined;
}

Message.prototype.reset = function() {
    this.pos = 0;
    this.end = this.data.length;
    this.value = undefined;
    this.tag = undefined;
}

Message.prototype.next = function() {
    if (this.pos < this.end) {
        this.value = this.decode_varint();
        this.tag = this.value >> 3;
        return true;
    }
    return false;
}

Message.prototype.skipBytes = function(bytes) {
    this.pos = this.pos + bytes;
    if (this.pos > this.end) {
        throw new Error("unterminated varint, unexpected end of buffer");
    }
}

Message.prototype.skip = function() {
   var val = this.value & 0x7; // wire type
   if (val == 0) {
       this.decode_varint();
   } else if (val == 1) { // int64 and double
       this.skipBytes(8);
   } else if (val == 2) { // string
       this.skipBytes(this.decode_varint());
   } else if (val == 5) { // int32 and float
       this.skipBytes(4);
   } else {
      throw new Error("unknown type: %d | %s | %d in %s");
   }
}

Message.prototype.decode_varint = function() {
    var byte = 0x80;
    var result = 0;
    var bitpos = 0;
    while (bitpos < 70 && (byte & 0x80)) {
        if (this.pos >= this.end) {
            throw new Error("unterminated varint, unexpected end of buffer in " + this.name);
        }
        byte = this.data[this.pos];
        //console.log(byte)
        result |= (byte & 0x7F) << bitpos;
        bitpos = bitpos + 7;
        ++this.pos;
    }
    if (bitpos == 70 && (byte & 0x80)) {
        throw new Error("unterminated varint (too long) in " + this.name);
    }
    return result
}

Message.prototype.decode_string = function() {
    length = this.decode_varint();
    //data = str(this.data[this.pos:this.pos+length]).decode('utf8')
    this.skipBytes(length);
    return 'foo';//data.encode('utf8')
}

Message.prototype.decode_float = function() {
    //val = struct.unpack('<f',str(this.data[this.pos:this.pos+4]))[0]
    this.skipBytes(4)
    return .5;
}
Message.prototype.decode_double = function() {
    var val = this.buf.readDoubleLE(this.pos);
    //val = struct.unpack('<d',str(this.data[this.pos:this.pos+8]))[0]
    this.skipBytes(8)
    return val
}
Message.prototype.decode_bool = function() {
    return bool(this.decode_varint())
}

Message.prototype.decode_int64 = function() {
    return this.decode_varint();
}

Message.prototype.decode_sint64 = function() {
    return this.decode_varint();
}

Message.prototype.decode_uint64 = function() {
    return this.decode_varint();
}

Message.prototype.decode_int32 = function() {
    return this.decode_varint();
}

Message.prototype.get_data = function(len) {
    return this.data.slice(this.pos,this.pos+len);
}

var parse = function(message) {
    var obj = {};
    while (message.next()) {
        if (message.tag == 1) {
            len = message.decode_varint();
            //console.log(len);
            var item = new Message('item',message.get_data(len))
            var key = 0
            var val_array = []
            while (item.next()) {
                if (item.tag == 1) {
                    var arrays_length = item.decode_varint()
                    var array = new Message('arrays',item.get_data(arrays_length))
                    while (array.next()) {
                        if (array.tag == 1) {
                            var vals_length = array.decode_varint()
                            var val = new Message('vals',array.get_data(vals_length))
                            var v2 = []
                            while (val.next()) {
                                v2.push(val.value)
                            }
                            val_array.push(v2)
                            array.skipBytes(vals_length)
                        } else {
                            throw new Error("skipping when shouldnt")
                            array.skip();
                        }
                    }
                    item.skipBytes(arrays_length)
                } else if (item.tag == 2) {
                    key = item.decode_int64();
                    //item.skip();
                } else {
                    throw new Error("hit unknown type: "+ item.tag);
                }
                obj[key.toFixed()] = val_array;
            }
            message.skipBytes(len);
        } else {
            throw new Error("skipping when shouldnt");
            message.skip();
        }
    }
    return obj;
}

var message = new Message('message',proto);

var name = 'parse proto js sync x'
console.time(name + times);
for (var i = 0; i < times; i++) {
   message.reset();
   parse(message)
   //console.log(parse(message));
}
console.timeEnd(name + times);
