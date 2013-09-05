#include <fstream>
#include <vector>
#include <iostream>
#include "src/flat-array.capnp.h"
#include "src/index.capnp.h"
#include <capnp/message.h>
#include <capnp/serialize-packed.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>

typedef std::vector<uint64_t> array;
array::size_type total_entries = 1000000;
unsigned iterations = 10;
bool packed = true;

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Missing arg." << std::endl;
        return 1;
    } else if (strcmp(argv[1], "write") == 0) {
        array list;
        for (array::size_type i=0;i<total_entries;++i) {
           list.push_back(i);
        }
        std::ofstream os ("data.dat", std::ios::out | std::ios::binary);
        array::size_type size1 = list.size();
        os.write((const char*)&size1, sizeof(array::size_type));
        os.write((const char*)&list[0], size1 * sizeof(uint64_t));
        os.close();
    } else if (strcmp(argv[1], "read") == 0) {
        for (unsigned j=0;j<iterations;++j) {
                array list2;
                std::ifstream is("data.dat", std::ios::in| std::ios::binary);
                array::size_type size2;
                is.read((char*)&size2, sizeof(array::size_type));
                list2.reserve(size2);
                is.read((char*)&list2[0], size2 * sizeof(uint64_t));
        }
    } else if (strcmp(argv[1], "cwrite") == 0) {
        kj::AutoCloseFd tmpfile(open("./data.packed", O_CREAT|O_TRUNC|O_WRONLY, S_IRUSR|S_IWUSR));
        uint firstSegmentWords = sizeof(array::size_type)*total_entries;
        ::capnp::AllocationStrategy allocationStrategy = ::capnp::SUGGESTED_ALLOCATION_STRATEGY;
        ::capnp::MallocMessageBuilder message(firstSegmentWords,allocationStrategy);
        auto msg = message.initRoot<flat_array::FlatMessage>();
        auto vals = msg.initVal(total_entries);
        for (array::size_type i=0;i<total_entries;++i) {
           vals.set(i,i);
        }
        kj::ArrayPtr<const kj::ArrayPtr<const ::capnp::word>> segs = message.getSegmentsForOutput();
        std::clog << "num segments: " << segs.size() << "\n";
        writePackedMessageToFd(tmpfile.get(), message);
    } else if (strcmp(argv[1], "cread") == 0) {
        for (unsigned j=0;j<iterations;++j) {
                array list2;
                kj::AutoCloseFd tmpfile(open("./data.packed",O_RDONLY));
                ::capnp::PackedFdMessageReader reader(tmpfile.get());
                auto msg = reader.getRoot<flat_array::FlatMessage>();
                auto vals = msg.getVal();
                unsigned vals_size = vals.size();
                list2.reserve(vals_size);
                std::copy(vals.begin(),vals.end(),back_inserter(list2));
        }
    } else {
        std::clog << "did not find action\n";
    }

}