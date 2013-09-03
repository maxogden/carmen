
class TestPipe: public kj::BufferedInputStream, public kj::OutputStream {
public:
  TestPipe()
      : preferredReadSize(std::numeric_limits<size_t>::max()), readPos(0) {}
  explicit TestPipe(size_t preferredReadSize)
      : preferredReadSize(preferredReadSize), readPos(0) {}
  ~TestPipe() {}

  const std::string& getData() { return data; }
  void resetRead(size_t preferredReadSize = std::numeric_limits<size_t>::max()) {
    readPos = 0;
    this->preferredReadSize = preferredReadSize;
  }

  bool allRead() {
    return readPos == data.size();
  }

  void clear(size_t preferredReadSize = std::numeric_limits<size_t>::max()) {
    resetRead(preferredReadSize);
    data.clear();
  }

  void write(const void* buffer, size_t size) override {
    data.append(reinterpret_cast<const char*>(buffer), size);
  }

  size_t tryRead(void* buffer, size_t minBytes, size_t maxBytes) override {
    //KJ_ASSERT(maxBytes <= data.size() - readPos, "Overran end of stream.");
    size_t amount = std::min(maxBytes, std::max(minBytes, preferredReadSize));
    memcpy(buffer, data.data() + readPos, amount);
    readPos += amount;
    return amount;
  }

  void skip(size_t bytes) override {
    //KJ_ASSERT(bytes <= data.size() - readPos, "Overran end of stream.");
    readPos += bytes;
  }

  kj::ArrayPtr<const capnp::byte> tryGetReadBuffer() override {
    size_t amount = std::min(data.size() - readPos, preferredReadSize);
    return kj::arrayPtr(reinterpret_cast<const capnp::byte*>(data.data() + readPos), amount);
  }

private:
  size_t preferredReadSize;
  std::string data;
  std::string::size_type readPos;
};



class BufferStream: public ::kj::BufferedInputStream {
public: BufferStream(const char * data, size_t size)
      : data_(data),
        size_(size),
        preferredReadSize(std::numeric_limits<size_t>::max()),
        readPos(0) {}
  ~BufferStream() {}

  size_t tryRead(void* buffer, size_t minBytes, size_t maxBytes) override {
    //kj::KJ_ASSERT(maxBytes <= size_ - readPos, "Overran end of stream.");
    size_t amount = std::min(maxBytes, std::max(minBytes, preferredReadSize));
    memcpy(buffer, data_ + readPos, amount);
    readPos += amount;
    return amount;
  }

  void skip(size_t bytes) override {
    //kj::KJ_ASSERT(bytes <= size_ - readPos, "Overran end of stream.");
    readPos += bytes;
  }

  kj::ArrayPtr<const kj::byte> tryGetReadBuffer() override {
    size_t amount = std::min(size_ - readPos, preferredReadSize);
    return kj::arrayPtr(reinterpret_cast<const kj::byte*>(data_ + readPos), amount);
  }

private:
  const char * data_;
  size_t size_;
  size_t preferredReadSize;
  std::string::size_type readPos;
};

class UnBufferedStream: public ::kj::InputStream {
public:
  UnBufferedStream(const char * data, size_t size, bool lazy=false)
      : data_(data),
        size_(size),
        lazy_(lazy),
        readPos_(0) {}
  ~UnBufferedStream() {}

  size_t tryRead(void* buffer, size_t minBytes, size_t maxBytes) override {
    //KJ_ASSERT(maxBytes <= size_t(end - pos), "Overran end of stream.");
    size_t amount = lazy_ ? minBytes : maxBytes;
    memcpy(buffer, data_ + readPos_, amount);
    readPos_ += amount;
    return amount;
  }
private:
  const char * data_;
  size_t size_;
  bool lazy_;
  size_t readPos_;
};

static constexpr uint32_t max_32_int = std::numeric_limits<uint32_t>::max();

//#define CREATE_JS_OBJ
constexpr size_t SCRATCH_SIZE = 128 * 1024;
::capnp::word scratchSpace[6 * SCRATCH_SIZE];

struct ScratchSpace {
    ::capnp::word* words;

    ScratchSpace() {
      words = scratchSpace + SCRATCH_SIZE;
    }
    ~ScratchSpace() noexcept {
    }
};