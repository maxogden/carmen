#pragma once

/*
 * Some parts are from upb - a minimalist implementation of protocol buffers.
 *
 * Copyright (c) 2008-2011 Google Inc.  See LICENSE for details.
 * Author: Josh Haberman <jhaberman@gmail.com>
 */

#include <stdint.h>
#include <stdexcept>
#include <string>
#include <cassert>

namespace llmr {

#define FORCEINLINE inline __attribute__((always_inline))
#define NOINLINE __attribute__((noinline))
#define PBF_INLINE FORCEINLINE

struct pbf {
	PBF_INLINE pbf(const unsigned char *data, uint32_t length);
	PBF_INLINE pbf(const char *data, uint32_t length);
	PBF_INLINE pbf(const std::string& buffer);

	PBF_INLINE bool next();
	PBF_INLINE uint64_t varint();
	PBF_INLINE int64_t svarint();
	PBF_INLINE std::string string();
	PBF_INLINE float float32();
	PBF_INLINE double float64();
	PBF_INLINE int64_t int64();
	PBF_INLINE bool boolean();

	template <typename T, typename... Args>
	PBF_INLINE T *message(const Args&... args);

	PBF_INLINE void skip();
	PBF_INLINE void skipValue(uint32_t val);
	PBF_INLINE void skipBytes(uint32_t bytes);

	const uint8_t *data;
	const uint8_t *end;
	uint64_t value;
	uint32_t tag;
};

pbf::pbf(const unsigned char *data, uint32_t length)
	: data(data),
	  end(data + length)
{
		//std::clog << "end: " << length << "\n";
}

pbf::pbf(const char *data, uint32_t length)
	: data((const unsigned char *)data),
	  end((const unsigned char *)data + length)
{
		//std::clog << "end: " << length << "\n";

}

pbf::pbf(const std::string& buffer)
	: data((const unsigned char *)buffer.data()),
	  end((const unsigned char *)buffer.data() + buffer.size())
{}

bool pbf::next()
{
	if (data < end) {
		value = varint();
		tag = value >> 3;
		return true;
	}
	return false;
}


uint64_t pbf::varint()
{
	uint8_t byte = 0x80;
	uint64_t result = 0;
	int bitpos;
	for (bitpos = 0; bitpos < 70 && (byte & 0x80); bitpos += 7) {
		if (data >= end) {
			throw std::runtime_error("unterminated varint, unexpected end of buffer");
		}
		result |= ((uint64_t)(byte = *data) & 0x7F) << bitpos;
		data++;
	}
	if (bitpos == 70 && (byte & 0x80)) {
		throw std::runtime_error("unterminated varint (too long)");
	}

	return result;
}

int64_t pbf::svarint()
{
	uint64_t n = varint();
	return (n >> 1) ^ -(int64_t)(n & 1);
}

std::string pbf::string()
{
	uint32_t bytes = varint();
	const char *string = (const char *)data;
	skipBytes(bytes);
	return std::string(string, bytes);
}

float pbf::float32()
{
	skipBytes(4);
	float result;
	memcpy(&result, data - 4, 4);
	return result;
}
double pbf::float64()
{
	skipBytes(8);
	double result;
	memcpy(&result, data - 8, 8);
	return result;
}

int64_t pbf::int64()
{
	return (int64_t)varint();
}

bool pbf::boolean()
{
	skipBytes(1);
	return *(bool *)(data - 1);
}


template <typename T, typename... Args> T *pbf::message(const Args&... args)
{
	uint32_t bytes = varint();
    T *result = new T(data, bytes, args...);
    skipBytes(bytes);
    return result;
}

void pbf::skip()
{
	skipValue(value);
}

void pbf::skipValue(uint32_t val)
{
	switch (val & 0x7) {
		case 0: // varint
			varint();
			break;
		case 1: // 64 bit
			skipBytes(8);
			break;
		case 2: // string/message
			skipBytes(varint());
			break;
		case 5: // 32 bit
			skipBytes(4);
			break;
		default:
			char msg[80];
			snprintf(msg, 80, "cannot skip unknown type %d", val & 0x7);
			throw std::runtime_error(msg);
	}
}

void pbf::skipBytes(uint32_t bytes)
{
	data += bytes;
	if (data > end) {
		throw std::runtime_error("unexpected end of buffer");
	}
}

} // end namespace llmr

