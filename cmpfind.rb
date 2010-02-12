#!/usr/bin/env ruby

require 'tempfile'

FIND_CMD = ENV["FIND_CMD"] || "find"
DIFF_CMD = ENV["DIFF_CMD"] || "meld"

$data = {:left => [], :right => nil}

ARGV.each do |arg|
  if arg == "--"
    $data[:right] = []
    next
  end
  if $data[:right] == nil
    $data[:left].push arg
  else
    $data[:right].push arg
  end
end

if $data[:right] == nil or $data[:left].empty? or $data[:right].empty?
  STDERR.puts "usage: #{$0} dir [find-opt]... -- dir [find-opt]..."
  exit 1
end

def print_file(name)
  stat = File.lstat(name)
  if stat.file?
    "%20d %s" % [stat.size, name]
  elsif stat.directory?
    "                     %s/" % name
  elsif stat.symlink?
    "                     %s@" % name
  else
    "                     %s%%" % name
  end
end

Tempfile.open("cmpfind-") do |t1|
Tempfile.open("cmpfind-") do |t2|

$tmp = {:left => t1, :right => t2}

[:left, :right].each do |side|
  IO.popen("-", "r") do |p|
    if p == nil
      wd = $data[side].shift
      STDERR.puts "==> entering directory #{wd}"
      Dir.chdir(wd) do
        logargs = $data[side].join(" ")
        if $data[side].empty? or $data[side].first[0,1] == "-"
          logargs = "* " + logargs
          files = Dir.entries(".")
          $data[side] = files[2, files.count-2] + $data[side]
        end
        STDERR.puts "find -s #{logargs}"
        exec FIND_CMD, "-s", *($data[side])
      end
      exit 1
    end
    Dir.chdir($data[side].first) do
      while p.gets
        chomp!
        $tmp[side].puts print_file($_)
      end
    end
  end
  exit 1 unless($?.success?)
end

t1.flush
t2.flush

STDERR.puts "==> comparing results"
STDERR.puts "meld #{t1.path} #{t2.path}"
system DIFF_CMD, t1.path, t2.path

end
end

