def support_d
  not ( debian_before_or_squeeze? or ubuntu_before_or_natty? )
end

def debian_before_or_squeeze?
  platform?("debian") && (node['platform_version'].to_f < 6.0 || (node['platform_version'].to_f == 6.0 && node['platform_version'] !~ /.*sid/ ))
end

def ubuntu_before_or_natty?
  platform?("ubuntu") && node['platform_version'].to_f <= 11.04
end
