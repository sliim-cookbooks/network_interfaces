action :save do
  new_resource.bridge = [ "none" ] if new_resource.bridge and new_resource.bridge.class != Array

  if new_resource.vlan_dev || new_resource.device =~ /(eth|bond|wlan)[0-9]+\.[0-9]+/
    package "vlan"
    modules "8021q"
  end

  new_resource.bond = [ "none" ] if new_resource.bond and new_resource.bond.class != Array

  if new_resource.bond
    package "ifenslave-2.6"
    modules "bonding"
  end

  if new_resource.bootproto == "dhcp"
    type = "dhcp"
  elsif ! new_resource.target
    type = "manual"
  else
    type = "static"
  end

  if get_value(:metric)
    package "ifmetric"
  end

  if new_resource.bridge
    package "bridge-utils"
  end

  execute "restart #{@new_resource.name}" do
    command "ifdown #{get_value(:device)} -i #{interface_file} ; ifup #{get_value(:device)} -i #{interface_file}"
    only_if "ifdown -n #{@new_resource.device} -i #{interface_file} && ifup -n #{@new_resource.device} -i #{interface_file}"
    action :nothing
  end

  template interface_file do
    cookbook "network_interfaces"
    source "interfaces.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :auto => get_value(:onboot),
      :type => type,
      :device => new_resource.device,
      :address => get_value(:target),
      :network => get_value(:network),
      :netmask => get_value(:mask),
      :gateway => get_value(:gateway),
      :broadcast => get_value(:broadcast),
      :bridge_ports => get_value(:bridge),
      :bridge_stp => get_value(:bridge_stp),
      :vlan_dev => get_value(:vlan_dev),
      :bond_slaves => get_value(:bond),
      :bond_mode => get_value(:bond_mode),
      :metric => get_value(:metric),
      :mtu => get_value(:mtu),
      :pre_up => get_value(:pre_up),
      :up => get_value(:up),
      :post_up => get_value(:post_up),
      :pre_down => get_value(:pre_down),
      :post_down => get_value(:post_down),
      :custom => get_value(:custom)
    )
    notifies :run, "execute[restart #{new_resource.name}]", :immediately
    notifies :create, "template[interface merged]", :delayed unless node["network_interface"]["support_d"]
  end
end

action :remove do
  execute "if_down #{new_resource.name}" do
    command "ifdown #{get_value(:device)} -i /etc/network/interfaces.d/#{get_value(:device)}"
    only_if "ifdown -n #{get_value(:device)} -i /etc/network/interfaces.d/#{get_value(:device)}"
  end

  file interface_file do
    action :delete
    notifies :run, "execute[if_down #{new_resource.name}]", :immediately
    notifies :create, "template[interface merged]", :delayed unless node["network_interface"]["support_d"]
  end
end

#def load_current_resource
#  @current_resource = Chef::Resource::NetworkInterface.new(@new_resource.name)
#  @new_resource.each do |key,value|
#    @current_resource.send(key)(get_value(key))
#  end
#  @current_resource.name(@new_resource.name)
#  @current_resource.device(@new_resource.device)
#
#  if false
#    @current_resource.exists = true
#  end
#end

def interface_file
  "/etc/network/interfaces.d/#{get_value(:priority)}-#{get_value(:device)}"
end

def get_conf(key)
  if workingnode.has_key?("network_interfaces") and workingnode["network_interfaces"].has_key?(@new_resource.device) and workingnode[:network_interfaces][@new_resource.device].has_key(key)
    return workingnode[:network_interfaces][@new_resource.device][key]
  else
    return false
  end
end

def get_value(key)
  if @new_resource.send(key)
    return @new_resource.send(key)
  elsif get_conf(key).has_key?(key)
    return get_conf(key)
  else
    return nil
  end
end
