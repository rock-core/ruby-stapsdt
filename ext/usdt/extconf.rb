require "mkmf"

unless system("make", "-C", File.join(__dir__, "..", "libstapsdt"))
    raise "Failed to compile libstapstd"
end

dir_config('libstapsdt',
           [File.join(__dir__, '..', 'libstapsdt', 'src')],
           [File.join(__dir__, '..', 'libstapsdt', 'out')])

unless find_library('elf', 'elf_begin')
    abort "cannot link to libelf"
end

unless find_library('stapsdt', 'probeIsEnabled')
    abort "cannot link to libstapsdt.a"
end

create_makefile("usdt/usdt")
