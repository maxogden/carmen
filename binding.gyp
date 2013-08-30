{
  'includes': [ 'common.gypi' ],
  'target_defaults': {
      'default_configuration': 'Release',
      'configurations': {
          'Debug': {
              'cflags_cc!': ['-O3', '-DNDEBUG'],
              'xcode_settings': {
                'OTHER_CPLUSPLUSFLAGS!':['-O3', '-DNDEBUG']
              },
              'msvs_settings': {
                 'VCCLCompilerTool': {
                     'ExceptionHandling': 1,
                     'RuntimeTypeInfo':'true',
                     'RuntimeLibrary': '3'
                 }
              }
          },
          'Release': {
          }
      },
      'include_dirs': [
          #'./fss/geocoder/'
      ],
      'cflags_cc!': ['-fno-rtti', '-fno-exceptions'],
      'cflags_cc' : ['-std=c++11'],
      #'libraries': [ '-lboost_system' , '-lboost_locale' ]
  },
  'targets': [
    {
      'target_name': 'mem',
      'sources': [
        "src/node_mem.cpp",
        "src/index.pb.cc",
        "src/index.capnp.cpp"
      ],
      'xcode_settings': {
        'OTHER_CPLUSPLUSFLAGS':['-stdlib=libc++'],
        'GCC_ENABLE_CPP_RTTI': 'YES',
        'GCC_ENABLE_CPP_EXCEPTIONS': 'YES',
        'CLANG_CXX_LANGUAGE_STANDARD':'c++11',
        'MACOSX_DEPLOYMENT_TARGET':'10.7'
      },
      'libraries':[ '-lkj','-lcapnp','-lprotobuf-lite'],
    },
    {
      'target_name': 'action_after_build',
      'type': 'none',
      'dependencies': [ 'mem' ],
      'copies': [
          {
            'files': [ '<(PRODUCT_DIR)/mem.node' ],
            'destination': './lib/'
          }
      ]
    }
  ]
}