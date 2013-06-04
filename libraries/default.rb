def get_conf(interface,workingnode=@node)
  if workingnode.has_key?("network_interfaces") and workingnode["network_interfaces"].has_key?("interface")
    return workingnode[:network_interfaces][interface]
  else
    return {}
  end
end

def get_value(key,interfaces, resource=@new_resource, workingnode=@node)
  !resource.send(key).nil? ? resource.send(key) : self.conf(interfaces,workingnode).has_key?(key) ? self.conf(interfaces,workingnode)[key] : nil
end

def debian_before_or_squeeze?
  platform?("debian") && (node['platform_version'].to_f < 6.0 || (node['platform_version'].to_f == 6.0 && node['platform_version'] !~ /.*sid/ ))
end

def ubuntu_before_or_natty?
  platform?("ubuntu") && node['platform_version'].to_f <= 11.04 
end
